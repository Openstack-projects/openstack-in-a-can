{{- define "_ansible" -}}
---
spec:
  template:
    spec:
      containers:
        - name: ansible
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "ansible" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: OS_CLOUD
              value: "openstack_helm"
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          command:
            - bash
            - -cex
            - |
              exec ansible-playbook /run/airship.org/ansible/openstack.yaml
          volumeMounts:
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "ansible" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "ansible" "Source" "ansible" "MountRoot" "/var/run/airship.org/ansible" ) | nindent 12 }}
            - name: pod-glance-etc-ceph
              mountPath: /srv/pod/glance/etc/ceph
            - name: pod-cinder-etc-ceph
              mountPath: /srv/pod/cinder/etc/ceph
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "ansible" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "ansible" "Source" "ansible" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "ansible" ) ) | nindent 8 }}
...
{{- end -}}
