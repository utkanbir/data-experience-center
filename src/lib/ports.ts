export function referencePortFor(databasePort:number){return databasePort<=64535?databasePort+1000:databasePort-1000;}
export function docsPortFor(databasePort:number){return databasePort<=62886?databasePort+2649:databasePort-2649;}
