
#!/bin/bash
set -e
MCSDIR=/usr/local/mariadb/columnstore
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"

if [ -e $FLAG ] && [ -e ${MCSDIR}/mysql/bin/mcsadmin]; then
    #Container already initialized
    # check system status
    ${MCSDIR}/mysql/bin/mcsadmin getSystemStatus | tail -n +9 | grep System | grep -v "System and Module statuses" | grep -q 'System.*ACTIVE'
    exit 0
fi