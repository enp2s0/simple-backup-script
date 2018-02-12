#!/bin/sh

DIRS=('/home /usr /var /etc /boot /bin /sbin /srv /lib /lib64 /opt /root')
BKROOT='/mnt/backup/'

DATE=`date +%m%d%y`
TIME=`date +%H%M%S`
HOST=`hostname`

function sighandler()
{
	echo ""
	echo "Interrupt received, shutting down!"
	if [ $name != "" ]; then
		echo "Backup of $name is incomplete, removing..."
		if [ -e $BKROOT""backups/$DATE/$TIME""$name.tar ]; then
			rm $BKROOT""backups/$DATE/$TIME""$name.tar
		fi
	if [ -e $BKROOT""backups/$DATE/$TIME""$name.tar.gz ]; then
			rm $BKROOT""backups/$DATE/$TIME""$name.tar,gz
		fi
	fi

	echo "Backups can be found in:"
	echo "    "$BKROOT"backups/$DATE/$TIME/"
	exit 0
}

if [ ! `whoami` == "root" ]; then
	echo "This script must be run as user root (UID 0) in order to backup system files!"
	echo "This script will rerun itself with 'sudo'. It may ask for a password."
	sudo $0 $@
	exit 0
fi

clear
trap sighandler 2 3 15

if [ "$1" == "clean" ]; then
	echo "Clean mode specified, removing old backups..."
	rm -rf $BKROOT/*
fi

if [ ! -e $BKROOT ]; then
	mkdir $BKROOT
	echo "Please mount a disk at $BKROOT, then rerun this script!"
	exit 1
fi

cd $BKROOT

if [ ! -e 'backups' ]; then
	mkdir 'backups'
fi

cd backups

echo "Starting backup of $HOST on `date +%m-%d-%y`!"
echo "------------------------------------------------------------------"

if [ ! -e $DATE ]; then
	mkdir $DATE
fi
cd $DATE

if [ ! -e $TIME ]; then
	mkdir $TIME
fi
cd $TIME

for name in $DIRS; do
	echo "Output for file: $name" >> output.txt
	echo "------------------------------------------------------" >> output.txt
	if [ -d $name ]; then
		TYPE="Directory"
	fi
	
	if [ -f $name ]; then
		TYPE="File"
	fi
	
	echo "Backing up $name ($TYPE)..."
	
	if [ ! -e $name ]; then
		echo "    Error: $name: No such file or directory!"
		continue;
	fi
	
	ARCHIVE=`echo $name.tar | tr -d /`
	
	echo "'tar' Output:" >> output.txt
	echo "-----------------------------------------------------" >> output.txt
	echo "    Archiving..."
	tar -cvf $ARCHIVE $name &>> output.txt
	
	echo "'gzip' Output:" >> output.txt
	echo "-----------------------------------------------------" >> output.txt
	echo "    Compressing..."
	gzip $ARCHIVE &>> output.txt
	echo ""
	echo "-----------------------------------------------------" >> output.txt
done

echo "Cleaning up..."
echo "    Compressing logs..."
echo "        Archiving..."
tar -cvf output.txt output.tar &> /dev/null

echo "        Compressing..."
gzip output.tar &> /dev/null


echo "------------------------------------------------------------------"
echo "Backup Complete!"
echo "Backups can be found in:"
echo "    "$BKROOT"backups/$DATE/$TIME/"
