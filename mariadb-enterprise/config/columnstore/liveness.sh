
#!/bin/bash
set -e
MCSDIR=/usr/local/mariadb/columnstore
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"

if [ -e ${MCSDIR}/bin/mcsadmin ]; then
    #Container already initialized
    # check system status
    ${MCSDIR}/bin/mcsadmin getSystemStatus
else
    exit 0
fi