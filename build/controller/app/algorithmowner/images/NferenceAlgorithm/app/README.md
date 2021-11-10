# Query Algorithm
An algorithm that connects to the specified database with `-d` and queries all records in the table `-t`.
Writes all queried JSON objects to an output file in directory given via flag `-o`.

# CLI

|argument | description
|---------|:-----------|
-o, --output_path | Output folder to store JSON objects. (default "encrypted_output")
-f, --filename | Output filename inside --output_path directory. (default "out.txt")
-e, --endpoint | MariaDB of the database, with pattern: $hostname:$PORT.(default "0.0.0.0:3306")
-d, --database | Database to connect to (default "test_db")
-t, --table | Table where JSON files are stored  (default "test_table")
-u, --user | MariaDB username (default "root")
-c, --column| Column name that stores JSON object in database

# Certificate setup
Set correct certificate specifying corresponding environmental variables:
```
DB_CACERT = os.getenv("DB_CACERT")
DB_CLIENT_KEY = os.getenv("DB_CLIENT_KEY")
DB_CLIENT_CERT = os.getenv("DB_CLIENT_CERT")
```
