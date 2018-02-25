#! /bin/bash
# bash PullTasks.sh ProjectName HostID NumPages
# $1=project URL
# $2=host ID
# $3=Pages of BOINC tasks to return (20 tasks per page)
# $4=Output File Name

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#echo $SCRIPT_DIR
# Load input data
URL="$(cat $SCRIPT_DIR/resources/WhiteList_URL_Lookup.txt | grep "$1"	| awk -F[=,=] '{print $2}')"
HostID=$2			
NumPages=$3		
dir=$(pwd)		
Output=$4

echo $URL
delim=";"
echo "Task;Work Unit;Sent [UTC];Time Reported [UTC];Status;Run Time [sec];CPU TIme [sec];Credit;Application" > $Output

# Check for projects that are incompatible with main script
if [ "$URL" == "https://einsteinathome.org" ]
then 
	bash $SCRIPT_DIR/PullTasks_Einstein_Special.alt $HostID $NumPages $Output
	
elif [ "$URL" == "http://www.rechenkraft.net/yoyo" ]
then
	bash $SCRIPT_DIR/PullTasks_Yoyo_Special.alt $HostID $NumPages $Output
	
elif [ "$URL" == "https://download.worldcommunitygrid.org/boinc" ]
then
	echo "World Community Grid does not report data task data on a per host basis"
else 
# Start Main Loop
for jnd in `seq 0 $(($NumPages-1))`;
do
offset=$(($jnd*20))


# Pull data from the website

	wget "$URL/results.php?hostid=$HostID&offset=$offset&show_names=0&state=4&appid=0" -O $SCRIPT_DIR/resources/x.temp
	if grep -q '<title>Invalid tasks for computer' $SCRIPT_DIR/resources/x.temp
	then
		wget "$URL/results.php?hostid=$HostID&offset=$offset&show_names=0&state=3&appid=0" -O $SCRIPT_DIR/resources/x.temp
	fi

	
# Kill loop if website is out of data
	if grep -q "explain_state" $SCRIPT_DIR/resources/x.temp
	then
	:
	else
	break
	fi

# Reformat to adjust for minor incosistencies in results.php data
	headersize="$(cat $SCRIPT_DIR/resources/x.temp| grep -n "result.php?resultid"|cut -f1 -d:|head -1)"
	headersize="$(($headersize-1))d"
	sed -i "1,$headersize" $SCRIPT_DIR/resources/x.temp
	head -n -6 $SCRIPT_DIR/resources/x.temp > $SCRIPT_DIR/resources/x.temp2
	mv $SCRIPT_DIR/resources/x.temp2 $SCRIPT_DIR/resources/x.temp


	cat $SCRIPT_DIR/resources/x.temp | awk '{gsub("</td><td", "</td>~<td", $0); print}' > $SCRIPT_DIR/resources/x.temp2 
	mv $SCRIPT_DIR/resources/x.temp2 $SCRIPT_DIR/resources/x.temp
	cat $SCRIPT_DIR/resources/x.temp | tr '~' '\n' > $SCRIPT_DIR/resources/x.temp2
	mv $SCRIPT_DIR/resources/x.temp2 $SCRIPT_DIR/resources/x.temp

	sed -i '/^$/d' $SCRIPT_DIR/resources/x.temp
	sed -i 's/ //g' $SCRIPT_DIR/resources/x.temp

	cat $SCRIPT_DIR/resources/x.temp | awk '{gsub("</td></tr>", "</td>", $0); print}' > $SCRIPT_DIR/resources/x.temp2 
	mv $SCRIPT_DIR/resources/x.temp2 $SCRIPT_DIR/resources/x.temp


	
	length="$(wc -l < $SCRIPT_DIR/resources/x.temp)"
	
	if [ "$length" -eq "0" ]
	then
		break
	fi
	
	dataseg="$(cat $SCRIPT_DIR/resources/x.temp| grep -n "result.php"|cut -f1 -d:|head -2|tail -1)"
	
	dataseg="$(( $dataseg - 1 ))"

	   for ind in `seq 0 19`;
	   do
		readln=$(( $ind*$dataseg+1))

		text=""
		text="$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp | sed 's/.*?//' | awk -F[=,\"] '{print $2}')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp | sed 's/.*?//' | awk -F[=,\"] '{print $2}')$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  tr --delete , | grep -Eo "[0-9]+\.[0-9]+")$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  tr --delete , | grep -Eo "[0-9]+\.[0-9]+")$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  tr --delete , | grep -Eo "[0-9]+\.[0-9]+")$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/resources/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')"

		echo $text >> $Output
	   done  
done
grep  'UTC' $Output > temp && mv temp $Output

grep  -v '.rogress' $Output > temp && mv temp $Output

rm $SCRIPT_DIR/resources/x.temp 
#cat $Output
fi
