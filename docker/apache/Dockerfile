#docker build ./docker/apache -t quay.io/port/openstack-apache:latest
#docker push quay.io/port/openstack-apache:latest
ARG FROM=debian:bullseye-slim
FROM ${FROM} as base-image
LABEL maintainer="pete@port.direct"

SHELL ["bash", "-exc"]
ARG DEBIAN_FRONTEND=noninteractive

# Update distro and install ansible
RUN apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y --no-install-recommends \
        apache2 \
        uwsgi \
        uwsgi-plugin-python3 \
        libapache2-mod-proxy-uwsgi ;\
    apt-get clean -y ;\
    rm -rf \
      /var/cache/debconf/* \
      /var/lib/apt/lists/* \
      /var/log/* \
      /tmp/* \
      /var/tmp/* \
      /root/.cache \
      /etc/machine-id
