{{- define "helpers.config._object_content_key" -}}
{{- $container := index . "Container" -}}
{{- $file := index . "File" -}}
{{ printf "%s-%s" $container $file | sha256sum }}
{{- end -}}

{{- define "helpers.config._object_content_renderer" -}}
    {{- $Global := index . "Global" -}}
    {{- $container := index . "container" -}}
    {{- $file := index . "file" -}}

    {{- $local := dict -}}
    {{- $_ := set $local "templateRaw" ( index $Global.Values.configuration $container $file )  -}}

    {{- with $Global -}}
        {{- if not (kindIs "string" $local.templateRaw)  -}}
            {{- $_ := set $local "template" ( toString ( toPrettyJson ( $local.templateRaw ) ) ) -}}
            {{- $_ := set $local "render" ( toString ( toYaml ( fromJson ( tpl $local.template . ) ) ) ) -}}
        {{- else -}}
            {{- $_ := set $local "template" $local.templateRaw -}}
            {{- $_ := set $local "render" ( tpl $local.template . ) -}}
        {{- end }}
{{- $local.render }}
    {{- end -}}
{{- end -}}

{{- define "helpers.config.object_content" -}}
  {{- $Global := index . "Global" -}}

  {{- $container_list := list -}}

  {{ $sourceRoot := printf "files/%s/" "defaults" }}
  {{ $globString := printf "%s%s" $sourceRoot "**" }}
  {{ range $sourcePath, $_ :=  $Global.Files.Glob $globString }}
    {{ $location := trimPrefix $sourceRoot $sourcePath }}
    {{ $container := (split "/" $location)._0 }}
    {{ $container_list = append $container_list $container }}
  {{ end }}
  {{ range $container, $_ := $Global.Values.configuration }}
    {{ $container_list = uniq (append $container_list $container) }}
  {{ end }}


  {{- $config_dict := dict -}}

  {{ range $_, $container := $container_list }}
    {{ $config_from_files := dict }}
    {{ $sourceRoot := printf "files/%s/%s" "defaults" $container }}
    {{ $globString := printf "%s%s" $sourceRoot "**" }}
    {{ range $sourcePath, $_ :=  $Global.Files.Glob $globString }}
      {{ $file := trimPrefix $sourceRoot $sourcePath }}
      {{ $config_dict = set $config_dict ( include "helpers.config._object_content_key" ( dict "Container" $container "File" $file ) ) (tpl ( $Global.Files.Get $sourcePath ) $Global ) }}
    {{ end }}
    {{ range $file, $_ := index $Global.Values.configuration $container }}
      {{ $config_dict = set $config_dict ( include "helpers.config._object_content_key" ( dict "Container" $container "File" $file ) ) (include "helpers.config._object_content_renderer" (dict "Global" $Global "container" $container "file" $file) ) }}
    {{ end }}
  {{ end }}

  {{ range $key, $value := $config_dict }}
{{ $key }}: {{ $value | b64enc }}
  {{ end }}

{{- end -}}


{{- define "helpers.config.container._volumename" -}}
  {{- $Global := index . "Global" -}}
  {{- $container := index . "container" -}}

  {{- $objectName := printf "%s-%s" (include "helpers.labels.fullname" $Global) "config" -}}

  {{- printf "%s-%s" $objectName ($container | sha1sum) -}}
{{- end }}

{{- define "helpers.config.container.volumemounts" -}}
  {{- $Global := index . "Global" -}}
  {{- $container := index . "container" -}}

  {{- with $Global }}

      {{ $config_list := list }}
      {{ $sourceRoot := printf "files/%s/%s" "defaults" $container }}
      {{ $globString := printf "%s%s" $sourceRoot "**" }}
      {{ range $sourcePath, $_ :=  .Files.Glob $globString }}
        {{ $file := trimPrefix $sourceRoot $sourcePath }}
        {{ $config_list = append $config_list $file }}
      {{ end }}

      {{ range $file, $_ := index $Global.Values.configuration $container }}
        {{ $config_list = uniq (append $config_list $file) }}
      {{ end }}

      {{ range $_, $file := $config_list }}
- name: {{ include "helpers.config.container._volumename" ( dict "Global" $Global "container" $container ) }}
  mountPath: {{ $file }}
  subPath: {{ $file | base }}
  readOnly: true
      {{ end }}
  {{- end }}
{{- end }}

{{- define "helpers.config.container.volumes" -}}
  {{- $Global := index . "Global" -}}
  {{- $container := index . "container" -}}
  {{- $configObjectName := index . "ConfigObjectName" -}}

  {{- with $Global -}}
- name: {{ include "helpers.config.container._volumename" ( dict "Global" $Global "container" $container ) }}
  secret:
    secretName: {{ $configObjectName }}
    defaultMode: 0444
    items:
      {{ $config_list := list }}
      {{ $sourceRoot := printf "files/%s/%s" "defaults" $container }}
      {{ $globString := printf "%s%s" $sourceRoot "**" }}
      {{ range $sourcePath, $_ :=  .Files.Glob $globString }}
        {{ $file := trimPrefix $sourceRoot $sourcePath }}
        {{ $config_list = append $config_list $file }}
      {{ end }}

      {{ range $file, $_ := index $Global.Values.configuration $container }}
        {{ $config_list = uniq (append $config_list $file) }}
      {{ end }}

      {{ range $_, $file := $config_list }}
      - key: {{ include "helpers.config._object_content_key" ( dict "Container" $container "File" $file ) }}
        path: {{ $file | base }}
      {{ end }}


  {{- end -}}
{{- end -}}