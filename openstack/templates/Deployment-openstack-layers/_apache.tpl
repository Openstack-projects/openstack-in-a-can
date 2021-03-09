{{- define "_apache" -}}
---
spec:
  template:
    spec:
      containers:
        - name: apache
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "apache" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: APACHE_RUN_DIR
              value: /var/run/apache2
          command:
            - bash
            - -cex
            - |
              a2enmod ssl
              a2enmod proxy
              a2enmod proxy_http
              a2enmod proxy_uwsgi
              a2enmod proxy_wstunnel
              a2enmod rewrite

              rm /etc/apache2/sites-enabled/000-default.conf
              exec apache2 -DFOREGROUND
          ports:
            - name: https
              containerPort: 443
              protocol: TCP
          # livenessProbe:
          #   httpGet:
          #     path: /
          #     port: http
          # readinessProbe:
          #   httpGet:
          #     path: /
          #     port: http
          volumeMounts:
            - name: apache-apache-run
              mountPath: /var/run/apache2
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "apache" ) | nindent 12 }}
            - name: apache-var-run-uwsgi
              mountPath: /var/run/uwsgi
            - name: tls-ca-crt
              mountPath: /usr/share/apache/html/
            - name: tls-crt
              mountPath: /var/run/secrets/airshipit.org/tls/crt/
            - name: tls-key
              mountPath: /var/run/secrets/airshipit.org/tls/key/
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "apache" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
        - name: apache-var-run-uwsgi
          emptyDir: {}
        - name: apache-apache-run
          emptyDir: {}
...
{{- end -}}
