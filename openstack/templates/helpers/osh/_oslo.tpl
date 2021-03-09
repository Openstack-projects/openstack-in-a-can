{{- define "helpers.osh.oslo.convert" -}}
{{- range $section, $values := . -}}
{{- if kindIs "map" $values -}}
[{{ $section }}]
{{ range $key, $value := $values -}}
{{- if kindIs "slice" $value -}}
{{ $key }} = {{ include "helm-toolkit.utils.joinListWithComma" $value }}
{{ else if kindIs "map" $value -}}
{{- if eq $value.type "multistring" }}
{{- range $k, $multistringValue := $value.values -}}
{{ $key }} = {{ $multistringValue }}
{{ end -}}
{{ else if eq $value.type "csv" -}}
{{ $key }} = {{ include "helm-toolkit.utils.joinListWithComma" $value.values }}
{{ end -}}
{{- else -}}
{{ $key }} = {{ $value }}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}