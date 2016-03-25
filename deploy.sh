#!/bin/bash -e

USER="wenruijiang"
PROJECT="predictionio"

# Prints the usage for this script and exits.
function print_usage() {
cat <<EOF
      Usage:

      Build Docker Image
      	./deploy.sh [FLAG] build [PIO_VERSION] [SPARK_VERSION] [ES_VERSION] [HBASE_VERSION]
      	FLAG: -s        indicates if we deploy PredictionIO based on Spark

      Launch Container
      	./deploy.sh [FLAG] run [SPARK_MASTER] [DRIVER_MEM] [EXECUTOR_MEM] [AKKA_FRAMESIZE]
      	FLAG: -s        indicates if we launch the spark based Contianer

      Examples:
	      Deploy PredictionIO based on Spark
	      	./deploy.sh -s build 0.9.5 1.6.0-bin-hadoop2.6 1.4.4 1.1.3

	      Using by Default Version
	      	./deploy.sh -s build

	      Run contaienr on AWS:
	        ./deploy.sh -s run --spark-master spark://ip-10-0-0-234.ec2.internal:7077 --driver-mem 4G --executor-mem 1G --akka-framsize 1024

EOF
exit 1
}

while getopts "s" OPTION
do
    case $OPTION in
        s)
            echo "A PredictionIO Engine based on Spark ..."
            PROJECT="predictionio-spark"
            SPARK=true
            shift
            ;;
        *)
            print_usage
            ;;
    esac
done

function build() {
	PIO_VERSION=${1:-0.9.5}
	PIO_HOME="\/opt\/PredictionIO-${PIO_VERSION}"
	SPARK_VERSION=${2:-1.6.0-bin-hadoop2.6}
	ES_VERSION=${3:-1.4.4}
	HBASE_VERSION=${4:-1.1.3}

	sed -e "s/PIO_VERSION/${PIO_VERSION}/g" -e "s/ES_VERSION/${ES_VERSION}/g" -e "s/SPARK_VERSION/${SPARK_VERSION}/g" -e "s/HBASE_VERSION/${HBASE_VERSION}/g" Dockerfile.template > Dockerfile
	sed -e "s/PIO_HOME/${PIO_HOME}/g" -e "s/HBASE_VERSION/${HBASE_VERSION}/g" conf/hbase-site.xml.template > hbase-site.xml
	sed -e "s/ES_VERSION/${ES_VERSION}/g" -e "s/SPARK_VERSION/${SPARK_VERSION}/g" -e "s/HBASE_VERSION/${HBASE_VERSION}/g" conf/pio-env.sh.template > pio-env.sh
	if [ -n "$SPARK" ]; then
	    cp entrypoint.sh.spark entrypoint.sh
	    echo "CMD [\"--spark-master\", \"spark://localhost:7077\", \"--driver-mem\", \"4G\", \"--executor-mem\", \"1G\", \"--akka-framsize\", \"1024\"]" >> Dockerfile
	else
		cp entrypoint.sh.non.spark entrypoint.sh
	fi
	docker build -t ${USER}/${PROJECT}:${PIO_VERSION} .
	docker tag ${USER}/${PROJECT}:${PIO_VERSION} ${USER}/${PROJECT}:latest
	rm -f Dockerfile pio-env.sh hbase-site.xml entrypoint.sh
}

function run() {
	docker run -d --name=${PROJECT} \
	-v $HOME/PIOEngine:/PIOEngine \
	-p 8000:8000 \
	-p 7070:7070 \
	${USER}/${PROJECT}:latest $@
}

if [[ $1 == "build" ]]; then
  	shift
  	build $@
elif [[ $1 == "run" ]]; then
	shift
    run $@
else
	print_usage
fi
