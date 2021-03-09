{{- define "_nova" -}}
---
spec:
  template:
    spec:
      containers:
        - name: nova-api-os-compute
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: nova
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section api_database
              #python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section cell0_database <<-gap to fix

              function db_sync() {
                nova-manage --config-file=/etc/nova/nova.conf api_db sync
                nova-manage --config-file=/etc/nova/nova.conf cell_v2 map_cell0 --database_connection="mysql+pymysql://nova-user:nova-password@/nova_cell0?unix_socket=/run/mysqld/mysqld.sock"
                nova-manage --config-file=/etc/nova/nova_cell1.conf db sync --local_cell
                nova-manage --config-file=/etc/nova/nova.conf db sync
                nova-manage --config-file=/etc/nova/nova.conf db online_data_migrations
                nova-manage --config-file=/etc/nova/nova.conf --config-file=/etc/nova/nova_cell1.conf cell_v2 create_cell --name="cell1" || true
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service placement
              exec uwsgi --procname-prefix nova-api --ini /etc/nova/nova-api-uwsgi.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: apache-var-run-uwsgi
              mountPath: /var/run/uwsgi
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
        - name: nova-conductor
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section api_database
              #python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section cell0_database <<-gap to fix
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service placement
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service compute

              exec nova-conductor --config-file=/etc/nova/nova.conf
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
        - name: nova-scheduler
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section api_database
              #python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section cell0_database <<-gap to fix
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service placement
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service compute


              exec nova-scheduler --config-file=/etc/nova/nova.conf
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
        - name: nova-metadata
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          ports:
            - name: n-meta
              containerPort: 8775
              protocol: TCP
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section api_database
              #python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section cell0_database <<-gap to fix
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service placement
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service compute


              exec uwsgi --procname-prefix nova-api-meta --ini /etc/nova/nova-metadata-uwsgi.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
        - name: nova-novnc
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "nova" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section api_database
              #python /var/run/airship.org/scripts/db_check.py --config-file=/etc/nova/nova.conf --db-section cell0_database <<-gap to fix
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service placement
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/nova/nova.conf --service compute


              exec nova-novncproxy --config-file /etc/nova/nova.conf --web /usr/share/novnc
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "nova" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "nova" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "nova" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "nova" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
...
{{- end -}}