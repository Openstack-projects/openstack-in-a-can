{{- define "_cinder" -}}
---
spec:
  template:
    spec:
      containers:
        - name: cinder
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "cinder" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            runAsUser: 42424
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "cinder" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: cinder
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/cinder/cinder.conf

              function db_sync() {
                cinder-manage --config-file=/etc/cinder/cinder.conf db sync
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/cinder/cinder.conf --service identity
              exec uwsgi --procname-prefix cinder-api --ini /etc/cinder/cinder-api-uwsgi.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "cinder" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "cinder" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: apache-var-run-uwsgi
              mountPath: /var/run/uwsgi
            - name: cinder-storage
              mountPath: /var/lib/cinder
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
        - name: cinder-scheduler
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "cinder" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            runAsUser: 42424
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/cinder/cinder.conf
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/cinder/cinder.conf --service volumev3

              exec cinder-scheduler --config-file /etc/cinder/cinder.conf
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "cinder" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "cinder" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: cinder-storage
              mountPath: /var/lib/cinder
        #NOTE - this chart only supports rook as a cinder backend currently
        - name: cinder-volume
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "cinder" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            runAsUser: 42424
            privileged: true
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/cinder/cinder.conf
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/cinder/cinder.conf --service volumev3

              tee /tmp/my-ip.ini <<EOF
              [DEFAULT]
              my_ip = ${POD_IP}
              EOF
              exec cinder-volume --config-file /etc/cinder/cinder.conf --config-file /tmp/my-ip.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "cinder" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "cinder" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: cinder-storage
              mountPath: /var/lib/cinder
            - name: pod-cinder-etc-ceph
              mountPath: /etc/ceph
        - name: cinder-backup
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "cinder" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            runAsUser: 42424
            privileged: true
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          command:
            - bash
            - -cex
            - |
              python /var/run/airship.org/scripts/db_check.py --config-file=/etc/cinder/cinder.conf
              python /var/run/airship.org/scripts/endpoint_check.py --config-file=/etc/cinder/cinder.conf --service volumev3

              tee /tmp/my-ip.ini <<EOF
              [DEFAULT]
              my_ip = ${POD_IP}
              EOF
              exec cinder-backup --config-file /etc/cinder/cinder.conf --config-file /tmp/my-ip.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "cinder" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "cinder" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: cinder-storage
              mountPath: /var/lib/cinder
            - name: pod-cinder-etc-ceph
              mountPath: /etc/ceph
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "cinder" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "cinder" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
        - name: cinder-storage
          emptyDir: {}
        - name: pod-cinder-etc-ceph
          emptyDir: {}
...
{{- end -}}