{{- define "_neutron" -}}
---
spec:
  template:
    spec:
      containers:
        - name: neutron-server
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "neutron" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "neutron" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: neutron
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/neutron/neutron.conf

              function db_sync() {
                neutron-db-manage upgrade heads
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/neutron/neutron.conf --service identity
              exec neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "neutron" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "neutron" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "neutron" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "neutron" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
...
{{- end -}}