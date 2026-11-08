export const productLogos:Record<string,{file:string;label:string;wide?:boolean}>={
 pg:{file:'pg',label:'PostgreSQL'},
 core:{file:'core',label:'dbt Core',wide:true},
 mf:{file:'core',label:'MetricFlow · dbt',wide:true},
 paid:{file:'core',label:'dbt Semantic Layer',wide:true},
 pb:{file:'pb',label:'Power BI'},
 py:{file:'py',label:'Streamlit'},
 cli:{file:'cli',label:'Python / CLI'},
 cube:{file:'cube',label:'Cube Core',wide:true},
 om:{file:'om',label:'OpenMetadata'},
 infa:{file:'infa',label:'Informatica'},
 neo:{file:'neo',label:'Neo4j'},
 trino:{file:'trino',label:'Trino'},
 bq:{file:'bq',label:'BigQuery'},
 snow:{file:'snow',label:'Snowflake'},
 dbx:{file:'dbx',label:'Databricks'}
};
export function logoIdsForSlot(slot:string,techId:string|undefined,components:string[]){
 const ids=slot==='execution'?['pg','bq','snow','dbx']:['gov1','gov5','products'].includes(slot)?['infa','om']:[techId==='sql-role'?'pg':techId??''];
 return ids.filter(id=>components.includes(id)&&!!productLogos[id]);
}
