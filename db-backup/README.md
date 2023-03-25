# Database backup

Utility Helm chart for creating a database backup

## Parameters

| Parameter                    | Description                                        | Default                                 |
|------------------------------|----------------------------------------------------|-----------------------------------------|
| `image.repository`           | Database backup docker image repository            | `docker.io/vanquynguyen/mongodb-backup` |
| `image.tag`                  | Database backup docker images tag                  | `latest`                                |
| `image.imagePullPolicy`      | Database backup docker images pull policy          | `IfNotPresent`                          |
| `persistence.enabled`        | Enable Database backup persistence using PVC       | `true`                                  |
| `persistence.accessMode`     | PVC Access Mode for database backup volume         | `ReadWriteOnce`                         |
| `persistence.size`           | PVC Storage Request for database backup volume     | `1GB`                                   |
