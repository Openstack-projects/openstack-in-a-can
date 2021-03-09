

docker build ./docker/openstack/debian --tag quay.io/port/loci-base:debian-bullseye

docker push quay.io/port/loci-base:debian-bullseye

loci_tmp="$(mktemp -d)"

git clone https://review.opendev.org/openstack/loci ${loci_tmp}
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
sed  -i 's/pip install ${PIP_ARGS} bindep pkginfo/pip install ${PIP_ARGS} bindep==2.8.0 pkginfo/' ${loci_tmp}/scripts/requirements.sh

sed -i "/sed -i '\/python-qpid-proton===0.14.0\/d' \/upper-constraints.txt/a\
sed -i '\/python-nss/d' \/upper-constraints.txt" ${loci_tmp}/scripts/requirements.sh

sed -i "/sed -i '\/python-qpid-proton===0.14.0\/d' \/upper-constraints.txt/a\
sed -i '\/dogtag-pki/d' \/upper-constraints.txt" ${loci_tmp}/scripts/requirements.sh

sed  -i 's/pip_install.sh bindep/pip_install.sh bindep==2.8.0/g' ${loci_tmp}/scripts/install.sh






docker build ${loci_tmp} \
    --build-arg PROJECT=requirements \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg KEEP_ALL_WHEELS="True" \
    --tag quay.io/port/loci-requirements:requirements-victoria

docker push quay.io/port/loci-requirements:requirements-victoria

docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=nova \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg PROFILES="ceph qemu" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-nova:bullseye-victoria

docker push quay.io/port/loci-nova:bullseye-victoria

sed -i '/mysql-client/d' ${loci_tmp}/bindep.txt
docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=placement \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-placement:bullseye-victoria

docker push quay.io/port/loci-placement:bullseye-victoria




docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=glance \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg PROFILES="ceph qemu" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-glance:bullseye-victoria

docker push quay.io/port/loci-glance:bullseye-victoria





docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=heat \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-heat:bullseye-victoria

docker push quay.io/port/loci-heat:bullseye-victoria


docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=cinder \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg PIP_PACKAGES="pymemcache" \
    --build-arg PROFILES="ceph qemu" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-cinder:bullseye-victoria

docker push quay.io/port/loci-cinder:bullseye-victoria


docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=horizon \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg PIP_PACKAGES="heat-dashboard sqlalchemy" \
    --build-arg PROFILES="apache" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-horizon:bullseye-victoria
docker push quay.io/port/loci-horizon:bullseye-victoria

docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=keystone \
    --build-arg PROJECT_REF="stable/victoria" \
    --build-arg PROJECT_RELEASE=victoria \
    --build-arg PYTHON3="yes" \
    --build-arg PIP_PACKAGES="" \
    --build-arg PROFILES="apache" \
    --build-arg WHEELS=quay.io/port/loci-requirements:requirements-victoria \
    --tag quay.io/port/loci-keystone:bullseye-victoria
docker push quay.io/port/loci-keystone:bullseye-victoria

os_release="master"


docker build ${loci_tmp} \
    --build-arg PROJECT=requirements \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT_REF="${os_release}" \
    --build-arg PROJECT_RELEASE="${os_release}" \
    --build-arg PYTHON3="yes" \
    --build-arg KEEP_ALL_WHEELS="True" \
    --tag "quay.io/port/loci-requirements:requirements-${os_release}"

docker push "quay.io/port/loci-requirements:requirements-${os_release}"

docker build ${loci_tmp} \
    --build-arg FROM=quay.io/port/loci-base:debian-bullseye \
    --build-arg PROJECT=neutron \
    --build-arg PROJECT_REF="${os_release}" \
    --build-arg PROJECT_RELEASE="${os_release}" \
    --build-arg PYTHON3="yes" \
    --build-arg PROFILES="openvswitch linuxbridge" \
    --build-arg WHEELS="quay.io/port/loci-requirements:requirements-${os_release}" \
    --tag "quay.io/port/loci-neutron:bullseye-${os_release}"

docker push "quay.io/port/loci-neutron:bullseye-${os_release}"
