FROM mariadb/server:10.3

# install curl in order to be able to get MariaDB Server from github
RUN apt-get update && apt-get install -y mariadb-test && apt-get install -y curl
COPY ./test-suite /usr/share/mysql/mysql-test/suite/bookstore
COPY ./load-data.sh .

# run test case
ENTRYPOINT ["/bin/bash", "./load-data.sh"]
