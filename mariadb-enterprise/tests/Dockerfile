FROM mariadb/server:10.3

# install curl in order to be able to get MariaDB Server from github
RUN apt-get update && apt-get install -y mariadb-test && apt-get install -y curl

# install sysbench
RUN curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | bash
RUN apt-get install -y sysbench

# copy test suites and scripts
COPY ./test-suite /usr/share/mysql/mysql-test/suite/bookstore
COPY ./run-*.sh ./

# run test case
ENTRYPOINT ["/bin/bash", "./run-tests.sh"]
