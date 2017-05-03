#!/bin/bash

RANCHER_METADATA='http://rancher-metadata.rancher.internal/latest'
KAFKA_CONFIG='/opt/kafka/config/server.properties'
KAFKA_CONFIG_TEMPLATE='/opt/config/server.properties'
ZK_STACK=$(echo $ZK_SERVICE | awk -F '/' {'print $1'})
ZK_SERVICE=$(echo $ZK_SERVICE | awk -F '/' {'print $2'})

get_container_ips() {
  local __RESULTARRAY=$1
  local STACK=$2
  local SERVICE=$3

  CONTAINER_URL="${RANCHER_METADATA}/stacks/${STACK}/services/${SERVICE}/containers"
  for container in `curl -s ${CONTAINER_URL}`; do
    CONTAINER_ID=$(echo $container | awk -F '=' {'print $1'})
    CONTAINER_INDEX=$(curl -s ${CONTAINER_URL}/${CONTAINER_ID}/service_index)
    CONTAINER_HOST_UUID=$(curl -s ${CONTAINER_URL}/${CONTAINER_ID}/host_uuid)

    # Loop through hosts to find host IP
    HOST_URL="${RANCHER_METADATA}/hosts"
    for host in `curl -s ${HOST_URL}`; do
      HOST_ID=$(echo $host | awk -F '=' {'print $1'})
      HOST_UUID=$(curl -s ${HOST_URL}/${HOST_ID}/uuid)

      if [ "${HOST_UUID}" = "${CONTAINER_HOST_UUID}" ]; then
        CONTAINER_IP=$(curl -s ${HOST_URL}/${HOST_ID}/agent_ip)
      fi
    done

    # Using the first port presented by rancher
    # Maybe we need to be explicit here in case the order changes or more ports are added
    CONTAINER_PORT=$(curl -s ${CONTAINER_URL}/${CONTAINER_ID}/ports/0/ | awk -F ':' {'print $2'})
    eval "$__RESULTARRAY+=(${CONTAINER_INDEX}:${CONTAINER_IP}:${CONTAINER_PORT})"
  done
}

ZK_HOSTS=()
get_container_ips ZK_HOSTS $ZK_STACK $ZK_SERVICE

BROKER_ID=$(curl -s ${RANCHER_METADATA}/self/container/service_index)
BROKER_IP=$(curl -s ${RANCHER_METADATA}/self/host/agent_ip)

DELIM=''
ZOOKEEPER_HOSTS=''
for host in "${ZK_HOSTS[@]}"; do
  ZK_ID=$(echo $host | awk -F ':' {'print $1'})
  ZK_IP=$(echo $host | awk -F ':' {'print $2'})
  ZK_PORT=$(echo $host | awk -F ':' {'print $3'})

  ZOOKEEPER_HOSTS="${ZOOKEEPER_HOSTS}${DELIM}${ZK_IP}:${ZK_PORT}"
  DELIM=','
done

# Copy template
cp ${KAFKA_CONFIG_TEMPLATE} ${KAFKA_CONFIG}

# Populate template
sed -i.bak s/\<broker_id\>/${BROKER_ID}/g ${KAFKA_CONFIG}
sed -i.bak s/\<broker_ip\>/${BROKER_IP}/g ${KAFKA_CONFIG}
sed -i.bak s/\<zookeeper_hosts\>/${ZOOKEEPER_HOSTS}/g ${KAFKA_CONFIG}

# Configure JMX
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=${BROKER_IP} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"

exec /opt/kafka/bin/kafka-server-start.sh ${KAFKA_CONFIG}

