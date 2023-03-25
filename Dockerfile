FROM mongo:latest

RUN apt update && \
    apt install awscli -y

WORKDIR /scripts

COPY backup-mongodb.sh .
RUN chmod +x backup-mongodb.sh

ENV MONGODB_URI="" \
    MONGODB_OPLOG="" \
    MONGODB_NAME="" \
    BUCKET_URI="" \
    AWS_ACCESS_KEY_ID="" \
    AWS_SECRET_ACCESS_KEY="" \
    AWS_DEFAULT_REGION="" \
    S3_ENDPOINT_URL="" \
    DB_BACKUP_MAX_FILES="" \
    DB_BACKUP_MAX_DAYS=""

RUN apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

CMD ["/scripts/backup-mongodb.sh"]
