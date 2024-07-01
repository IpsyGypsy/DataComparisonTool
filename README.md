# DataComparisonTool

Implementation:-

1.	Run the script by calling it as follows:
./dataForValidation.sh <environment><list of comma seperated GIDs without space in between><attributes to be fetched for a table in HBase, * for all>
E.g. ./dataForValidation.sh dev "3bcce709-2262-1034-9781-ac162d9d7c07,16f13f9b-4c32-1032-8363-ac162d9d79d3" "*"
2.	Determine whether environment is DEV or QA. Based on that Solr search will be done.
3.	Call function “id” to get the consolidated list of IDs with quotation marks and separated by comma. These IDs will be used while searching in Solr and HBase via Hive.
4.	Curl command is used to generate result from Solr and output is stored in dataForValidation.csv file.
5.	A temporary external Hive table is created that points to the CSV file location.
6.	A hive table is created which makes use of "org.apache.hadoop.hive.hbase.HBaseStorageHandler" and points to HBase table.
7.	Function “attribute” is called so as to get the list of attributes to be queried in the aforementioned Hive table. The attribute-list is passed as 3rd parameter while scheduling the job. For all attributes, pass “*” as parameter.
8.	Since this Hive table points to HBase, querying it takes a considerable amount of time. Hence another Hive table is created with ORC as file format and compression mode “Snappy”.
9.	Data is inserted into this table from initial Hive table which houses data from HBase table. While doing so, the data is filtered for optimization.
10.	Using md5 method both Hive tables are compared and result is printed
