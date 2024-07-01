# DataComparisonTool

Implementation:-

1.	Run the script by calling it as follows:
./dataForValidation.sh <environment><list of comma seperated GIDs without space in between><attributes to be fetched for Party table in HBase, * for all><attributes to be fetched for Account table in HBase, * for all>
E.g. ./dataForValidation.sh dev "3bcce709-2262-1034-9781-ac162d9d7c07,16f13f9b-4c32-1032-8363-ac162d9d79d3" "*" "prd_cd,ad1"
2.	Determine whether environment is DEV or QA. Based on that Solr search will be done.
3.	Call function “id” to get the consolidated list of IDs with quotation marks and separated by comma. These IDs will be used while searching in Solr and HBase via Hive.
4.	Curl command is used to generate result from Solr and output is stored in dataForValidation.csv file.
5.	A hive table is created which makes use of "org.apache.hadoop.hive.hbase.HBaseStorageHandler" and points to HBase’s Party table.
6.	Function “attribute” is called so as to get the list of attributes to be queried in the aforementioned Hive table. The attribute-list is passed as 3rd and 4th parameter while scheduling the job for Party and Account tables respectively. For all attributes, pass “*” as parameter.
7.	Since this Hive table points to HBase, querying it takes a considerable amount of time. Hence another Hive table is created with ORC as file format and compression mode “Snappy”.
8.	Data is inserted into this table from initial Hive table which houses data from HBase table. While doing so, the data is filtered for optimization.
9.	Now the staging Hive table is queried, ordered by GID.
10.	The output is stored in dataForValidation.csv file. 
11.	The process is repeated for Account table.
