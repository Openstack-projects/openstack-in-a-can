{{- define "_neutron_l3" -}}
---
spec:
  template:
    spec:
      containers:
        - name: neutron-l3-init
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "neutron" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
          command:
            - bash
            - -cex
            - |
              nsenter -t1 -m -u -n -i modprobe ip6_tables
      containers:
        - name: neutron-l3
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "neutron" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
          env:
            - name: OVS_SOCKET
              value: /run/openvswitch/db.sock
          command:
            - bash
            - -cex
            - |
              /run/airship.org/scripts/ovs_check.sh
              exec neutron-l3-agent \
                --config-file=/etc/neutron/neutron.conf \
                --config-file=/etc/neutron/l3_agent.ini
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "neutron" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "neutron" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: host-run-netns
              mountPath: /run/netns
              mountPropagation: Bidirectional
            - name: host-run-openvswitch
              mountPath: /run/openvswitch
            - name: host-etc-machineid
              mountPath: /etc/machineid
              readOnly: true
            - name: pod-var-lib-neutron
              mountPath: /var/lib/neutron
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "neutron" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "neutron" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
...
{{- end -}}
