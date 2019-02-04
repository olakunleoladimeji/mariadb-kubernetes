#!/bin/sh
DATADIR="$(_get_config 'datadir' "$@")"
# clean the target dir
rm -rf $DATADIR/*
# move the backup
mv /backup_local/* $DATADIR/
# make sure the permissions are right
chown -R mysql:mysql $DATADIR/
# needed with Mariabackup 10.2 for ensuring that the server will not attempt crash recovery with an old redo log
rm $DATADIR/ib_logfile*
