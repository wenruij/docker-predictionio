#!/bin/bash -e

USER="wenruijiang"
PROJECT="predictionio"

# Prints the usage for this script and exits.
function print_usage() {
cat <<EOF
      Usage:

      Build Docker Image
      	./deploy.sh build [PIO_VERSION] [SPARK_VERSION] [ES_VERSION] [HBASE_VERSION] [FLAG]
      	FLAG: -s        indicates if we deploy PredictionIO based on Spark

      Launch Container
      	./deploy.sh run [SPARK_MASTER] [DRIVER_MEM] [EXECUTOR_MEM] [AKKA_FRAMESIZE] [FLAG]
      	FLAG: -s        indicates if we launch the spark based Contianer

      Examples:
	      Deploy PredictionIO based on Spark
	      	./deploy.sh build 0.9.5 1.6.0-bin-hadoop2.6 1.4.4 1.1.3 -s

	      Using by Default Version
	      	./deploy.sh build -s

	      Run contaienr on AWS:
	        ./deploy.sh run spark://ip-10-0-0-234.ec2.internal:7077 4G 1G 1024 -s

EOF
exit 1
}

while getopts "s:" OPTION
do
    case $OPTION in
        s)
            echo "Deploy PredictionIO on Spark"
            PROJECT="predictionio-spark"
            SPARK=true
            ;;
        *)
            print_usage
            ;;
    esac
done

if [[ $1 == "build" ]]; then
  	shift
  	build
elif [[ $1 == "run" ]]; then
    run
else
	print_usage
fi

function build() {
	PIO_VERSION=${1:-0.9.5}
	PIO_HOME="/opt/PredictionIO-${PIO_VERSION}"
	SPARK_VERSION=${2:-1.6.0-bin-hadoop2.6}
	ES_VERSION=${3:-1.4.4}
	HBASE_VERSION=${4:-1.1.3}

	sed -e "s/PIO_VERSION/$(PIO_VERSION)/g" -e "s/ES_VERSION/$(ES_VERSION)/g" -e "s/SPARK_VERSION/$(SPARK_VERSION)/g" -e "s/HBASE_VERSION/$(HBASE_VERSION)/g" Dockerfile.template > Dockerfile
	sed -e "s/ES_VERSION/$(ES_VERSION)/g" -e "s/SPARK_VERSION/$(SPARK_VERSION)/g" -e "s/HBASE_VERSION/$(HBASE_VERSION)/g" conf/pio-env.sh.template > pio-env.sh
	sed -e "s/PIO_HOME/$(PIO_HOME)/g" -e "s/HBASE_VERSION/$(HBASE_VERSION)/g" conf/hbase-site.xml.template > hbase-site.xml
	if [ -n "$SPARK" ]; then
	    cp entrypoint.sh.spark entrypoint.sh
	    echo "CMD [\"spark://localhost:7077\", \"4G\", \"1G\", \"1024\"]" >> Dockerfile
	else
		cp entrypoint.sh.non.spark entrypoint.sh
	fi
	docker build -t $(USER)/$(PROJECT):$(PIO_VERSION) .
	docker tag $(USER)/$(PROJECT):$(PIO_VERSION) $(USER)/$(PROJECT):latest
	rm -f Dockerfile pio-env.sh hbase-site.xml entrypoint.sh
}

function run() {
	docker run -d --name=$(PROJECT) \
	-v $HOME/PIOEngine:/PIOEngine \
	-p 8000:8000 \
	-p 7070:7070 \
	$(USER)/$(PROJECT):latest $@
}
