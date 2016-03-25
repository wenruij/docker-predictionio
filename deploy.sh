#!/bin/bash -e

USER="wenruijiang"
PROJECT="predictionio"


function build() {
	PIO_VERSION=${1:-0.9.5}
	SPARK_VERSION=${2:-1.6.0-bin-hadoop2.6}
	ES_VERSION=${3:-1.4.4}
	HBASE_VERSION=${4:-1.1.3}

	sed -e "s/PIO_VERSION/$(PIO_VERSION)/g" -e "s/ES_VERSION/$(ES_VERSION)/g" -e "s/SPARK_VERSION/$(SPARK_VERSION)/g" -e "s/HBASE_VERSION/$(HBASE_VERSION)/g" Dockerfile.template > Dockerfile
	sed -e "s/ES_VERSION/$(ES_VERSION)/g" -e "s/SPARK_VERSION/$(SPARK_VERSION)/g" conf/pio-env.sh.template > pio-env.sh
	docker build -t $(USER)/$(PROJECT):$(PIO_VERSION) .
	rm -f Dockerfile pio-env.sh
	docker tag $(USER)/$(PROJECT):$(PIO_VERSION) $(USER)/$(PROJECT):latest
}

function run() {
	docker run --name=$(PROJECT) \
	

}
