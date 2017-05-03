#!/bin/bash

RANCHER_METADATA='http://rancher-metadata.rancher.internal/latest'
ZK_CONFIG='/opt/kafka/config/zookeeper.properties'
ZK_CONFIG_TEMPLATE='/opt/config/zookeeper.properties'
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

LOCAL_ZK_ID=$(curl -s ${RANCHER_METADATA}/self/container/service_index)
LOCAL_ZK_IP=$(curl -s ${RANCHER_METADATA}/self/container/primary_ip)

DELIM=''
ZOOKEEPER_HOSTS=''
for host in "${ZK_HOSTS[@]}"; do
  ZK_ID=$(echo $host | awk -F ':' {'print $1'})
  ZK_IP=$(echo $host | awk -F ':' {'print $2'})
  ZK_PORT=$(echo $host | awk -F ':' {'print $3'})

  # Use local IP if server is loca server
  if [ "${ZK_ID}" -eq "${LOCAL_ZK_ID}" ]; then
    ZK_IP=${LOCAL_ZK_IP}
  fi

  ZOOKEEPER_HOSTS="${ZOOKEEPER_HOSTS}${DELIM}server.${ZK_ID}=${ZK_IP}:2888:3888"
  DELIM="\n"
done

# Set myid
echo ${LOCAL_ZK_ID} > /opt/data/zookeeper/myid

# Copy template
cp ${ZK_CONFIG_TEMPLATE} ${ZK_CONFIG}

# Populate template
sed -i.bak s/\<zookeeper_hosts\>/${ZOOKEEPER_HOSTS}/g ${ZK_CONFIG}

exec /opt/kafka/bin/zookeeper-server-start.sh ${ZK_CONFIG}
