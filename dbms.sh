#!/usr/bin/bash
currentdb="";

#Functions go here!
function checktable {
        #Checks for table existence
        if [[ -f $1 ]]
        then
                return 1
        else    
                return 0
        fi  
};

function createtable {
	tablename=$1;
	checktable $tablename;
	if [[ $? -eq 1 ]]
	then
		echo "Table already exists!"
	else
		#Reads and Check Column Names and Types1
		read -p "Insert names of rows comma-separated: " cols;
		cols=$(echo $cols | sed 's/ *, */:/g'); echo $cols > $tablename;
		read -p "Insert type of each row comma-separated (str/int): " types;
		types=$(echo $types | sed 's/ *, */:/g'); echo $types >> $tablename;

		#Check for equal number of fields
		nfields=$(echo $cols | awk -F: '{printf NF}'); nfields2=$(echo $types | awk -F: '{printf NF}');
		if [[ nfields -ne nfields2 ]]; then
			echo "Unmatched Number of Fields";
			rm -f $tablename;
			return 0; fi;

		local IFS=":";
		fields=($cols);
		for field in "${fields[@]}"
		do
			if [[ $field =  *" "* ]] || [[ -z $field ]] 
			then
				echo "Table names cannot be empty or contain white spaces!"
				rm -f $tablename;
				return 0;
			fi
		done

		local IFS=":";
		fields=($types);
		types=('int' 'str');
		for field in "${fields[@]}"
		do
			if [[ $field = "str" ]] || [[ $field = "int" ]] 
			then
				continue;
			else
				echo "Invalid Type Found! $field"
				rm -f $tablename;
				return 0;
			fi
		done

	fi
};

function getColIndex {
	local tname=$1;
	local colname=$2;
	local IFS=":";
	fields=($(head -1 $tname));
	len=${#fields[@]}
	res=-1;
	for (( i=0; i<$len; i++ ));
	do 
		if [[ " $key " = " ${fields[$i]} " ]]; 
		then
				res=$i;
				break;
		fi; 
	done;

	return $res;
};

function selectTable {
	local tname=$1;
	echo "This table headers are as follows:"; echo `head -1 $tname`;
	printf '\nEnter the select query as follows:\nSELECT all or col1,..,coln WHERE colx=val "No Spaces!"\n';
	read query; local IFS=" "; 	fields=($query);
	condition=${fields[3]}; cols=${fields[1]};
	key=$(echo $condition | cut -d= -f1)
	searchval=$(echo $condition | cut -d= -f2)

	local IFS=":";
	headers=($(head -1 $tname));


	getColIndex $tname $key;
	colindex=$?;

	if [[ $colindex -eq '255' ]]
	then
		echo "Cannot find Column: $key!"
		return 0;
	fi


	local IFS=","; cols=($cols);
	if [[ $cols = "all" ]]
	then
		reqcols='all';
	else
		#Check if requested columns are real columns
		len=${#cols[@]}
		for (( i=0; i<$len; i++ ));
		do 	
			if [[ " ${headers[@]} " =~ " ${cols[$i]} " ]]; 
			then
				local reqcols+=("$i");
			fi 
		done
		
		#get index of requested columns
		len=${#headers[@]}
		for (( i=0; i<$len; i++ ));
		do 	
			if [[ " ${cols[@]} " =~ " ${headers[$i]} " ]]; 
			then
				local reqcols+=("$i");
			fi 
		done
	fi;



	colindex=$(($colindex+1));
	type=$(sed -n "2p" "$tname" | cut -d: -f $colindex);
	
	filelength=$(cat $tname | wc -l);
	line_number=3
	echo ${cols[@]};
	echo "==========";

	while [ "$line_number" -le $filelength ]; do
		line="$(sed -n "$line_number p" "$tname")"
		if [ $(echo $line | cut -d: -f $colindex) = $searchval -a $type = 'str' ] || [ $(echo $line | cut -d: -f $colindex) -eq $searchval -a $type = 'int' ] 2> /dev/null
		then
			if [[ $reqcols = "all" ]]
			then
				echo $line
			else
				res=("# ")
				for i in ${reqcols[@]}
				do
					res+="$(echo $line | cut -d: -f $(($i+1))) ";
				done
				res+=(" #");
				echo ${res[@]};
			fi
		fi

		line_number=$((line_number + 1))
	done
};

function insertRow {

};

function checkdb {
	#Checks for database existence
	if [[ $(ls ./databases 2> /dev/null | grep ^$1$ | wc -l) -eq 1 ]]
	then 
		return 1
	else
		return 0
	fi
};

function createdb {
	checkdb $1;	
	if [[ $? -eq 1 ]]
	then
		echo "Database $1 already exists!, cannot create!";	
	else
		if [[ -z "$1" ]]
		then
			echo "Enter a valid name!"
		else
			mkdir -p ./databases/$1;
			echo "Created a new database: $1"
		fi
	fi
};

function listdb {
	echo "Current Databases:";
	echo `ls ./databases 2> /dev/null`
};

function connectdb {
        checkdb $1;
        if [[ $? -eq 1 ]]
        then
			cd ./databases/$1; echo "Currently Connected to database $1";
			select order in 'Create Table' 'List Tables' 'Drop Table' 'Insert into Table' 'Select From Table' 'Delete From Table' 'Update Table' 'Disconnect'
			do
				case $order in
					'Create Table') 
						read -p "Insert name of table: " tname;
						createtable $tname
					;;

                    'List Tables')
						if [[ $(ls | wc -l) -eq 0 ]]
						then
							echo "No tables in this database!"
						else
							ls;
						fi
						
                    ;;
                    
					'Drop Table')
						read -p "Which table to drop? " tname;
						checktable $tname;
						if [[ $? -eq 0 ]]
						then
							echo "No such Table!"
						else
							rm -f $tname;
							echo "Table $tname deleted!"
						fi
					;;

					'Select From Table')
						read -p "Which Table to Select From? " tname;
						checktable $tname;
						if [[ $? -eq 1 ]]
						then
							selectTable $tname;
						else
							echo "No Such Table!";
						fi
					;;

                    'Insert into Table')
						read -p "Enter table Name: " tname;
						checktable $tname;
						if [[ $? -eq 1 ]]
						then
							insertRow $tname;
						else
							echo "No Such Table!"
						fi
                    ;;


#                      “Delete From Table”)
#                       ;;
#
#                       “Update Table”)
#                       ;;
					'Disconnect')
						cd ../../;
						echo "Disconnected! You're back to the main menu.";
						break;;

					*) echo "Invalid Choice!";;
					esac
			done
        else
                echo "No such Database!"
        fi
};

function deletedb {
	read -p "Are you sure you want to delete database: $1 (y/n)?"
	if [[ $REPLY = 'y' ]]
	then
		checkdb $1;	
        	if [[ $? -eq 1 ]]
			then 
				rm -rf ./databases/$1
				echo "Database Deleted!"
			else
				echo "No such Database!"
			fi
	fi
}; 

#End of Functions

select choice in "Create Database" "List Databases" "Connect to Databases" "Drop Database"
do
	case $choice in 
		"Create Database") read -p "Enter the name of your new database: " newdb;
		createdb $newdb;; #function db creates databases

		"List Databases") listdb;;

		"Connect to Databases") read -p "Enter the name of the desired database: " currentdb;
		connectdb $currentdb;;

		"Drop Database") read -p "Which database to drop? " deleteddb;
		deletedb $deleteddb;;

		*) echo "Invalid Choice!"
	esac
done
