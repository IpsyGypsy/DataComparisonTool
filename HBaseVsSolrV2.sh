#!/bin/bash

ls dataForValidation # List the contents of the dataForValidation directory
cmdStatus=$? # Store the exit status of the previous command
if [ $cmdStatus -eq 0 ]; then # Check if the exit status is 0 (success)
    rm -r dataForValidation # Remove the dataForValidation directory and its contents
fi
mkdir dataForValidation # Create the dataForValidation directory
cd dataForValidation # Change to the dataForValidation directory

IDField="" # Initialize the IDField variable
id="" # Initialize the id variable
idCounter=0 # Initialize the idCounter variable
idDivide=1 # Initialize the idDivide variable
url="" # Initialize the url variable
array=( "$@" ) # Store the command line arguments in an array
echo "Environment: ${array[0]}" # Print the value of the first element in the array
echo "Attributes to be checked: ${array[2]} ${array[3]}" # Print the values of the third and fourth elements in the array
attributeList="*" # Initialize the attributeList variable

solrValidation() {
    # idDivide=0 # Reset the idDivide variable
    echo "Executing solrValidation function"

    # IFS=',' # Set the comma as the delimiter
    # read -ra IDArray <<< "$4" # Read the fourth argument into an array, using the comma as the delimiter
    # for i in "${IDArray[@]}"; do # Iterate over each element in the array
    #     restCall=$1$2"/select?df="$3"&fq="$i"&indent=on&q=*:*&rows="$5"&sort="$3"%20asc&wt=csv" # Form the query for Solr search
    #     if [ $idDivide = 0 ]; then # Check if idDivide is 0
    #         idDivide=$(expr $idDivide + 1) # Increment idDivide by 1
    #         curl $restCall  | sed 's/\\,/;/g' | tee -a solr.csv >> dataForValidation.csv # Replace '\,' characters with ';' and write to csv
    #     else
    #         curl $restCall  | sed 's/\\,/;/g' | sed '1d' | tee -a solr.csv >> dataForValidation.csv # Replace '\,' characters with ';' and write to csv
    #     fi
    # done
    # unset IFS
    # IFS='`'

    
    # Drop the table if it exists and create an external table in Hive with HBase storage handler
    hive -S -e 'drop table if exists tableASolr;CREATE EXTERNAL TABLE IF NOT EXISTS tableASolr(key string,fnm string,lnm string,dob string,funm string,ssn string,grp string,pol string,gid string,ad1 string,ad2 string,ad3 string,adloc string,adty string,ccd string,cty string,dod string,eid string,emp string,epi string,gcd string,mnm string,pcd string,perid string,pid string,ppi string,st string,sty string,suff string,ph string) STORED BY "com.lucidworks.hadoop.hive.LWStorageHandler" LOCATION "/tmp/solr" TBLPROPERTIES("solr.server.url" = "'$1'", "solr.collection" = "tableA","solr.query" = "*:*");'

    hive -S -e 'drop table if exists s;CREATE TABLE IF NOT EXISTS s(key string,fnm string,lnm string,dob string,funm string,ssn string,grp string,pol string,gid string,ad1 string,ad2 string,ad3 string,adloc string,adty string,ccd string,cty string,dod string,eid string,emp string,epi string,gcd string,mnm string,pcd string,perid string,pid string,ppi string,st string,sty string,suff string,ph string) ROW FORMAT DELIMITED FIELDS TERMINATED BY "," STORED AS ORC TBLPROPERTIES("compress.mode"="SNAPPY");insert into table s select * from tableASolr where gid in ('$id');'
}

id() {
    echo "Inside ID function"

    hive -S -e 'drop table if exists sqoopTable;CREATE EXTERNAL TABLE IF NOT EXISTS sqoopTable(a1 string,a2 string,a3 string,a4 string,a5 string,a6 string,a7 string,a8 string,a9 string,a10 string,a11 string,a12 string,a13 string,a14 string,a15 string,a16 string,a17 string,a18 string,a19 string,a20 string,a21 string,a22 string,a23 string,a24 string,a25 string,a26 string,a27 string,a28 string,a29 string,a30 string,a31 string,a32 string,a33 string,a34 string,a35 string,a36 string,a37 string,a38 string,a39 string,a40 string,a41 string,a42 string,a43 string) STORED AS TEXTFILE LOCATION "/Data/csc_insights/dental/sqoop_extract/sqoop_tableA";'

    grep -q '-' <<< $1 && str=$1 || str=($(hive -S -e 'select distinct a43 from sqoopTable;'|sed ':a;N;$!ba;s/\n/,/g')) #check whether SEARCH_IDs are passed. Otherwise take SEARCH_IDs from sqoop_tableA path

    str=($(hive -S -e 'select distinct a43 from sqoopTable;'|sed ':a;N;$!ba;s/\n/,/g'))  #get a list of comma separated IDs from sqoop_tableA path

    IFS=',' # Set the comma as the delimiter
    read -ra ADDR <<< "$str" # Read the value of str into an array, using the comma as the delimiter
    for i in "${ADDR[@]}"; do # Iterate over each element in the array
        IDField="%22"$i"%22%20"$IDField # Append the current element to the IDField variable
        id=$id'"'$i'",' # Append the current element to the id variable
        idCounter=$(expr $idCounter + 1) # Increment the idCounter variable
        if [ $idCounter = 100 ]; then # Check if idCounter is equal to 100
            idDivide=$(expr $idDivide + 1) # Increment idDivide by 1
            IDField=","$IDField
        fi
    done
    id=${id: : -1} # Remove the last character from the id variable
    idCounterRows=$(expr $idCounter \* 30) # Calculate the value of idCounterRows
    unset IFS
    IFS='`'
}

attribute() {
    echo "in attribute"
    attributeList="*" # Reset the attributeList variable
    if [ "$1" != "" ]; then # Check if the first argument is not empty
        if [ "$1" != "*" ]; then # Check if the first argument is not equal to "*"
            grep -q 'gid' <<< $1 && attributeList=" $1 " || attributeList=" gid,$1 " # Check if the first argument contains "gid". If yes, set attributeList to the first argument. Otherwise, set attributeList to "gid" followed by the first argument.
        fi
    fi
}

compare() {
    hbase_val=$(hive -S -e 'select md5(concat(*)) as md5 from p') 
    solr_val=$(hive -S -e 'select md5(concat(*)) as md5 from sqoopTable')

    if [ "$hbase_val" = "$solr_val" ]; then
        echo "NO DIFFERENCE"
    else
        echo "DIFFERENCE FOUND! KINDLY CHECK!"
    fi
}

if [ "${array[0]}" = "dev" ]; then # Check if the value of the first element in the array is "dev"
    url="http://<solr-url for DEV environment>.com:<port number>/solr/" # Set the value of the url variable
    coreTableA="<name of table A for DEV environment>" # Set the value of the coreTableA variable
elif [ "${array[0]}" = "qa" ]; then # Check if the value of the first element in the array is "qa"
    url="http://<solr-url for QA environment>.com:<port number>/solr/" # Set the value of the url variable
    coreTableA="<name of table A for QA environment>" # Set the value of the coreTableA variable
fi

id "${array[1]}" # Call the id function with the second element in the array as an argument
#id
echo "" >> dataForValidation.csv
echo "TableA SOLR result" >> dataForValidation.csv
solrValidation "$url" "$coreTableA" "id" "$IDField" "$idCounterRows" # Call the solrValidation function with the appropriate arguments

# Drop the table if it exists and create an external table in Hive with HBase storage handler
hive -S -e 'drop table if exists tableAHbase;CREATE EXTERNAL TABLE IF NOT EXISTS tableAHbase(key string,fnm string,lnm string,dob string,funm string,ssn string,grp string,pol string,gid string,ad1 string,ad2 string,ad3 string,adloc string,adty string,ccd string,cty string,dod string,eid string,emp string,epi string,gcd string,mnm string,pcd string,perid string,pid string,ppi string,st string,sty string,suff string,ph string) STORED BY "org.apache.hadoop.hive.hbase.HBaseStorageHandler" WITH SERDEPROPERTIES ("hbase.columns.mapping" = ":key,p:fnm,p:lnm,p:dob,p:funm,p:ssn,p:grp,p:pol,p:gid,p:ad1,p:ad2,p:ad3,p:adloc,p:adty,p:ccd,p:cty,p:dod,p:eid,p:emp,p:epi,p:gcd,p:mnm,p:pcd,p:perid,p:pid,p:ppi,p:st,p:sty,p:suff,p:ph") TBLPROPERTIES("hbase.table.name" = "tableA", "hbase.mapred.output.outputtable" = "tableA");'

# Get the tableA attributes from the array
tableAAttributes="${array[2]}"
# Call the attribute function with the tableAAttributes
attribute "$tableAAttributes"
# Print the attributeList for tableA
echo "attributeList for tableA $attributeList"

# Drop the table if it exists and create a table in Hive with ORC storage format
hive -S -e 'drop table if exists p;CREATE TABLE IF NOT EXISTS p(key string,fnm string,lnm string,dob string,funm string,ssn string,grp string,pol string,gid string,ad1 string,ad2 string,ad3 string,adloc string,adty string,ccd string,cty string,dod string,eid string,emp string,epi string,gcd string,mnm string,pcd string,perid string,pid string,ppi string,st string,sty string,suff string,ph string) ROW FORMAT DELIMITED FIELDS TERMINATED BY "," STORED AS ORC TBLPROPERTIES("compress.mode"="SNAPPY");insert into table p select * from tableAHbase where gid in ('$id');'

# Set the query to select the attributeList from table p and order by gid
query="set hive.cli.print.header=true;select ${attributeList} from p order by gid;"
echo "$query"

echo "TableA HBase result" >> dataForValidation.csv
# Execute the query, replace ',' characters with ';' and tabs with ',' using sed, remove NULL values, and append the result to hbase.csv and dataForValidation.csv
hive -S -e "$query" | sed 's/,/;/g' | sed 's/[\t]/,/g' | sed 's/NULL//g' | tee -a hbase.csv >> dataForValidation.csv

# Call the compare function with "TableA" as the argument
compare "TableA"
# Remove the dataForValidation.csv file
rm dataForValidation.csv
	
# Go back to the parent directory
cd ..
# Print the end message
echo "*******END*******"
