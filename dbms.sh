#!/usr/bin/bash

#Functions go here!
#Table Functions
function checktable {
        #Checks for table existence
        if [[ -f $1 ]]
        then
                return 1
        else    
                return 0
        fi  
};

function join_by { 
	local IFS="$1"; shift; echo "$*"; 
};

function tolowercase {
	echo $(echo $@ | tr '[:upper:]' '[:lower:]');
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
		if [[ " $colname " = " ${fields[$i]} " ]]; 
		then
				res=$i;
				break;
		fi; 
	done;

	return $res;
};

function checkDataType {
	local value=$1;
	local dtype=$2;
	
	case "${dtype}" in
		'int')
			if [[ $value = *([0-9]) ]]; then
				return 1
			else
				return 0
			fi
		;;
		'str')
			if ! [[ $value = *([0-9]) ]]; then
				return 1
			else
				return 0
			fi
		;;
		*)
			return 0
		;;
	esac
            
};

function createtable {
	tname=$1; pairs=$2;

	#Reads and Check Column Names and Types1
	local IFS=","; pairs=($pairs); 
	unset cols; unset types;

	local IFS="=";
	for (( i=0; i<${#pairs[@]}; i++ ));
	do 	
		pair=(${pairs[$i]})
		cols[$i]+=${pair[0]}
		types[$i]+=${pair[1]}
	done
	
	echo $(join_by ':' ${cols[@]}) > $tname; 
	echo $(join_by ':' ${types[@]}) >> $tname;
	#Check for equal number of fields
	if [[ ${#cols[@]} -ne ${#types[@]} ]]; then
		echo "Unmatched Number of Fields";
		rm -f $tname;
		return 0; 
	fi;

	for col in "${cols[@]}"
	do
		if [[ $col =  *" "* ]] || [[ -z $col ]] 
		then
			echo "Table names cannot be empty or contain white spaces!"
			rm -f $tname;
			return 0;
		fi
	done

	local IFS=":";
	for type in "${types[@]}"
	do
		if [[ $type = "str" ]] || [[ $type = "int" ]] 
		then
			continue;
		else
			echo "Invalid Type Found! $type"
			rm -f $tname;
			return 0;
		fi
	done

};

function selectTable {
	tname=$1; cols=$2; condition=$3;
	if [[ ! -z $condition ]] #Check to see if condition given
	then
			key=$(echo $condition | cut -d= -f1)
			searchval=$(echo $condition | cut -d= -f2)
			getColIndex $tname $key;
			colindex=$?;

			if [[ $colindex -eq '255' ]]
			then
				echo "Cannot find Column: $key!"
				return 0;
			fi

			colindex=$(($colindex+1));
			type=$(sed -n "2p" "$tname" | cut -d: -f $colindex);
	fi

	local IFS=":"; headers=($(head -1 $tname));
	local IFS=","; cols=($cols);


	if [[ $cols = "all" ]]
	then
		reqcols='all';
	else
		#Check if requested columns are real columns
		len=${#cols[@]}
		for (( i=0; i<$len; i++ ));
		do 	
			if [[ ! " ${headers[@]} " =~ " ${cols[$i]} " ]]; 
			then
				echo "Column ${cols[$i]} Not Found!"
				return;
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

	filelength=$(cat $tname | wc -l);
	line_number=3
	if [[ $cols = "all" ]]
	then join_by ":" ${headers[@]};
	else echo ${cols[@]}; fi;
	echo "==========";

	while [ "$line_number" -le $filelength ]; do
		line="$(sed -n "$line_number p" "$tname")"
		if [ -z $condition ] || [ $(echo $line | cut -d: -f $colindex) = $searchval ] 2> /dev/null
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
	tname=$1;
	row=$2;
	local IFS=":";
	headers=($(head -1 $tname));
	types=($(head -2 $tname | tail -1));

	local IFS=","; row=($row);

	#Check for equal number of fields
	if [[ ${#headers[@]} -ne ${#row[@]} ]]; then
		echo "Unmatched Number of Fields";
		return 0; 
	fi;

	for (( i=0; i<${#headers[@]}; i++ ));
	do 	
		local dtype=${types[$i]};
		local value=${row[$i]};

		checkDataType $value $dtype
		if [[ $? -eq 0 ]]; 
		then
			echo "Insert $value Failed! Your Input must be $dtype"
			return 0;
		fi
	done
	join_by ":" ${row[@]} >> $tname;
};

function deleteRow {
	tname=$1;
	condition=$2;

	if [[ ! -z $condition ]] #Check to see if condition given
	then
			key=$(echo $condition | cut -d= -f1)
			searchval=$(echo $condition | cut -d= -f2)
			getColIndex $tname $key;
			colindex=$?;

			if [[ $colindex -eq '255' ]]
			then
				echo "Cannot find Column: $key!"
				return 0;
			fi

	else
		echo "No condition is given, will empty table cells but keep the table structure"
	fi

	local IFS=":"; headers=($(head -1 $tname));

	filelength=$(cat $tname | wc -l);
	line_number=3
	while [ "$line_number" -le $filelength ]; do
		line=($(sed -n "$line_number p" "$tname"));
		if [ -z $condition ] || [ ${line[$colindex]} = $searchval ] 2> /dev/null
		then
			echo "Deleted entry == $line == Successfully!"
			sed "$line_number d" $tname > "$tname new"
			rm -f $tname
			mv "$tname new" $tname;
			filelength=$(cat $tname | wc -l);
		else
			line_number=$((line_number + 1))

		fi
	done
};

function updateTable {
	tname=$1; update=$2; condition=$3;

	local IFS=":";
	headers=($(head -1 $tname));
	types=($(head -2 $tname | tail -1));
	newkey=$(echo $update | cut -d= -f1);
	newval=$(echo $update | cut -d= -f2);
	getColIndex $tname $newkey; changecol=$?;

	dtype=${types[$changecol]};
	checkDataType $newval $dtype
	if [[ $? -eq 0 ]]; 
	then
		echo "Updating $newkey Failed! Your Input must be $dtype"
		return 0;
	fi

	if [[ ! -z $condition ]] #Check to see if condition given
	then
			key=$(echo $condition | cut -d= -f1)
			searchval=$(echo $condition | cut -d= -f2)
			getColIndex $tname $key; colindex=$?;

			if [[ $colindex -eq '255' ]]
			then
				echo "Cannot find Column: $key!"
				return 0;
			fi



	else
		echo "No condition is given, will empty table cells but keep the table structure"
	fi

	filelength=$(cat $tname | wc -l);
	line_number=3
	while [ "$line_number" -le $filelength ]; do
		line=($(sed -n "$line_number p" "$tname"))
		if [ -z $condition ] || [ ${line[$colindex]} = $searchval ] 2> /dev/null
		then

			oldval=${line[$changecol]};
			sed -i "$line_number s/[^:]*/$newval/"$(($changecol+1)) $tname

		fi
		line_number=$((line_number + 1))

	done
	
};

#Database Functions
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
						printf '\nEnter the Create query as follows:\nCREATE TABLE {Table Name} VALUES (col1=type1,col2=type2,...,coln=typen)\n';
						read query; 
						query=$(tolowercase $(echo $(echo $query | sed 's/ *= */=/g') | sed 's/ *, */,/g') | tr -d '()');
						local IFS=" "; fields=($query); tname=${fields[2]}; cols=${fields[4]};
						checktable $tname;
						if [[ $? -eq 0 ]]
						then
							createtable $tname $cols;
						else
							echo "Table already exists!"
						fi
						
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
						printf '\nEnter the Drop query as follows:\DROP {Table Name}\n';
						read query; query=$(tolowercase $query); local IFS=" "; fields=($query);
						tname=${fields[1]};
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
						printf '\nEnter the select query as follows:\nSelect all or col1,..,coln FROM {TABLE} WHERE (optional) colx=val\n';
						read query; query=$(tolowercase $(echo $(echo $query | sed 's/ *= */=/g') | sed 's/ *, */,/g'));
						local IFS=" "; fields=($query);
						cols=${fields[1]};tname=${fields[3]}; condition=${fields[5]};

						checktable $tname;
						if [[ $? -eq 1 ]]
						then
							selectTable $tname $cols $condition ;
						else
							echo "No Such Table!";
						fi
					;;

                    'Insert into Table')
						printf '\nEnter the insert query as follows:\nINSERT INTO {TABLE} VALUES (col1,col2,...coln)\n';
						read query; 
						set -x;
						query=$(tolowercase $(echo $(echo $query | sed 's/ *= */=/g') | sed 's/ *, */,/g') | tr -d '()');
						local IFS=" "; fields=($query);
						tname=${fields[2]}; cols=${fields[4]};

						checktable $tname;
						if [[ $? -eq 1 ]]
						then
							insertRow $tname $cols;
						else
							echo "No Such Table!"
						fi
						set +x;
                    ;;

                    'Delete From Table')
						printf '\nEnter the delete query as follows:\nDelete FROM {TABLE} WHERE (optional) colx=val\n';
						read query; query=$(tolowercase $(echo $(echo $query | sed 's/ *= */=/g'))); local IFS=" "; fields=($query);
						tname=${fields[2]}; condition=${fields[4]};

						checktable $tname;
						if [[ $? -eq 1 ]]
						then
							deleteRow $tname $condition;
						else
							echo "No Such Table!"
						fi
                    ;;

					'Update Table')
						printf '\nEnter the update query as follows:\nUpdate {TABLE} SET colx=val\n WHERE (optional) colx=val\n';
						read query; query=$(tolowercase $(echo $(echo $query | sed 's/ *= */=/g'))); local IFS=" "; fields=($query);
						tname=${fields[1]}; update=${fields[3]}; condition=${fields[5]};

						checktable $tname;
						if [[ $? -eq 1 ]]
						then
							updateTable $tname $update $condition;
						else
							echo "No Such Table!"
						fi
                    ;;

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
		newdb=$(tolowercase $newdb)
		createdb $newdb;; #function db creates databases

		"List Databases") listdb;;

		"Connect to Databases") read -p "Enter the name of the desired database: " currentdb;
		currentdb=$(tolowercase $currentdb)
		connectdb $currentdb;;

		"Drop Database") read -p "Which database to drop? " deleteddb;
		deleteddb=$(tolowercase $deleteddb)
		deletedb $deleteddb;;

		*) echo "Invalid Choice!"
	esac
done
