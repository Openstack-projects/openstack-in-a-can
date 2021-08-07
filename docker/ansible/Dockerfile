#docker build ./docker/ansible -t quay.io/port/openstack-ansible:latest
#docker push quay.io/port/openstack-ansible:latest
ARG FROM=debian:bullseye-slim
FROM ${FROM} as base-image
LABEL maintainer="pete@port.direct"

SHELL ["bash", "-exc"]
ARG DEBIAN_FRONTEND=noninteractive

# Update distro and install ansible
RUN apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        python3-dev \
        python3-minimal \
        python3-pip ;\
    pip3 install --no-cache-dir --upgrade wheel setuptools ;\
    pip3 install --no-cache-dir --upgrade ansible openstacksdk python-openstackclient python-heatclient openshift ;\
    curl -o /usr/local/bin/kubectl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" ;\
    chmod +x /usr/local/bin/kubectl ;\
    apt-get purge -y \
        gcc \
        python3-dev ;\
    apt-get autoremove -y ;\
    find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete ;\
    apt-get clean -y ;\
    rm -rf \
      /var/cache/debconf/* \
      /var/lib/apt/lists/* \
      /var/log/* \
      /tmp/* \
      /var/tmp/* \
      /root/.cache \
      /etc/machine-id
