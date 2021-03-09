{{- define "_keystone" -}}
---
spec:
  template:
    spec:
      containers:
        - name: keystone
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "keystone" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "keystone" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: keystone
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/keystone/keystone.conf

              function db_sync() {
                keystone-manage --config-file=/etc/keystone/keystone.conf db_sync
                keystone-manage --config-file=/etc/keystone/keystone.conf fernet_setup \
                    --keystone-user keystone \
                    --keystone-group keystone
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              set +x
              keystone-manage --config-file=/etc/keystone/keystone.conf bootstrap \
                  --bootstrap-username admin \
                  --bootstrap-password password \
                  --bootstrap-project-name admin \
                  --bootstrap-admin-url https://openstack.cluster.local/identity \
                  --bootstrap-public-url https://openstack.cluster.local/identity \
                  --bootstrap-internal-url https://openstack/identity \
                  --bootstrap-region-id RegionOne
              set -x
              exec apache2 -DFOREGROUND
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "keystone" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "keystone" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: keystone-apache-run
              mountPath: /var/run/apache2
            - name: openstack-storage
              mountPath: /etc/keystone/fernet-keys
              subPath: keystone-fernet-keys
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "keystone" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "keystone" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
        - name: keystone-apache-run
          emptyDir: {}
...
{{- end -}}
