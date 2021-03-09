{{- define "_glance" -}}
---
spec:
  template:
    spec:
      containers:
        - name: glance
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "glance" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            runAsUser: 42424
            privileged: true
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "glance" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: glance
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/glance/glance-api.conf

              function db_sync() {
                glance-manage --config-file=/etc/glance/glance-api.conf db_sync
                glance-manage --config-file=/etc/glance/glance-api.conf db_load_metadefs
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/glance/glance-api.conf --service identity
              exec glance-api --config-dir=/etc/glance
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "glance" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "glance" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: glance-storage
              mountPath: /var/lib/glance
            - name: pod-glance-etc-ceph
              mountPath: /etc/ceph
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "glance" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "glance" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
        - name: glance-storage
          emptyDir: {}
        - name: pod-glance-etc-ceph
          emptyDir: {}
...
{{- end -}}