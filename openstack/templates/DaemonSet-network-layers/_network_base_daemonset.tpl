{{- define "_network_base_daemonset" -}}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ template "helpers.labels.fullname" . }}-network
  labels: {{- include "helpers.labels.labels" . | nindent 4 }}
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ''
spec:
  selector:
    matchLabels: {{- include "helpers.labels.matchLabels" . | nindent 6 }}
  template:
    metadata:
      labels: {{- include "helpers.labels.labels" . | nindent 8 }}
      annotations:
        checksum/secret-config: {{ include "helpers.template.hash" ( dict "Global" $ "TemplateName" "Secret-config.yaml" ) }}
        checksum/scripts: {{ include "helpers.template.hash" ( dict "Global" $ "TemplateName" "ConfigMap-scripts.yaml" ) }}
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      hostPID: true
      hostIPC: true
      nodeSelector:
{{ include "helpers.pod.node_selector" ( dict "Global" $ "Application" "openstack" ) | nindent 8 }}
      initContainers: null
      containers: null
      volumes:
        - name: host-etc-machineid
          hostPath:
            path: /etc/machine-id
            type: File
        - name: tls-ca-crt
          secret:
            secretName: {{ template "helpers.labels.fullname" . }}-tls
            items:
              - key: ca.crt
                path: ca.crt
        - name: host-run-netns
          hostPath:
            path: /run/netns
        - name: host-run-openvswitch
          hostPath:
            path: /run/openvswitch
        - name: pod-var-lib-neutron
          emptyDir: {}
...
{{- end -}}