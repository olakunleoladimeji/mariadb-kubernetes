# MariaDB AX Columnstore Sandbox with Zeppelin Notebooks

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [MariaDB AX Columnstore Sandbox with Zeppelin Notebooks](#mariadb-ax-columnstore-sandbox-with-zeppelin-notebooks)
	* [Installing prerequisites](#installing-prerequisites)
		* [Install Docker](#install-docker)
		* [Install Docker Compose](#install-docker-compose)
		* [Get the MariaDB AX sandbox](#get-the-mariadb-ax-sandbox)
		* [System Requirements](#system-requirements)
		* [Build columnstore](#build-columnstore)
		* [Build Zeppelin instance (optional)](#build-zeppelin-instance-optional)
		* [Bring the whole cluster up](#bring-the-whole-cluster-up)
		* [Troubleshooting](#troubleshooting)
	* [Zeppelin Guide](#zeppelin-guide)
		* [What is Zeppelin](#what-is-zeppelin)
		* [Start MariaDB AX Sandbox - Bookstore Analytics](#start-mariadb-ax-sandbox-bookstore-analytics)
	* [Useful Links](#useful-links)

<!-- /code_chunk_output -->

## Installing prerequisites

### Install Docker

* Install docker following this link:

https://docs.docker.com/engine/installation/

### Install Docker Compose

* Install docker compose following this link:

https://docs.docker.com/compose/install/

### Get the MariaDB AX sandbox

Checkout the images from [GitHub](https://github.com/mariadb-corporation/mariadb-columnstore-docker)

```bash
cd /working_directory
git clone https://github.com/mariadb-corporation/mariadb-columnstore-docker.git
```

### System Requirements

The docker application should run with *minimum 4GB RAM* allocated for those 5 machines to spin and work properly.
The disk space requirement for the docker images is around 4GB.

Make sure you are in columnstore_zeppelin folder

### Build columnstore sandbox
#### Quick start
You can use the following shell script to start the columnstore cluster.
```bash
bash ./sandboxdemo.sh
```

The file executes the following comands:

```bash
cd ./columnstore
docker build -t mariadb/columnstore:1.2 .
cd ../columnstore_zeppelin
echo 'y' | docker network prune &> /dev/null 
echo ''
docker-compose down -v
docker-compose up --build
docker-compose down -v
```
#### Step-by-Step

*Navigate to the columnstore zeppelin directory.*

```bash
cd columnstore_zeppelin
```

*Build the docker image from definitions*

```bash
docker build -t mariadb/columnstore:1.2 ../columnstore
```

*Build Zeppelin instance (optional)*

```bash
docker build -t mariadb/columnstore_zeppelin:latest ../columnstore_zeppelin
```

*Cleanup network settings (optional)*
Removes all unused network configurations. This step is required only if there is a previous network configurations.
```bash
echo 'y' | docker network prune
```

*Remove all existing volumes (optional)*
The following command will remove all disk volumes used by this application.
```bash
docker-compose down -v
```

This command should be used to clean up the volumes before or after restart of the cluster.

#### Start the whole cluster

The command is starting a columnstore cluster with 4 nodes 2UM and 2PM modules:

```bash
docker-compose up --build
```

It can take up to 10 min before the cluster starts and the data is ingested.

The following log entry marks the end of the load.
**`"Container initialization complete at ..."`**

The status of data ingest can be tracked in the UM1 container log file.

```bash
docker logs -f columnstore_zeppelin_um1_1
```

The Bookstore Sandbox Database can be accessed directly with following command:
```bash
mysql -h127.0.0.1 -uzeppelin_user -pzeppelin_pass bookstore
```

The docker volumes created during the process can be released using:
```bash
docker-compose down -v
```
Use this command to start clean when you need to restart theprocess.


### Troubleshooting

In case you run a service on 3306,3307 or 8080 the ports configuration in docker-compose.yml should be changed.
You might encounter the following error 
`ERROR: Encountered errors while bringing up the project.`

i.e. if we have another MariaDB server running on port 3306
The following configuration

```yaml
    ports:
      - "3306:3306"
```

Should be altered like this:

```yaml
    ports:
      - "3308:3306"
```

Assuming 3308 is unbound on our machine.

In case Zeppelin some notebook queries do not work: Increase the memory allocation of the docker engine. The setup  was tested with 4GB RAM but for some operations systems this might be insufficient. 

## Zeppelin Guide

### What is Zeppelin

A open web-based notebook that enables interactive data analytics

Apache Zeppelin brings data ingestion, data exploration, visualization, sharing and collaboration features to Hadoop and Spark.

Zeppelin allows data engineers, data scientist and data analysts be more productive by developing, organizing, executing, and sharing data code and visualizing results without referring to the command line or needing the cluster details.
Notebooks allow these users not only to execute but to interactively work with long workflows.  

We use Zeppelin to allow data scientists to play with the sandbox data stored in MariaDB AX cluster.

### Start MariaDB AX Sandbox - Bookstore Analytics

After the installation is completed you can navigate to [http://localhost:8080/](http://localhost:8080/) and will be presented with the Zeppelin home page

![Img 2](./imgreadme/img2.png)

Press the login button and enter credentials:
![Img 3](./imgreadme/img3.png)

User: ```demo```

Password: ```highlyillogical```

In the lower right section the Notebook section. There you can find **MariaDB AX Sandbox Folder**
Click to open.
Choose **Bookstore Analytics with Scala and Spark**
![Img 4](./imgreadme/img4.png)

When you open the Notebook for the first time you should reload all paragraphs by using the  "Run All Paragraphs" button ![run](./imgreadme/run.jpg)  ...

![Img 5](./imgreadme/img5.png)
after confirmation all scripts will be executed and the results presented.

You are now ready to use Zeppelin with MAriaDB AX Sandbox Data

You can follow this link to get more information about the [Zeppelin user interface](https://zeppelin.apache.org/docs/0.8.0/quickstart/explore_ui.html#note-layout).

You can also follow the tutorial and run the individual paragraphs one by one pressing ![run](./imgreadme/run.jpg) on each paragraph.

Follow the screen instructions.

## Useful Links
[Docker Commands](https://docs.docker.com/engine/reference/commandline/cli/)

[Docker Compose Commands](https://docs.docker.com/compose/reference/overview/)

[Zeppelin UI Guide](https://zeppelin.apache.org/docs/0.8.0/quickstart/explore_ui.html)

[Zeppelin Tutorial](https://zeppelin.apache.org/docs/0.8.0/quickstart/tutorial.html)

[Zeppelin with MariaDB and JDBC](https://zeppelin.apache.org/docs/0.8.0/interpreter/jdbc.html#mariadb)
