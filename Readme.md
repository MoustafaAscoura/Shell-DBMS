# Hello to the World's Best DBMS!

BashDBMS is a simple, yet the best, DBMS developed using bash shell script in linux. This is an educational project to showcase skills acquired in shell script course in ITI Training Program (Summer 2023), Mansoura, Egypt.

## Installation

First, make sure you have the appropriate execute permission.

```bash
chmod +x dbms.sh
```
Then, simply execute the file.

```bash
pip install foobar
```

## Structure
This database is made up of directories and text files (tip: don't store your passwords here!)
Each database is a directory and each table within is a text file.
Each line of a file is a row. Columns are separated by a colon (:).
The first line of each file is column names, the second line is the data types corresponding to these columns.

## Usage

The first version of the code is pretty simple and has guiding prompts everywhere. The second version is similar to any (Less interesting, previously your best) DBMS! 
This program is not case nor (space) sensitive, change case and add spaces wherever you want.

### In the main menu

```Bash

# Create a database
CREATE DATABASE {database name}

# See current databases
LIST DATABASE

# Drop Database
DROP DATABASE {database name}

# Connect to a database (This will take you to another menu 
# where the previous commands won't work anymore"
CONNECT DATABASE {database name}

#Exit the program
QUIT
```
### After Connecting to a database

```Bash

# Create a Table
CREATE TABLE {Table Name} VALUES (col1=type1,col2=type2,...,coln=typen)';
#types are (int) or (str) only!

#List current tables
LIST TABLES

#Drop Table
DROP {Table Name}

#Select From Table
SELECT all or col1,..,coln FROM {TABLE} WHERE (optional) colx=val

#Insert into Table
INSERT INTO {TABLE} VALUES (col1,col2,...coln)

#Delete From Table
DELETE FROM {TABLE} WHERE (optional) colx=val

#Update Table
UPDATE {TABLE} SET colx=val\n WHERE (optional) colx=val

#Disconnect (This will take you back to the main menu)
DISCONNECT

```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

Free! But do not copy for your own sake. Make one instead and use this as guide only. <3
