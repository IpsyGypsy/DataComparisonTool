# DataComparisonTool

Implementation:-

1.	Run the script by calling it as follows:
./dataForValidation.sh <environment> <list of comma seperated IDs without space in between> <attributes to be fetched for a table in HBase, * for all>
E.g. ./dataForValidation.sh dev "ID1,ID2,.." "*"
3.	Determine whether environment is DEV or QA. Based on that Solr search will be done.
4.	Call function “id” to get the consolidated list of IDs with quotation marks and separated by comma. These IDs will be used while searching in Solr and HBase via Hive.
5.	Curl command is used to generate result from Solr and output is stored in dataForValidation.csv file.
6.	A temporary external Hive table is created that points to the CSV file location.
7.	A hive table is created which makes use of "org.apache.hadoop.hive.hbase.HBaseStorageHandler" and points to HBase table.
8.	Function “attribute” is called so as to get the list of attributes to be queried in the aforementioned Hive table. The attribute-list is passed as 3rd parameter while scheduling the job. For all attributes, pass “*” as parameter.
9.	Since this Hive table points to HBase, querying it takes a considerable amount of time. Hence another Hive table is created with ORC as file format and compression mode “Snappy”.
10.	Data is inserted into this table from initial Hive table which houses data from HBase table. While doing so, the data is filtered for optimization.
11.	Call function "compare" to compare both Hive tables using md5 method and result is printed
