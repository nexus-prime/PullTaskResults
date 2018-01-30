#! /bin/bash
# This is a special script to parse the results pages of the Einstein@home website
#
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HostID=$1			
NumPages=$2				
Output="$(echo $SCRIPT_DIR | awk '{gsub("resources", "", $0); print}')$3"
echo $Output
delim=';'
echo "Task;Work Unit;Sent [UTC];Time Reported [UTC];Status;Run Time [sec];CPU TIme [sec];Credit;Application" > $Output

for jnd in `seq 0 $(($NumPages-1))`;
do

wget "https://einsteinathome.org/host/$HostID/tasks/4/0?page=$jnd" -O "$SCRIPT_DIR/x.temp"



# Kill loop if website is out of data
	if grep -q 'Go to next page' $SCRIPT_DIR/x.temp
	then
	:
	else
	break
	fi
# Trim header and navigation buttons
	headersize="$(cat $SCRIPT_DIR/x.temp| grep -n 'task-name active'|cut -f1 -d:|head -1)"
	headersize="$(($headersize-1))d"
	sed -i "1,$headersize" $SCRIPT_DIR/x.temp
	head -n -76 $SCRIPT_DIR/x.temp > $SCRIPT_DIR/x.temp2
	mv $SCRIPT_DIR/x.temp2 $SCRIPT_DIR/x.temp

# Add new lines
 	cat $SCRIPT_DIR/x.temp | awk '{gsub("</td><td", "</td>~<td", $0); print}' > $SCRIPT_DIR/x.temp2 
	mv $SCRIPT_DIR/x.temp2 $SCRIPT_DIR/x.temp
	cat $SCRIPT_DIR/x.temp | tr '~' '\n' > $SCRIPT_DIR/x.temp2
	mv $SCRIPT_DIR/x.temp2 $SCRIPT_DIR/x.temp


	length="$(wc -l < $SCRIPT_DIR/x.temp)"
	
	if [ "$length" -eq "0" ]
	then
		break
	fi



	
	dataseg="9"

	   for ind in `seq 0 19`;
	   do
		readln=$(( $ind*$dataseg+1))

		text=""
		text="$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp | sed 's/.*task\///' | cut -d\" -f1)$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp | sed 's/.*workunit\///' | cut -d\" -f1)$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  tr --delete , | grep -Eo "[0-9]+")$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  tr --delete , | grep -Eo "[0-9]+")$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  tr --delete , | grep -Eo "[0-9]+")$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{21\}//' | sed 's/.\{11\}$//')"
		echo $text >> $Output

	   done  

done

grep  'UTC' $Output > temp && mv temp $Output
rm $SCRIPT_DIR/x.temp

cat $Output



