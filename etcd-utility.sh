#!/bin/bash

# ETCD backup and restore operations utility script

"
Main Command to take snapshot
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=<trusted-ca-file> --cert=<cert-file> --key=<key-file> snapshot save <backup-file-location>
"
# Variables - insert your variables here
ETCD_SERVER_IP=""
cacert=""
cert=""
key=""
BACKUP_LOCATION=""
ENDPOINT=https://${ETCD_SERVER_IP}:2379

# get cluster name
ETCDCTL_API=3 etcdctl get cluster.name --endpoints=${ENDPOINT} --cacert=${cacert} --cert=${cert} --key=${key} | sed -n 2p

#backup
ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_LOCATION} \
  --endpoints=${ENDPOINT} \
  --cacert=${cacert} \
  --cert=${cert} \
  --key=${key}

# verify the snapshot
ETCDCTL_API=3 etcdctl --write-out=table snapshot status ${BACKUP_LOCATION}

# ----restore---
# stop etcd
sudo systemctl stop etcd

# Delete the existing etcd data:
sudo rm -rf /var/lib/etcd

# restore
sudo ETCDCTL_API=3 etcdctl snapshot restore ${BACKUP_LOCATION} \
--initial-cluster etcd-restore=${ENDPOINT} \
--initial-advertise-peer-urls ${ENDPOINT} \
--name etcd-restore \
--data-dir /var/lib/etcd

# Set ownership on the new data directory:
sudo chown -R etcd:etcd /var/lib/etcd

# Start etcd:
sudo systemctl start etcd

# Verify the restored data is present by looking up the value for the key cluster.name again:
ETCDCTL_API=3 etcdctl get cluster.name --endpoints=${ENDPOINT} --cacert=${cacert} --cert=${cert} --key=${key} | sed -n 2p
