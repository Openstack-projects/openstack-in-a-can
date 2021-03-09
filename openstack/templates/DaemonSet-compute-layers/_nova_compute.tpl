{{- define "_nova_compute" -}}
---
spec:
  template:
    spec:
      initContainers:
        - name: nova-init
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            runAsUser: 0
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          command:
            - bash
            - -cex
            - |
              mkdir -p /var/lib/nova/instances
              # Set Ownership of nova dirs to the nova user
              chown 42424 /var/lib/nova /var/lib/nova/instances
              tee /etc/nova/local/nova-compute-ip.ini <<EOF
              [DEFAULT]
              my_ip = ${POD_IP}
              [vnc]
              server_proxyclient_address = ${POD_IP}
              server_listen = ${POD_IP}
              EOF
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: host-var-lib-nova
              mountPath: /var/lib/nova
            - name: nova-etc-nova-local
              mountPath: /etc/nova/local
      containers:
        - name: nova
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
            runAsUser: 42424
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/libvirt_check.py
              exec nova-compute --config-file /etc/nova/nova-cpu.conf --config-file=/etc/nova/local/nova-compute-ip.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
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
            - name: nova-etc-nova-local
              mountPath: /etc/nova/local
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "nova" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "nova" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
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
        - name: nova-etc-nova-local
          emptyDir: {}
...
{{- end -}}
