RESET MASTER;
CREATE DATABASE test;

CREATE USER '{{REPLICATION_USER}}'@'127.0.0.1' IDENTIFIED BY '{{REPLICATION_PASSWORD}}';
CREATE USER '{{REPLICATION_USER}}'@'%' IDENTIFIED BY '{{REPLICATION_PASSWORD}}';
GRANT ALL ON *.* TO '{{REPLICATION_USER}}'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '{{REPLICATION_USER}}'@'%' WITH GRANT OPTION;

CREATE USER '{{ADMIN_USER}}'@'127.0.0.1' IDENTIFIED BY '{{ADMIN_PASSWORD}}';
CREATE USER '{{ADMIN_USER}}'@'%' IDENTIFIED BY '{{ADMIN_PASSWORD}}';
GRANT ALL ON *.* TO '{{ADMIN_USER}}'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '{{ADMIN_USER}}'@'%' WITH GRANT OPTION;

SET GLOBAL max_connections=10000;
SET GLOBAL gtid_strict_mode=ON;