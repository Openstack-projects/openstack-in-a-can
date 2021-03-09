{{- define "_placement" -}}
---
spec:
  template:
    spec:
      containers:
        - name: placement
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "placement" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "placement" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: placement
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/placement/placement.conf --db-section placement_database

              function db_sync() {
                placement-manage --config-file=/etc/placement/placement.conf db sync
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/placement/placement.conf --service identity
              exec uwsgi --procname-prefix placement --ini /etc/placement/placement-uwsgi.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "placement" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "placement" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: apache-var-run-uwsgi
              mountPath: /var/run/uwsgi
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "placement" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "placement" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
...
{{- end -}}