{{- define "_horizon" -}}
---
spec:
  template:
    spec:
      containers:
        - name: horizon
          image: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "horizon" ) }}
          imagePullPolicy: {{ .Values.images.pull.policy | quote }}
          env:
            - name: MY_IMAGE
              value: {{ include "helpers.pod.container.image" ( dict "Global" $ "Application" "horizon" ) }}
            - name: FAST_START
              value: {{ .Values.params.fast_start | toString | lower | quote }}
            - name: FAST_START_SERVICE
              value: horizon
          command:
            - bash
            - -cex
            - |
              export SITE_PACKAGES_ROOT=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

              # FIXME: Will need to wait for Django3.x...
              sed -i "s/query.decode(errors='replace')/errors='replace'/g" ${SITE_PACKAGES_ROOT}/django/db/backends/mysql/operations.py

              rm -f ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/local_settings.py
              ln -s /etc/openstack-dashboard/local_settings ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/local_settings.py

              # wsgi/horizon-http needs open files here, including secret_key_store
              chown -R horizon ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/

              SITE_PACKAGES_ROOT=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
              for PANEL in heat_dashboard neutron_taas_dashboard; do
                PANEL_DIR="${SITE_PACKAGES_ROOT}/${PANEL}/enabled"
                if [ -d ${PANEL_DIR} ];then
                  for panel in `ls -1 ${PANEL_DIR}/_[1-9]*.py`
                  do
                    ln -sv ${panel} ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/enabled/$(basename ${panel})
                  done
                fi
                unset PANEL_DIR
              done

              /var/run/airship.org/scripts/db_check.py --config-file /etc/horizon/horizon-chart-env-check.conf

              function db_sync() {
                /run/airship.org/scripts/horizon_manage.py migrate --noinput

                # If the image has support for it, compile the translations
                if type -p gettext >/dev/null 2>/dev/null; then
                  cd ${SITE_PACKAGES_ROOT}/openstack_dashboard; python /run/airship.org/scripts/horizon_manage.py compilemessages
                fi

                # Compress Horizon's assets.
                /run/airship.org/scripts/horizon_manage.py collectstatic --noinput
                /run/airship.org/scripts/horizon_manage.py compress --force
              }
              export -f db_sync
              /run/airship.org/scripts/fast_start.sh db_sync

              rm -rfv /tmp/_tmp_.secret_key_store.lock /tmp/.secret_key_store
              exec apache2 -DFOREGROUND
          volumeMounts:
{{ include "helpers.config.container.volumemounts" ( dict "Global" $ "container" "horizon" ) | nindent 12 }}
{{ include "helpers.files.container.volumemounts" ( dict "Global" $ "container" "horizon" "Source" "scripts" "MountRoot" "/var/run/airship.org/scripts" ) | nindent 12 }}
            - name: tls-ca-crt
              mountPath: /var/run/secrets/airshipit.org/tls/ca/
            - name: mariadb-socket
              mountPath: /run/mysqld
            - name: horizon-apache-run
              mountPath: /var/run/apache2
            - name: openstack-storage
              mountPath: /var/www/html/horizon
              subPath: horizon
            - name: openstack-storage
              mountPath: /var/run/secrets/airshipit.org/faststart
              subPath: faststart
      volumes:
{{ include "helpers.config.container.volumes" ( dict "Global" $ "container" "horizon" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "config" ) ) | nindent 8 }}
{{ include "helpers.files.container.volumes" ( dict "Global" $ "container" "horizon" "Source" "scripts" "ConfigObjectName" ( printf "%s-%s" ( include "helpers.labels.fullname" $ ) "scripts" ) ) | nindent 8 }}
        - name: horizon-apache-run
          emptyDir: {}
...
{{- end -}}


