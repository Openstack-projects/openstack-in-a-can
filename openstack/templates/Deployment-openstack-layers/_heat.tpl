{{- define "_heat" -}}
---
spec:
  template:
    spec:
      containers:
        - name: heat-api
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "heat" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "heat" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: heat
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file /etc/heat/heat.conf

              function db_sync() {
                heat-manage --config-file=/etc/heat/heat.conf db_sync
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/heat/heat.conf --service identity
              exec uwsgi --ini /etc/heat/heat-api-uwsgi.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "heat" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "heat" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: apache-var-run-uwsgi
              mountPath: /var/run/uwsgi
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
        - name: heat-api-cfn
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "heat" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file /etc/heat/heat.conf
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/heat/heat.conf --service orchestration

              exec uwsgi --ini /etc/heat/heat-api-cfn-uwsgi.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "heat" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "heat" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: apache-var-run-uwsgi
              mountPath: /var/run/uwsgi
        - name: heat-engine
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "heat" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file /etc/heat/heat.conf
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/heat/heat.conf --service orchestration

              exec heat-engine --config-file=/etc/heat/heat.conf
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "heat" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "heat" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "heat" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "heat" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
...
{{- end -}}
