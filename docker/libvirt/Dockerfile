#docker build ./docker/libvirt -t quay.io/port/openstack-libvirt:latest
#docker push quay.io/port/openstack-libvirt:latest
ARG FROM=debian:bullseye-slim
FROM ${FROM} as base-image
LABEL maintainer="pete@port.direct"

SHELL ["bash", "-exc"]
ARG DEBIAN_FRONTEND=noninteractive

ARG PROJECT=nova
ARG UID=42424
ARG GID=42424

RUN set -ex ;\
    apt-get update ;\
    apt-get install --no-install-recommends -y \
      ca-certificates \
      ceph-common \
      qemu-block-extra \
      dmidecode \
      ebtables \
      iproute2 \
      qemu-system \
      libvirt-clients \
      libvirt-daemon-system \
      openvswitch-switch \
      kmod ;\
    groupadd -g ${GID} ${PROJECT} ;\
    useradd -u ${UID} -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /usr/sbin/nologin -c "${PROJECT} user" ${PROJECT} ;\
    mkdir -p /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT} ;\
    chown ${PROJECT}:${PROJECT} /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT} ;\
    usermod -a -G kvm ${PROJECT} ;\
    apt-get clean -y ;\
    rm -rf \
      /var/cache/debconf/* \
      /var/lib/apt/lists/* \
      /var/log/* \
      /tmp/* \
      /var/tmp/* \
      /root/.cache \
      /etc/machine-id
