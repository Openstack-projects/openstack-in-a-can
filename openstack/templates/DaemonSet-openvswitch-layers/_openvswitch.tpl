{{- define "_openvswitch" -}}
---
spec:
  template:
    spec:
      initContainers:
        - name: openvswitch-vswitchd-init
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "openvswitch" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
          command:
            - bash
            - -cex
            - |
              nsenter -t1 -m -u -n -i modprobe openvswitch
              nsenter -t1 -m -u -n -i modprobe vxlan
      containers:
        - name: openvswitch-ovsdb
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "openvswitch" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
          env:
            - name: OVS_DB
              value: /run/openvswitch/conf.db
            - name: OVS_SCHEMA
              value: /usr/share/openvswitch/vswitch.ovsschema
            - name: OVS_PID
              value: /run/openvswitch/ovsdb-server.pid
            - name: OVS_SOCKET
              value: /run/openvswitch/db.sock
          command:
            - bash
            - -cex
            - |
              mkdir -p "$(dirname ${OVS_DB})"
              if [[ ! -e "${OVS_DB}" ]]; then
                ovsdb-tool create "${OVS_DB}"
              fi

              if [[ "$(ovsdb-tool needs-conversion ${OVS_DB} ${OVS_SCHEMA})" == 'yes' ]]; then
                  ovsdb-tool convert ${OVS_DB} ${OVS_SCHEMA}
              fi

              umask 000
              exec /usr/sbin/ovsdb-server ${OVS_DB} \
                      -vconsole:emer \
                      -vconsole:err \
                      -vconsole:info \
                      --pidfile=${OVS_PID} \
                      --remote=punix:${OVS_SOCKET} \
                      --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                      --private-key=db:Open_vSwitch,SSL,private_key \
                      --certificate=db:Open_vSwitch,SSL,certificate \
                      --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "openvswitch" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "openvswitch" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: host-run-netns
              mountPath: /run/netns
              mountPropagation: Bidirectional
            - name: host-run-openvswitch
              mountPath: /run/openvswitch
            - name: host-etc-machineid
              mountPath: /etc/machine-id
              readOnly: true
        - name: openvswitch-vswitchd
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "openvswitch" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          securityContext:
            privileged: true
          env:
            - name: OVS_SOCKET
              value: /run/openvswitch/db.sock
            - name: OVS_PID
              value: /run/openvswitch/ovs-vswitchd.pid
          command:
            - bash
            - -cex
            - |
              t=0
              while [ ! -e "${OVS_SOCKET}" ] ; do
                  echo "waiting for ovs socket $sock"
                  sleep 1
                  t=$(($t+1))
                  if [ $t -ge 10 ] ; then
                      echo "no ovs socket, giving up"
                      exit 1
                  fi
              done

              ovs-vsctl --db=unix:${OVS_SOCKET} --no-wait show

              exec /usr/sbin/ovs-vswitchd unix:${OVS_SOCKET} \
                      -vconsole:emer \
                      -vconsole:err \
                      -vconsole:info \
                      --pidfile=${OVS_PID} \
                      --mlockall
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "openvswitch" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "openvswitch" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: host-run-netns
              mountPath: /run/netns
              mountPropagation: Bidirectional
            - name: host-run-openvswitch
              mountPath: /run/openvswitch
            - name: host-etc-machineid
              mountPath: /etc/machine-id
              readOnly: true
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "openvswitch" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "openvswitch" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
...
{{- end -}}
