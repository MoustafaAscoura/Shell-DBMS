#!/usr/bin/env bash

"Insert into Table") read -p "Enter table Name: " tname
					   			if [ -f $tname ] 
								then
									numOfColumn=`head -1 ./$tname | awk 'BEGIN{RS=":"}{print $0}' | wc -l`
        							#echo $numOfColumn
									for((i=1;i<$numOfColumn;i++)); do
										#Array contain Columns Names
										arrayOfColumnNames[$i]=`head -1 ./$tname | cut -d ':' -f$i`
										#Array contain Data Types
										arrayOfDataTypes[$i]=`head -2 ./$tname | tail -1 | cut -d ':' -f$i`
										
									done
									count=1
									while [ $count -lt $numOfColumn ]; do
										read -p "Enter Value Of ${arrayOfColumnNames[$count]}: " value
										dtype=${arrayOfDataTypes[$count]}
										checkDataType $value $dtype
										if [[ $? -eq 1 ]]; then
											echo "$value Inserted"
											echo -n "$value:" >> ./$tname
											count=$(($count + 1))
										else
											echo "Insert $value Failed! Your Input must be ${arrayOfDataTypes[$count]}"
										fi
										
									done
									echo -ne "\n" >> ./$tname;
								else
									echo "Table Not Exist!"

								fi 