{{- define "_neutron_openvswitch" -}}
---
spec:
  template:
    spec:
      initContainers:
        - name: neutron-ovs-agent-init
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "neutron" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          command:
            - bash
            - -cex
            - |
              tee /etc/neutron/local/neutron-ovs-agent-ip.ini <<EOF
              [ovs]
              local_ip = "${POD_IP}"
              EOF
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "neutron" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "neutron" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: neutron-etc-neutron-local
              mountPath: /etc/neutron/local
      containers:
        - name: neutron-ovs-agent
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
              ovs-vsctl --db=unix:${OVS_SOCKET} --no-wait --may-exist add-br br-ex
              exec neutron-openvswitch-agent \
                --config-file=/etc/neutron/neutron.conf \
                --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini \
                --config-file=/etc/neutron/local/neutron-ovs-agent-ip.ini
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
              mountPath: /etc/machine-id
              readOnly: true
            - name: neutron-etc-neutron-local
              mountPath: /etc/neutron/local
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "neutron" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "neutron" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
        - name: neutron-etc-neutron-local
          emptyDir: {}
...
{{- end -}}
