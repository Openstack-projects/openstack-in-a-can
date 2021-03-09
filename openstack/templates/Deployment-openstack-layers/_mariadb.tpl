{{- define "_mariadb" -}}
---
spec:
  template:
    spec:
      containers:
        - name: mariadb
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "mariadb" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MYSQL_ROOT_PASSWORD_FILE
              value: "/var/run/secrets/airshipit.org/mysql/mysql-root"
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "mariadb" ) | nindent 12 }}
            - name: openstack-storage
              mountPath: /var/lib/mysql
              subPath: mariadb
            - name: mariadb-socket
              mountPath: /run/mysqld
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "mariadb" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
        - name: mariadb-socket
          emptyDir: {}
...
{{- end -}}
