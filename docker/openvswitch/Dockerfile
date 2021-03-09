#docker build ./docker/openvswitch -t quay.io/port/openstack-openvswitch:latest
#docker push quay.io/port/openstack-openvswitch:latest
ARG FROM=debian:bullseye-slim
FROM ${FROM}
LABEL maintainer="pete@port.direct"

SHELL ["bash", "-exc"]
ARG DEBIAN_FRONTEND=noninteractive

RUN set -ex; \
    apt-get update ;\
    apt-get install -y openvswitch-switch ;\
    apt-get clean -y ;\
    rm -rf \
      /var/cache/debconf/* \
      /var/lib/apt/lists/* \
      /var/log/* \
      /tmp/* \
      /var/tmp/* \
      /root/.cache \
      /etc/machine-id