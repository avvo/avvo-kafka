# Avvo Kafka

This repo contains docker files that help us build Kafka and Zookeeper images that
mirror what we have in our production/test Cloudera clusters

These versions are built modified from Wurstmeister ([Kafka](https://github.com/wurstmeister/kafka-docker), [Zookeeper](https://github.com/wurstmeister/zookeeper-docker)). We have modified them to lock to the versions we need
because the tags on docker hub do not contain the versions we need.

## Current Versions

Kafka: 0.10.2.0
Zookeeper: 3.3.6 (3.3.5 is used in Cloudera but there is no current download available for it)

## Running

You can use the provided `docker-compose.yml` file to run zookeeper and kafka locally
