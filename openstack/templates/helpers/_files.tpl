{{- define "helpers.files._object_content_key" -}}
{{- $sourcePath := index . "SourcePath" -}}
{{ printf "%s-%s" (base $sourcePath) (sha256sum $sourcePath) }}
{{- end -}}

{{- define "helpers.files.object_content" -}}
  {{- $Global := index . "Global" -}}
  {{- $source := index . "Source" -}}

  {{ $sourceRoot := printf "files/%s/" $source }}
  {{ $globString := printf "%s%s" $sourceRoot "**" }}

  {{ range $sourcePath, $_ :=  $Global.Files.Glob $globString }}
    {{ $file := trimPrefix $sourceRoot $sourcePath }}
{{ include "helpers.files._object_content_key" ( dict "SourcePath" $sourcePath ) }}: |
{{ $Global.Files.Get $sourcePath | indent 2 }}
  {{ end }}
{{- end -}}


{{- define "helpers.files.container._volumename" -}}
  {{- $Global := index . "Global" -}}
  {{- $container := index . "container" -}}
  {{- $source := index . "Source" -}}

  {{- $objectName := printf "%s-%s" (include "helpers.labels.fullname" $Global) $source -}}

  {{- printf "%s-%s" $objectName ($container | sha1sum) | trunc 63 -}}
{{- end }}

{{- define "helpers.files.container.volumemounts" -}}
  {{- $Global := index . "Global" -}}
  {{- $container := index . "container" -}}
  {{- $source := index . "Source" -}}
  {{- $mountRoot := index . "MountRoot" -}}

  {{- $sourceRoot := printf "files/%s/" $source -}}
  {{- $globString := printf "%s%s" $sourceRoot "**" -}}

  {{- with $Global }}
      {{ range $sourcePath, $_ :=  $Global.Files.Glob $globString }}
        {{ $file := trimPrefix $sourceRoot $sourcePath }}
- name: {{ include "helpers.files.container._volumename" ( dict "Global" $Global "container" $container "Source" $source ) }}
  mountPath: {{ $mountRoot }}/{{ $file }}
  subPath: {{ $file }}
  readOnly: true
      {{ end }}
  {{- end }}
{{- end }}

{{- define "helpers.files.container.volumes" -}}
  {{- $Global := index . "Global" -}}
  {{- $container := index . "container" -}}
  {{- $source := index . "Source" -}}
  {{- $configObjectName := index . "ConfigObjectName" -}}

  {{- $sourceRoot := printf "files/%s/" $source -}}
  {{ $globString := printf "%s%s" $sourceRoot "**" }}

  {{- with $Global -}}
- name: {{ include "helpers.files.container._volumename" ( dict "Global" $Global "container" $container "Source" $source ) }}
  configMap:
    name: {{ $configObjectName }}
    defaultMode: 0555
    items:
      {{ range $sourcePath, $_ :=  .Files.Glob  $globString }}
        {{ $file := trimPrefix $sourceRoot $sourcePath }}
      - key: {{ include "helpers.files._object_content_key" ( dict "SourcePath" $sourcePath ) }}
        path: {{ $file }}
      {{ end }}
  {{- end }}
{{- end -}}