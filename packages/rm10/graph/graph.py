import hashlib,json,os,re,sys,time
from pathlib import Path
from datetime import datetime,timezone
from decimal import Decimal
import psycopg
from psycopg.rows import dict_row
from neo4j import GraphDatabase

DATASET='beverage-revenue-v1'
CLASSES={'Customer','Outlet','Distributor','Product','Promotion','Sale','Metric'}
RELATIONS={'OWNS_OUTLET':('Customer','Outlet'),'SERVED_BY':('Outlet','Distributor'),'AT_OUTLET':('Sale','Outlet'),'OF_PRODUCT':('Sale','Product'),'WITH_PROMOTION':('Sale','Promotion')}
KEYS=['ontology_definition','graph_entities','graph_relationships','graph_provenance','graph_freshness','graph_paths','graph_metric_context','graph_model_binding']

def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=False,default=str).encode()).hexdigest()
def identity(kind,key):return 'rm10:'+kind.lower()+':'+str(key)
def ontology_valid(model):
    classes=model.get('classes',[]);relations=model.get('relations',[])
    sources={'Customer':('raw.dim_customer','customer_key'),'Outlet':('raw.dim_outlet','outlet_key'),'Distributor':('raw.dim_outlet','distributor_key'),'Product':('raw.dim_product','product_key'),'Promotion':('raw.dim_promotion','promotion_key'),'Sale':('dwh.v_sales_detail','sales_line_key'),'Metric':('cube/schema/Sales.js','Sales.netRevenue')}
    return model.get('id')=='beverage-ontology-v1' and model.get('version')=='1.0' and len(classes)==7 and {c['name']:(c.get('source'),c.get('key')) for c in classes}==sources and len(relations)==5 and {r['name']:(r['domain'],r['range']) for r in relations}==RELATIONS and model.get('metric',{}).get('id')=='Sales.netRevenue'

def snapshot():
    nodes=[];edges=[]
    def node(kind,key,source,name,**props):
        value={'id':identity(kind,key),'kind':kind,'dataset':DATASET,'sourceTable':source,'sourceKey':str(key),'name':name,**props};nodes.append(value);return value['id']
    def edge(a,kind,b):edges.append({'from':a,'type':kind,'to':b})
    with psycopg.connect(host='postgres',dbname='komtas_rm10',user='rm10_bi',password=os.environ['PGPASSWORD'],row_factory=dict_row,connect_timeout=15) as c:
        customers=c.execute('SELECT * FROM raw.dim_customer ORDER BY customer_key').fetchall()
        outlets=c.execute('SELECT * FROM raw.dim_outlet ORDER BY outlet_key').fetchall()
        products=c.execute('SELECT * FROM raw.dim_product ORDER BY product_key').fetchall()
        promotions=c.execute('SELECT * FROM raw.dim_promotion ORDER BY promotion_key').fetchall()
        sales=c.execute('SELECT sales_line_key,outlet_key,product_key,promotion_key,source_reference,month_start,channel,gross_revenue_eur-discount_amount_eur-return_amount_eur AS net_revenue,net_volume_liters FROM dwh.v_sales_detail ORDER BY sales_line_key').fetchall()
    for row in customers:node('Customer',row['customer_key'],'raw.dim_customer',row['customer_name'])
    distributors={row['distributor_key']:row['distributor_name'] for row in outlets}
    for key,name in sorted(distributors.items()):node('Distributor',key,'raw.dim_outlet',name)
    for row in outlets:
        oid=node('Outlet',row['outlet_key'],'raw.dim_outlet',row['outlet_name'],country=row['country'],channel=row['channel'])
        edge(identity('Customer',row['customer_key']),'OWNS_OUTLET',oid);edge(oid,'SERVED_BY',identity('Distributor',row['distributor_key']))
    for row in products:node('Product',row['product_key'],'raw.dim_product',row['product_name'],category=row['category'])
    for row in promotions:node('Promotion',row['promotion_key'],'raw.dim_promotion',row['promotion_name'])
    for row in sales:
        sid=node('Sale',row['sales_line_key'],'dwh.v_sales_detail',row['source_reference'],sourceReference=row['source_reference'],month=str(row['month_start']),channel=row['channel'],netRevenue=float(row['net_revenue']),netLiters=float(row['net_volume_liters']))
        for rel,kind,key in [('AT_OUTLET','Outlet',row['outlet_key']),('OF_PRODUCT','Product',row['product_key']),('WITH_PROMOTION','Promotion',row['promotion_key'])]:edge(sid,rel,identity(kind,key))
    formula='gross_revenue_eur - discount_amount_eur - return_amount_eur'
    node('Metric','Sales.netRevenue','cube/schema/Sales.js','NetRevenue',metricId='Sales.netRevenue',sql=formula)
    return sorted(nodes,key=lambda n:n['id']),sorted(edges,key=lambda e:(e['from'],e['type'],e['to']))

def main():
    mode=sys.argv[1] if len(sys.argv)>1 else 'verify';out=Path('/artifacts');out.mkdir(exist_ok=True)
    states=dict.fromkeys(KEYS,'not_tested');evidence={'mode':mode,'generatedAt':datetime.now(timezone.utc).isoformat(),'checks':[]};results={}
    model=json.loads(Path('/graph/ontology.json').read_text());model_hash=digest(model)
    driver=GraphDatabase.driver('bolt://neo4j:7687',auth=('neo4j',os.environ['NEO4J_PASSWORD']),connection_timeout=15)
    def query(cypher,**params):
        with driver.session(database='neo4j') as session:return [r.data() for r in session.run(cypher,params)]
    def check(key,ok):states[key]='passed' if ok else 'failed'
    try:
        if not ontology_valid(model):states['ontology_definition']='failed';raise ValueError('Invalid explicit ontology definition')
        for attempt in range(45):
            try:driver.verify_connectivity();break
            except Exception:
                if attempt==44:raise
                time.sleep(2)
        if mode=='fault':
            count=query("MATCH (o:Outlet:LabEntity {id:$id,dataset:$dataset})-[r:SERVED_BY]->() DELETE r RETURN count(r) AS removed",id=identity('Outlet',1),dataset=DATASET)[0]['removed']
            print(json.dumps({'removedServedByEdges':count}));return 0
        nodes,edges=snapshot();source_hash=digest({'nodes':nodes,'edges':edges})
        if mode=='sync':
            query('CREATE CONSTRAINT rm10_entity_id IF NOT EXISTS FOR (n:LabEntity) REQUIRE n.id IS UNIQUE')
            query('CREATE CONSTRAINT rm10_meta_id IF NOT EXISTS FOR (n:LabMeta) REQUIRE n.id IS UNIQUE')
            with driver.session(database='neo4j') as session:
                def load(tx):
                    tx.run('MATCH(n) WHERE (n:LabEntity OR n:LabMeta) AND n.dataset=$dataset DETACH DELETE n',dataset=DATASET).consume()
                    tx.run('CREATE(m:LabMeta:OntologyModel {id:$id,dataset:$dataset,version:$version,modelHash:$modelHash,sourceHash:$sourceHash,loadedAt:$at})',id='rm10:ontology',dataset=DATASET,version=model['version'],modelHash=model_hash,sourceHash=source_hash,at=datetime.now(timezone.utc).isoformat()).consume()
                    for concept in model['classes']:tx.run('CREATE(c:LabMeta:Concept {id:$id,dataset:$dataset,name:$name,source:$source,key:$key})',id='rm10:concept:'+concept['name'],dataset=DATASET,**concept).consume()
                    for relation in model['relations']:tx.run('CREATE(r:LabMeta:RelationType {id:$id,dataset:$dataset,name:$name,domain:$domain,range:$range})',id='rm10:relation:'+relation['name'],dataset=DATASET,**relation).consume()
                    for kind in sorted(CLASSES):
                        tx.run('UNWIND $rows AS row CREATE(n:LabEntity:'+kind+') SET n=row WITH n MATCH(c:Concept:LabMeta {name:$kind,dataset:$dataset}) CREATE(n)-[:INSTANCE_OF]->(c)',rows=[n for n in nodes if n['kind']==kind],kind=kind,dataset=DATASET).consume()
                    for relation in RELATIONS:
                        tx.run('UNWIND $rows AS row MATCH(a:LabEntity {id:row.from,dataset:$dataset}),(b:LabEntity {id:row.to,dataset:$dataset}) CREATE(a)-[:'+relation+']->(b)',rows=[e for e in edges if e['type']==relation],dataset=DATASET).consume()
                session.execute_write(load)
        check('ontology_definition',query('MATCH(m:OntologyModel:LabMeta {dataset:$dataset}) RETURN m.modelHash AS hash',dataset=DATASET)==[{'hash':model_hash}] and {r['name'] for r in query('MATCH(c:Concept:LabMeta {dataset:$dataset}) RETURN c.name AS name',dataset=DATASET)}==CLASSES and {r['name']:(r['domain'],r['range']) for r in query('MATCH(r:RelationType:LabMeta {dataset:$dataset}) RETURN r.name AS name,r.domain AS domain,r.range AS range',dataset=DATASET)}==RELATIONS)
        actual_nodes=[r['node'] for r in query('MATCH(n:LabEntity {dataset:$dataset}) RETURN properties(n) AS node ORDER BY n.id',dataset=DATASET)]
        actual_edges=sorted(query('MATCH(a:LabEntity {dataset:$dataset})-[r]->(b:LabEntity {dataset:$dataset}) RETURN a.id AS from,type(r) AS type,b.id AS to',dataset=DATASET),key=lambda e:(e['from'],e['type'],e['to']))
        check('graph_entities',[(n['id'],n['kind']) for n in actual_nodes]==[(n['id'],n['kind']) for n in nodes] and query('MATCH(n:LabEntity {dataset:$dataset})-[:INSTANCE_OF]->(c:Concept) WHERE n.kind=c.name RETURN count(n) AS count',dataset=DATASET)==[{'count':len(nodes)}])
        check('graph_relationships',actual_edges==edges)
        expected_provenance={n['id']:(n['sourceTable'],n['sourceKey'],n.get('sourceReference')) for n in nodes}
        check('graph_provenance',{n['id']:(n.get('sourceTable'),n.get('sourceKey'),n.get('sourceReference')) for n in actual_nodes}==expected_provenance)
        stored=query('MATCH(m:OntologyModel:LabMeta {dataset:$dataset}) RETURN m.sourceHash AS hash',dataset=DATASET)
        check('graph_freshness',stored==[{'hash':source_hash}] and digest({'nodes':actual_nodes,'edges':actual_edges})==source_hash)
        paths=query("MATCH(c:Customer:LabEntity {dataset:$dataset})-[:OWNS_OUTLET]->(o:Outlet {channel:'HoReCa'})-[:SERVED_BY]->(d:Distributor) RETURN c.id AS customer,c.name AS customerName,o.id AS outlet,o.name AS outletName,d.id AS distributor,d.name AS distributorName ORDER BY outlet",dataset=DATASET)
        check('graph_paths',{r['outlet'] for r in paths}=={n['id'] for n in nodes if n['kind']=='Outlet' and n['channel']=='HoReCa'} and len(paths)==4)
        context=query('MATCH(s:Sale:LabEntity {dataset:$dataset})-[:AT_OUTLET]->(o:Outlet)-[:SERVED_BY]->(d:Distributor) MATCH(s)-[:OF_PRODUCT]->(p:Product) MATCH(c:Customer)-[:OWNS_OUTLET]->(o) WHERE o.channel="HoReCa" RETURN s.month AS month,c.id AS customer,c.name AS customerName,o.id AS outlet,o.name AS outletName,d.id AS distributor,d.name AS distributorName,p.id AS product,p.name AS productName,sum(s.netRevenue) AS netRevenue,sum(s.netLiters) AS netLiters ORDER BY month,outlet,product',dataset=DATASET)
        totals=query('MATCH(s:Sale:LabEntity {dataset:$dataset})-[:AT_OUTLET]->(o:Outlet) RETURN s.month AS month,o.channel AS channel,sum(s.netRevenue) AS revenue,sum(s.netLiters) AS liters ORDER BY month,channel',dataset=DATASET)
        sys.path.insert(0,'/consumer');from client import run_query
        cube=run_query();pairs={(r['month'],r['channel']):r for r in totals}
        context_totals={}
        for row in context:
            value=context_totals.setdefault(row['month'],[Decimal(0),Decimal(0)]);value[0]+=Decimal(str(row['netRevenue']));value[1]+=Decimal(str(row['netLiters']))
        context_matches=all(r['Sales.month'] in context_totals and abs(context_totals[r['Sales.month']][0]-Decimal(str(r['Sales.netRevenue'])))<Decimal('0.0001') and abs(context_totals[r['Sales.month']][1]-Decimal(str(r['Sales.netLiters'])))<Decimal('0.0001') for r in cube if r['Sales.channel']=='HoReCa')
        check('graph_metric_context',context_matches and len(context_totals)==2 and len(pairs)==6 and len(cube)==6 and all((r['Sales.month'],r['Sales.channel']) in pairs and abs(Decimal(str(pairs[r['Sales.month'],r['Sales.channel']]['revenue']))-Decimal(str(r['Sales.netRevenue'])))<Decimal('0.0001') and abs(Decimal(str(pairs[r['Sales.month'],r['Sales.channel']]['liters']))-Decimal(str(r['Sales.netLiters'])))<Decimal('0.0001') for r in cube))
        cube_model=Path('/cube-model/Sales.js').read_text();expression=re.search(r'netRevenue:\s*\{sql:\s*`([^`]+)`',cube_model)
        metric=[n for n in actual_nodes if n['kind']=='Metric'];check('graph_model_binding',len(metric)==1 and metric[0].get('metricId')=='Sales.netRevenue' and expression is not None and metric[0].get('sql')==expression[1])
        evidence.update(entityCount=len(actual_nodes),businessRelationshipCount=len(actual_edges),classCounts={kind:sum(n['kind']==kind for n in actual_nodes) for kind in sorted(CLASSES)},sourceHash=source_hash,storedSourceHash=stored,modelHash=model_hash)
        results={'question':'HoReCa düşüşünden etkilenen outlet, müşteri, distribütör ve ürün bağlantıları nelerdir?','customerOutletDistributorPaths':paths,'contextByMonthOutletProduct':context,'graphTotals':totals,'cubeMetricResults':cube,'limit':'Birlikte görünme nedensellik kanıtı değildir. Kanonik metrik Cube’dan gelir; graph satır bileşenlerini bağlam uzlaştırması için toplar.'}
    except Exception as error:
        evidence['error']=str(error);states['graph_relationships']='failed';print(type(error).__name__+': '+str(error),file=sys.stderr)
    finally:
        driver.close()
        if mode!='fault':
            evidence['checks']=[{'id':key,'status':states[key]} for key in KEYS]
            (out/'graph-checks.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2));(out/'graph-status.txt').write_text('\n'.join(states.values())+'\n');(out/'graph-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
    print(json.dumps(states));return 0 if mode=='verify' or all(v=='passed' for v in states.values()) else 1

if __name__=='__main__':raise SystemExit(main())
