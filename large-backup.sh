#!/bin/bash

# Run as ./large-backup.sh [backup-file.mbz (filename must start with 'backup')] [maxsize (in MB, no suffix)]
# For example ./large-backup.sh ~/Desktop/backup-file.mbz 550

# Define variables
LOGSTART="`date +%Y%m%d%H%M`"
MYLOG="$LOGSTART.large-backup.log"
DELETEDFILES="deletedfilehashes.txt"
DELETEDFILESCSV="deletedfilehashescsv.txt"
FILENAMEQUERY="filenamequery.txt"
FILES="files.txt"

# Define variables from arguments
ARG1=$1
ARG2=$2
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

# While directory is over maxsize, delete next largest file
while read -r LINE; do
    # Get directory size to compare to <=maxsize
    DIRECTORYSIZE=$(du -sm $DIRECTORY | sed -e "s:\($DIRECTORY\)::g")
    
    if [ "$DIRECTORYSIZE" -gt +$ARG2 ]; then
        echo "Directory size = $DIRECTORYSIZE" >> $LOCATION/$MYLOG 2>&1
        FILE=$LINE
        HASHDIRECTORY=$(echo $FILE | cut -c1-2)
        
        # Go into hash directory
        cd $HASHDIRECTORY
        
        # Delete file
        rm $FILE
        echo "Deleting $FILE" >> $LOCATION/$MYLOG 2>&1
	echo "'$FILE'" >> $DIRECTORY/$DELETEDFILES
        # Go back up to files directory
        cd ..
    fi
done < $FILES

# Put list of deleted file hashes in MySQL query format
# Convert individual lines to comma separated
tr '\n' ',' < $DIRECTORY/$DELETEDFILES > $DIRECTORY/$DELETEDFILESCSV
# Remove trailing comma
sed '$ s/.$//' $DIRECTORY/$DELETEDFILESCSV > $LOCATION/$FILENAMEQUERY
# Add query prefix to hash list
echo "SELECT DISTINCT filename FROM mdl_files WHERE contenthash IN (" | cat - $LOCATION/$FILENAMEQUERY > $DIRECTORY/temp 
# Add query suffix to hash list
echo ");" >> $DIRECTORY/temp && mv $DIRECTORY/temp $LOCATION/$FILENAMEQUERY 

# Zip files into smaller backup
cd $DIRECTORY 
zip -r $BACKUPFILE *
mv $BACKUPFILE $LOCATION 

# Remove files and directory
cd $LOCATION 
rm -rf $DIRECTORY
