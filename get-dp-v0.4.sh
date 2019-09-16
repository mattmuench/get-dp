#!/bin/bash
# ident: get-dp.sh, v0.4, 2019/09/16.
# usual line for RHEL on iostat is:
#   Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
#   sdj               0.00   104.00    0.00 1043.00     0.00 115908.00   222.26     0.24    0.23    0.00    0.23   0.18  19.10

usage() {
	echo "$0 -t top -p iovalue -d device -u upper -f file [-n]"
	echo " -d device   - device name as stated in iostat"
	echo " -t top      - number of highest numerical value to pick"
	echo " -f file     - iostat formatted output file from RHEL"
	echo " -p iovalue  - name of an iostat value to display highest values for"
	echo " -u upper    - upper ceiling for requested value to report all ones above"
	echo "             - shows percentage for values higher than upper ceiling "
	echo " -n          - if the picked max of the value is 0.00 then dont display an entry for the device"
	echo "    valid iovalues are: rrqm wrqm r w rkb wkb avgrq-sz avgqu-sz await r_wait w_wait util"
}

TEMP=/tmp/get-dp-$$.tmp


#
# check arguments
#
# read arguments
dflag=0
fflag=0
pflag=0
tflag=0
uflag=0
nflag=0
while getopts d:f:p:t:u:hn name; do
        case $name in
                d)      dflag=1
                        DEVICE="$OPTARG";;

                f)      fflag=1
                        FILE="$OPTARG";;

                p)      pflag=1
                        COL="$OPTARG";;

                t)      tflag=1
                        TOP="$OPTARG";;

                u)      uflag=1
                        UPPER="$OPTARG";;

                n)      nflag=1
                        ;;

                h)      usage
                        exit 2;;
        esac
done

if [ $fflag -ne 1 ]; then
        echo "$0 - ERROR: -f option must be set"
        usage
        exit 2
fi
if [ $dflag -ne 1 ]; then
        echo "$0 - ERROR: -d option must be set"
        usage
        exit 2
fi
if [ $pflag -ne 1 ]; then
        echo "$0 - ERROR: -p option must be set"
        usage
        exit 2
fi
if [ $tflag -ne 1 ]; then
        echo "$0 - ERROR: -t option must be set"
        usage
        exit 2
fi


case $COL in 
	"rrqm") PICK=2;;
	"wrqm") PICK=3;;
	"r")	PICK=4;;
	"w") PICK=5;;
	"rkb") PICK=6;;
	"wkb") PICK=7;;
	"avgrq-sz") PICK=8;;
	"avgqu-sz") PICK=9;;
	"await") PICK=10;;
	"r_wait") PICK=11;;
	"w_wait") PICK=12;;
	"util") PICK=14;;
	*) echo "$COL is not a valid argument for iovalue"; usage; exit;;
esac

trap 'rm -f $TEMP; echo "Terminated and removed $TEMP."; exit 0' 1 2 5 10 15

_FOUND=0
if [ $uflag -eq 1 ]; then
	for _UP in `grep $DEVICE $FILE |awk '{print $'$PICK'}'|sort -un`; do 
		if [ `echo "$_UP > $UPPER"|bc` -eq 1 ]; then
			_FOUND=1
			break
		fi
	done
	if [ $_FOUND -ne 1 ]; then
		echo "$0 - $DEVICE => INFO: no value of that size, check for lower value"
		exit 1
	else
		# get line number form list to start from
		START=`grep $DEVICE $FILE |awk '{print $'$PICK'}'|sort -un|grep -n $_UP|cut -d: -f1`
		END=`grep $DEVICE $FILE |awk '{print $'$PICK'}'|sort -un|wc -l`
		DIFF=`expr $END - $START + 1`
		# run through this list - the number of values found might be really long and to prevent from exhausting memory we use
		# use the good old temporary file
		for HIGH in `grep $DEVICE $FILE |awk '{print $'$PICK'}'|sort -un|tail -$DIFF`; do grep $DEVICE $FILE |awk  "{if (\$$PICK ~ /$HIGH/ ) { print \$0; } }" ; done | wc -l > $TEMP
		NUM=`cat $TEMP`
		ALL=`grep $DEVICE $FILE | wc -l`
		# calculate percentage of NUM in the whole number of lines collected
		PORTION=`echo 'scale=7;'"$NUM/$ALL*100"|bc`
		echo "$0 - $DEVICE => RESULT: portion of lines with $COL > $UPPER = $PORTION %"
	fi
else
	if [ "`grep $DEVICE $FILE |awk '{print $'$PICK'}'|sort -un|tail -1`" != "0.00" ]; then
		echo "Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util"
		for HIGH in `grep $DEVICE $FILE |awk '{print $'$PICK'}'|sort -un|tail -$TOP`; do grep $DEVICE $FILE |awk  "{if (\$$PICK ~ /$HIGH/ ) { print \$0; } }"; done
	else
		if [ $nflag -ne 1 ]; then
			echo "Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util"
			echo "$DEVICE          0.00     0.00    0.00    0.00     0.00     0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00"
		fi
	fi
fi
rm -f $TEMP
trap 1 2 5 10 15
#Done.
