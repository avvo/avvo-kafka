FROM anapsix/alpine-java:8u121b13_jdk
MAINTAINER Abi X Renhart <arenhart@avvo.com>

ENV KAFKA_VERSION 0.10.2.0
ENV SCALA_VERSION 2.12

RUN apk add --no-cache --update \
    curl \
    bash

RUN curl -o /tmp/kafka.tgz http://mirrors.sonic.net/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    tar -C /opt -xf /tmp/kafka.tgz && \
    ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka && \
    rm -rf /tmp/* /var/cache/apk/*

RUN mkdir -p /opt/data/zookeeper

ADD config /opt/config
ADD entrypoint.sh /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh"]