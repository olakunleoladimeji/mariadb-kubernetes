STOP SLAVE;
CHANGE MASTER TO 
    MASTER_HOST='{{APPLICATION}}-{{ENVIRONMENT}}-mdb-ms-0.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust', 
	MASTER_PORT=3306, 
	MASTER_USER='{{REPLICATION_USER}}', 
	MASTER_PASSWORD='{{REPLICATION_PASSWORD}}', 
	MASTER_LOG_POS=4, 
	MASTER_LOG_FILE='mariadb-bin.000001', 
	MASTER_CONNECT_RETRY=1;
START SLAVE;

SET GLOBAL max_connections=10000;
SET GLOBAL gtid_strict_mode=ON;
