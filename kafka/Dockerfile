FROM anapsix/alpine-java:8u121b13_jdk
MAINTAINER Abi X Renhart <arenhart@avvo.com>

RUN apk add --no-cache --update \
    curl \
    bash

RUN curl -O /tmp/kafka.tgz http://mirrors.sonic.net/apache/kafka/0.10.2.0/kafka_2.12-0.10.2.0.tgz && \
    mkdir /opt && \
    tar -C /opt -xf /tmp/kafka.tgz && \
    ln -s /opt/kafka_2.12-0.10.2.0 /opt/kafka

ADD entrypoint.sh /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh"]