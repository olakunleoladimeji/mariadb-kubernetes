#!/bin/bash

ZEPPELIN_WEB_NOTEBOOK_DIR=/zeppelin/notebooks
CUSTOM_NOTEBOOKS=$(ls $ZEPPELIN_WEB_NOTEBOOK_DIR/*.json -la 2>/dev/null | wc -l)
function customise(){
    find $ZEPPELIN_WEB_NOTEBOOK_DIR -type f -name *.json -exec sed -i "s/{{columnstore_host_nm}}/{{${MARIADB_DATABASE_SERVICE}}}/g" {} +
}

while [ -z $(curl -s http://${ZEPPELIN_WEB_HOST}:${ZEPPELIN_WEB_PORT}/api/version | grep -o '"status":"OK"' ) ]; do
    sleep 5
done

ZEPPELIN_WEB_LOGIN=$(curl -s -i --data "userName=${ZEPPELIN_WEB_ADMIN_USER}&password=${ZEPPELIN_WEB_ADMIN_PASS}" -X POST http://${ZEPPELIN_WEB_HOST}:${ZEPPELIN_WEB_PORT}/api/login)
ZEPPELIN_WEB_LOGIN_RESULT=$(grep -o 'HTTP/1.1 200 OK' <<< $ZEPPELIN_WEB_LOGIN)
INSTALLED_NOTEBOOKS=0



if [ 0 -eq $CUSTOM_NOTEBOOKS ]; then
    echo "No custom notebooks to install on $(date)"
else
    echo "Installing custom notebooks on $(date) DB ${MARIADB_DATABASE_SERVICE}"
    customise

    for f in $ZEPPELIN_WEB_NOTEBOOK_DIR/*.json; do
        if [ ! -z "$ZEPPELIN_WEB_LOGIN_RESULT" ]; then
            ZEPPELIN_WEB_JSESSIONID=$(grep -o 'JSESSIONID=[^;]*; Path=/; HttpOnly' <<< $ZEPPELIN_WEB_LOGIN | tail -1)
            ZEPPELIN_WEB_NOTEBOOK_INS_RESULT=$(curl -s -i -b "${ZEPPELIN_WEB_JSESSIONID}" -XPOST http://${ZEPPELIN_WEB_HOST}:${ZEPPELIN_WEB_PORT}/api/notebook/import -d@"${f}" | grep -o 'HTTP/1.1 200 OK')
            if [ -z "$ZEPPELIN_WEB_NOTEBOOK_INS_RESULT" ]; then
                exit 556
            else
                INSTALLED_NOTEBOOKS=$((INSTALLED_NOTEBOOKS+1))
            fi
        else 
            exit 555
        fi
    done
    echo "All $INSTALLED_NOTEBOOKS notebooks installed"
fi