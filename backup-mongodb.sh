#!/bin/bash

set -e

SCRIPT_NAME=backup-mongodb
ARCHIVE_NAME="$MONGODB_NAME"_$(date +%Y_%m_%d_%H%M%S).gz
OPLOG_FLAG=""

if [ -n "$MONGODB_OPLOG" ]; then
	OPLOG_FLAG="--oplog"
fi

echo "[$SCRIPT_NAME] Dumping all MongoDB databases to compressed archive..."

mongodump $OPLOG_FLAG \
	--archive="$ARCHIVE_NAME" \
	--gzip \
	--uri "$MONGODB_URI" \
    --authenticationDatabase=admin

S3_ENDPOINT_OPT=""
if [ ! -z "$S3_ENDPOINT_URL" ]; then
  S3_ENDPOINT_OPT="--endpoint-url $S3_ENDPOINT_URL"
fi

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

echo "[$SCRIPT_NAME] Uploading compressed archive to S3 bucket..."
aws ${S3_ENDPOINT_OPT} s3 cp "$ARCHIVE_NAME" "$BUCKET_URI/db-backup/$ARCHIVE_NAME"

echo "[$SCRIPT_NAME] Cleanup: remove backups older than $DB_BACKUP_MAX_DAYS days"
aws ${S3_ENDPOINT_OPT} s3 ls "$BUCKET_URI/db-backup/" | while read -r line; do
    createDate=`echo $line|awk {'print $1" "$2'}`
    createDate=`date -d"$createDate" +%s`
    olderThan=`date --date "$DB_BACKUP_MAX_DAYS days ago" +%s`
    if [[ $createDate -lt $olderThan ]]
        then
        fileName=`echo $line|awk {'print $4'}`

        if [[ $fileName != "" ]]
        then
            aws ${S3_ENDPOINT_OPT} s3 rm "$BUCKET_URI/$fileName"
        fi
    fi
done;

echo "[$SCRIPT_NAME] Cleanup: keeping maximum $DB_BACKUP_MAX_FILES backup(s)"
LS=$(aws ${S3_ENDPOINT_OPT} s3 ls "$BUCKET_URI/db-backup/")
TOTAL_FILES=$(echo "$LS" | wc -l)
DELETE_FILES=0
if [ "$TOTAL_FILES" -gt "$DB_BACKUP_MAX_FILES" ]; then
    DELETE_FILES=$((TOTAL_FILES-DB_BACKUP_MAX_FILES))
fi
if [ "$DELETE_FILES" -gt 0 ]; then
    aws ${S3_ENDPOINT_OPT} s3 ls "$BUCKET_URI/db-backup/" --recursive | sort | head -n -"$DELETE_FILES" | while read -r line ; do
        fileName=`echo $line|awk {'print $4'}`
        echo "Removing ${fileName}"
        aws ${S3_ENDPOINT_OPT} s3 rm "$BUCKET_URI/${fileName}"
    done
fi

echo "[$SCRIPT_NAME] Cleaning up compressed archive..."
if [ -n "$ARCHIVE_NAME" ]; then
    rm "$ARCHIVE_NAME"
fi

echo "[$SCRIPT_NAME] Backup complete!"
