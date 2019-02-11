FROM mariadb/server:10.3

# install curl in order to be able to get MariaDB Server from github
RUN apt-get update && apt-get install -y mariadb-test && apt-get install -y curl
COPY ./test-suite /usr/share/mysql/mysql-test/suite/bookstore
COPY ./load-data.sh .
# WORKDIR /test
# download and filter the test suites
# RUN curl -L https://codeload.github.com/MariaDB/server/legacy.tar.gz/10.3 | tar xz --wildcards "*/mysql-test/" --strip-components=1

# install Perl dependencies 
# RUN cpan -i Memoize
ENTRYPOINT ["/bin/bash", "./load-data.sh"]
