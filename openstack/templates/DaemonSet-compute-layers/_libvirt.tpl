{{- define "_libvirt" -}}
---
spec:
  template:
    spec:
      containers:
        - name: libvirt
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "libvirt" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
            runAsUser: 0
          env:
            - name: OVS_SOCKET
              value: /run/openvswitch/db.sock
            - name: SECRET_RBD_CINDER_UUID
              value: "65e7d4b4-00fa-4a50-ba8c-d10120791244"
          command:
            - bash
            - -cex
            - |
              /run/airship.org/scripts/ovs_check.sh
              if [ -n "$(cat /proc/*/comm 2>/dev/null | grep -w libvirtd)" ]; then
                set +x
                for proc in $(ls /proc/*/comm 2>/dev/null); do
                  if [ "x$(cat $proc 2>/dev/null | grep -w libvirtd)" == "xlibvirtd" ]; then
                    set -x
                    libvirtpid=$(echo $proc | cut -f 3 -d '/')
                    echo "WARNING: libvirtd daemon already running on host" 1>&2
                    echo "$(cat "/proc/${libvirtpid}/status" 2>/dev/null | grep State)" 1>&2
                    kill -9 "$libvirtpid" || true
                    set +x
                  fi
                done
                set -x
              fi
              rm -f /var/run/libvirtd.pid

              if [[ -c /dev/kvm ]]; then
                  chmod 660 /dev/kvm
                  chown root:kvm /dev/kvm
              fi

              exec systemd-run --slice system.slice --scope --no-block /usr/sbin/libvirtd --listen
          startupProbe:
            periodSeconds: 10
            failureThreshold: 30
            exec:
              command:
                - bash
                - -cex
                - |
                  virsh secret-define --file /etc/libvirt/secrets/rbd-cinder.xml
                  virsh secret-set-value --secret "${SECRET_RBD_CINDER_UUID}" --file /etc/ceph/raw.cinder.keyring
          livenessProbe:
            failureThreshold: 1
            periodSeconds: 300
            exec:
              command:
                - virsh
                - secret-set-value
                - --secret
                - $(SECRET_RBD_CINDER_UUID)
                - --file
                - /etc/ceph/raw.cinder.keyring
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "libvirt" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "libvirt" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: host-run
              mountPath: /run
            - name: host-dev
              mountPath: /dev
            - name: host-lib-modules
              mountPath: /lib/modules
              readOnly: true
            - name: host-sys-fs-cgroup
              mountPath: /sys/fs/cgroup
            - name: host-etc-machineid
              mountPath: /etc/machineid
              readOnly: true
            - name: host-etc-libvirt-qemu
              mountPath: /etc/libvirt/qemu
            - name: host-var-lib-libvirt
              mountPath: /var/lib/libvirt
            - name: host-var-lib-nova
              mountPath: /var/lib/nova
            - name: pod-etc-ceph
              mountPath: /etc/ceph
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "libvirt" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "libvirt" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
        - name: host-run
          hostPath:
            path: /run
        - name: host-dev
          hostPath:
            path: /dev
        - name: host-lib-modules
          hostPath:
            path: /lib/modules
        - name: host-sys-fs-cgroup
          hostPath:
            path: /sys/fs/cgroup
        - name: host-etc-libvirt-qemu
          hostPath:
            path: /etc/libvirt/qemu
        - name: host-var-lib-libvirt
          hostPath:
            path: /var/lib/libvirt
        - name: host-var-lib-nova
          hostPath:
            path: /var/lib/nova
...
{{- end -}}
