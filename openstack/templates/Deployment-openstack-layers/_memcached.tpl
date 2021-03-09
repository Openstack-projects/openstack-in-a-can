{{- define "_memcached" -}}
---
spec:
  template:
    spec:
      containers:
        - name: memcached
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "memcached" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          command:
            - /usr/local/bin/memcached
            - -vv
            - --listen=0.0.0.0
            - --port=11211
            - --memory-limit=128
          ports:
            - name: memcache
              containerPort: 11211
              protocol: TCP
...
{{- end -}}
