#!/bin/bash
ZEPPELIN_WEB_CONF_DIR=/zeppelin/conf
find $ZEPPELIN_WEB_CONF_DIR -type f -name *.ini -exec sed -i "s/{{demo_user}}/${ZEPPELIN_WEB_DEMO_USER}/g" {} +
find $ZEPPELIN_WEB_CONF_DIR -type f -name *.ini -exec sed -i "s/{{demo_pass}}/${ZEPPELIN_WEB_DEMO_PASS}/g" {} +
find $ZEPPELIN_WEB_CONF_DIR -type f -name *.ini -exec sed -i "s/{{admin_user}}/${ZEPPELIN_WEB_ADMIN_USER}/g" {} +
find $ZEPPELIN_WEB_CONF_DIR -type f -name *.ini -exec sed -i "s/{{admin_pass}}/${ZEPPELIN_WEB_ADMIN_PASS}/g" {} +
/zeppelin/notebooks/install_notebooks.sh & /zeppelin/bin/zeppelin.sh 