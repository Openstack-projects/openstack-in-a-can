{{- define "_base_deployment" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "helpers.labels.fullname" . }}
  labels: {{- include "helpers.labels.labels" . | nindent 4 }}
spec:
  replicas: 1
  minReadySeconds: 30
  strategy:
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels: {{- include "helpers.labels.matchLabels" . | nindent 6 }}
  template:
    metadata:
      labels: {{- include "helpers.labels.labels" . | nindent 8 }}
      annotations:
        checksum/secret-config: {{ include "helpers.template.hash" ( dict "Global" $ "TemplateName" "Secret-config.yaml" ) }}
        checksum/scripts: {{ include "helpers.template.hash" ( dict "Global" $ "TemplateName" "ConfigMap-scripts.yaml" ) }}
        checksum/ansible: {{ include "helpers.template.hash" ( dict "Global" $ "TemplateName" "ConfigMap-ansible.yaml" ) }}
    spec:
      serviceAccountName: {{ template "helpers.labels.fullname" . }}-openstack
      hostAliases:
        - ip: "127.0.0.1"
          hostnames:
            - "{{ .Values.params.endpoints.hostname }}"
            - "{{ template "helpers.labels.fullname" . }}"
            - "{{ template "helpers.labels.fullname" . }}.{{ .Release.Namespace }}"
            - "{{ template "helpers.labels.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.params.cluster.domain }}"
      nodeSelector:
{{ include "helpers.pod.node_selector" ( dict "Global" $ "Application" "openstack" ) | nindent 8 }}
      initContainers: null
      containers: null
      volumes:
        - name: tls-ca-crt
          secret:
            secretName: {{ template "helpers.labels.fullname" . }}-tls
            items:
              - key: ca.crt
                path: ca.crt
        - name: tls-crt
          secret:
            secretName: {{ template "helpers.labels.fullname" . }}-tls
            items:
              - key: tls.crt
                path: tls.crt
        - name: tls-key
          secret:
            secretName: {{ template "helpers.labels.fullname" . }}-tls
            items:
              - key: tls.key
                path: tls.key
        - name: openstack-storage
          {{ if .Values.params.storage.openstack.enabled }}
          persistentVolumeClaim:
            claimName: {{ printf "%s-%s" ( include "helpers.labels.fullname" $ ) "openstack" }}
          {{ else }}
          emptyDir: {}
          {{ end }}

...
{{- end -}}