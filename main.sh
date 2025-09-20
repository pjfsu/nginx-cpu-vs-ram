#!/usr/bin/env bash
set -euo pipefail

NETWORK="ab-net"
REQS=5000
CONC=100
RAM_LOG="test-ram.log"
CPU_LOG="test-cpu.log"

echo "[INFO] network create..."
! podman network exists $NETWORK && podman network create $NETWORK

echo "[INFO] kube play ..."
# the network for a pod is fixed at creation time.
! podman pod exists tester && podman kube play --network $NETWORK tester.yaml
for target in low medium high; do
	! podman pod exists $target-ram && podman kube play --network $NETWORK $target-ram.yaml
	! podman pod exists $target-cpu && podman kube play --network $NETWORK $target-cpu.yaml
done

echo "" > $RAM_LOG
echo "" > $CPU_LOG
for target in low medium high; do
	echo "[INFO] testing $target-ram ..."
	podman exec tester-ab ab -n $REQS -c $CONC http://$target-ram:80/ | awk -v target=$target-ram -f parse_ab.awk >> $RAM_LOG
	echo "[INFO] testing $target-cpu ..."
	podman exec tester-ab ab -n $REQS -c $CONC http://$target-cpu:80/ | awk -v target=$target-cpu -f parse_ab.awk >> $CPU_LOG
done

echo "[INFO] kube down ..."
for target in low medium high; do
	podman pod exists $target-ram && podman kube down --force $target-ram.yaml
	podman pod exists $target-cpu && podman kube down --force $target-cpu.yaml
done
podman pod exists tester && podman kube down --force tester.yaml

echo "[INFO] network remove ..."
podman network exists $NETWORK && podman network remove $NETWORK
