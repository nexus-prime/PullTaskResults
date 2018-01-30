#! /bin/bash
# This is a special script to parse the results pages of the Yoyo@home website
#
#


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HostID=$1			
NumPages=$2				
Output="$(echo $SCRIPT_DIR | awk '{gsub("resources", "", $0); print}')$3"

delim=';'
echo "Task;Work Unit;Sent [UTC];Time Reported [UTC];Outcome;Run Time [sec];Credit Claimed;Credit Granted" > $Output

for jnd in `seq 0 $(($NumPages-1))`;
do
offset=$(($jnd*20))
wget "http://www.rechenkraft.net/yoyo/results.php?hostid=$HostID&offset=$offset&show_names=0&state=4&appid=0" -O "$SCRIPT_DIR/x.temp"



# Kill loop if website is out of data
	if grep -q 'result.php?resultid' $SCRIPT_DIR/x.temp
	then
	:
	else
	break
	fi
# Trim header and navigation buttons
	headersize="$(cat $SCRIPT_DIR/x.temp| grep -n 'result.php?resultid'|cut -f1 -d:|head -1)"
	headersize="$(($headersize-1))d"
	sed -i "1,$headersize" $SCRIPT_DIR/x.temp
	head -n -13 $SCRIPT_DIR/x.temp > $SCRIPT_DIR/x.temp2
	mv $SCRIPT_DIR/x.temp2 $SCRIPT_DIR/x.temp


 	cat $SCRIPT_DIR/x.temp | sed "s/'......'//"| sed s/'<font color=>'// | sed 's@</font>@@'  > $SCRIPT_DIR/x.temp2 

	mv $SCRIPT_DIR/x.temp2 $SCRIPT_DIR/x.temp

	sed -i 's/ //g' $SCRIPT_DIR/x.temp


	length="$(wc -l < $SCRIPT_DIR/x.temp)"
	
	if [ "$length" -eq "0" ]
	then
		break
	fi



	
	dataseg="12"

	   for ind in `seq 0 19`;
	   do
		readln=$(( $ind*$dataseg+1))

		text=""
		text="$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp | sed 's/.*?//' | awk -F[=,\"] '{print $2}')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp | sed 's/.*?//' | awk -F[=,\"] '{print $2}')$delim"	
		readln=$(($readln+2))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+2))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  sed 's/^.\{4\}//' | sed 's/.\{5\}$//')$delim"
		readln=$(($readln+2))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  tr --delete , | grep -Eo "[0-9]+\.[0-9]+")$delim"
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  tr --delete , | grep -Eo "[0-9]+\.[0-9]+")$delim"	
		readln=$(($readln+1))
		text="$text$(awk "NR==$readln {print;exit}" $SCRIPT_DIR/x.temp |  tr --delete , | grep -Eo "[0-9]+\.[0-9]+")"	

		echo $text >> $Output

	   done  

done

grep  'UTC' $Output > temp && mv temp $Output
rm $SCRIPT_DIR/x.temp

cat $Output