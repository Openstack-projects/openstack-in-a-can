```
sudo tee /etc/sysctl.d/99-inotify-and-memory-maps.conf <<EOF
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 512
vm.max_map_count = 524288
EOF
sudo sysctl --system
```

```
kubectl apply -f - <<EOF
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: cinder
  namespace: rook-ceph
spec:
  failureDomain: osd
  replicated:
    size: 3
---
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: cinder-backups
  namespace: rook-ceph
spec:
  failureDomain: osd
  replicated:
    size: 3
---
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: glance
  namespace: rook-ceph
spec:
  failureDomain: osd
  replicated:
    size: 3
---
apiVersion: ceph.rook.io/v1
kind: CephClient
metadata:
  name: cinder
  namespace: rook-ceph
spec:
  caps:
    mon: 'profile rbd'
    osd: 'profile rbd pool=cinder, profile rbd pool=cinder-backups, profile rbd-read-only pool=images'
---
apiVersion: ceph.rook.io/v1
kind: CephClient
metadata:
  name: glance
  namespace: rook-ceph
spec:
  caps:
    mon: 'profile rbd'
    osd: 'profile rbd pool=glance'
EOF
```

```
helm upgrade --namespace openstack  --create-namespace  --install openstack ./openstack
```

```
rbd -p cinder list | xargs -L1 rbd -p cinder rm
for image in $(rbd -p glance list); do
  snap="$(rbd -p glance snap list ${image} | tail -n +2 | awk '{ print $2 }')"
  if [[ ! -z "$snap" ]]; then
    rbd -p glance snap unprotect --image ${image} --snap ${snap}
    rbd -p glance snap remove --image ${image} --snap ${snap}
  fi
  rbd -p glance remove ${image}
done
```