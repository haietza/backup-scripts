#!/bin/bash

# Run as ./large-backup.sh [file.mbz]

# Define variables
LOGSTART="`date +%Y%m%d%H%M`"
MYLOG="$LOGSTART.large-backup.log"
#DIRECTORY="backup"
FILES="files.txt"

# Define variables from arguments
ARG1=$1
LOCATION=$(echo $ARG1 | sed 's/\/backup.*//')
DIRECTORY="$LOCATION/backup"
BACKUPFILE=$(echo $ARG1 | sed 's/^.*backup/backup/')

# Move backup file into directory
mkdir $DIRECTORY 
mv $ARG1 $DIRECTORY
cd $DIRECTORY

# Decompress large backup file
tar -xvf $BACKUPFILE

# Delete original backup file
rm $BACKUPFILE

# Sort large files recursively with block size
# Delete spaces at start of line
# Delete total lines
# Delete initial directory lines
# Delete directory lines
# Delete empty lines
# Sort by first column of block size
# Delete first column of block size
cd files
ls -s -S -R | sed -e 's/^ *//; /total/d; /0 /d; /:/d; /^$/d' | sort -k1 -r -n | sed 's/[^ ]* //' > $FILES

# While directory is over 500M, delete next largest file
while read -r LINE; do
    # Get directory size to compare to <=500M
    DIRECTORYSIZE=$(du -sm $DIRECTORY | sed -e "s:\($DIRECTORY\)::g")
    
    if [ "$DIRECTORYSIZE" -gt +500 ]; then
        echo "Directory size = $DIRECTORYSIZE" >> $LOCATION/$MYLOG 2>&1
        FILE=$LINE
        HASHDIRECTORY=$(echo $FILE | cut -c1-2)
        
        # Go into hash directory
        cd $HASHDIRECTORY
        
        # Delete file
        rm $FILE
        echo "Deleting $FILE" >> $LOCATION/$MYLOG 2>&1
        # Go back up to files directory
        cd ..
    fi
done < $FILES

# Zip files into smaller backup
cd $DIRECTORY 
zip -r $BACKUPFILE *
mv $BACKUPFILE $LOCATION 

# Remove files and directory
cd $LOCATION 
rm -rf $DIRECTORY
