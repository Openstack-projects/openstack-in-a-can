{{- define "_rabbitmq" -}}
---
spec:
  template:
    spec:
      initContainers:
        - name: rabbitmq-definition-gen
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "keystone" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - python3
            - /var/run/airship.org/scripts/rabbit_definition_generator.py
            - --search-dir
            - /var/run/airshipit.org/rabbitmq/snippets
            - --output
            - /var/run/airshipit.org/rabbitmq/definitions.file.json
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "rabbitmq_init" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "rabbitmq_init" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: rabbitmq-definition
              mountPath: /var/run/airshipit.org/rabbitmq
      containers:
        - name: rabbitmq
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "rabbitmq" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          ports:
            - name: rabbitmq
              containerPort: 5672
              protocol: TCP
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "rabbitmq" ) | nindent 12 }}
            - name: rabbitmq-storage
              mountPath: /var/lib/rabbitmq
            - name: rabbitmq-definition
              mountPath: /var/run/airshipit.org/rabbitmq
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: tls-crt
              mountPath: /var/run/secrets/airshipit.org/tls/crt/
            - name: tls-key
              mountPath: /var/run/secrets/airshipit.org/tls/key/
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "rabbitmq_init" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "rabbitmq_init" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "rabbitmq" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
        #RabbitMQ common
        - name: rabbitmq-definition
          emptyDir: {}
        #RabbitMQ Server
        - name: rabbitmq-storage
          emptyDir: {}
...
{{- end -}}
