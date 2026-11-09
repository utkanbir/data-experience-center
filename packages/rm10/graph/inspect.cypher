MATCH (c:Concept:LabMeta {dataset:'beverage-revenue-v1'}) RETURN c;

MATCH (c:Customer:LabEntity {dataset:'beverage-revenue-v1'})-[:OWNS_OUTLET]->(o:Outlet {channel:'HoReCa'})-[:SERVED_BY]->(d:Distributor) RETURN c,o,d;

MATCH (s:Sale:LabEntity {dataset:'beverage-revenue-v1'})-[:AT_OUTLET]->(o:Outlet {channel:'HoReCa'}) MATCH(s)-[:OF_PRODUCT]->(p:Product) MATCH(s)-[:WITH_PROMOTION]->(promotion:Promotion) RETURN o,s,p,promotion LIMIT 50;

MATCH(s:Sale:LabEntity {dataset:'beverage-revenue-v1'}) RETURN s.id,s.sourceTable,s.sourceKey,s.sourceReference LIMIT 10;

MATCH(m:Metric:LabEntity {dataset:'beverage-revenue-v1'}) RETURN m.metricId,m.sql,m.sourceTable;
