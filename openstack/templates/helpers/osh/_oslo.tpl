{{- define "helpers.osh.oslo._joinListWithComma" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}},{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}

{{- define "helpers.osh.oslo.convert" -}}
{{- range $section, $values := . -}}
{{- if kindIs "map" $values -}}
[{{ $section }}]
{{ range $key, $value := $values -}}
{{- if kindIs "slice" $value -}}
{{ $key }} = {{ include "helpers.osh.oslo._joinListWithComma" $value }}
{{ else if kindIs "map" $value -}}
{{- if eq $value.type "multistring" }}
{{- range $k, $multistringValue := $value.values -}}
{{ $key }} = {{ $multistringValue }}
{{ end -}}
{{ else if eq $value.type "csv" -}}
{{ $key }} = {{ include "helpers.osh.oslo._joinListWithComma" $value.values }}
{{ end -}}
{{- else -}}
{{ $key }} = {{ $value }}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "helpers.osh.oslo.overlay" -}}
{{- $Global := index . "Global" -}}
{{- $currentConfig := index . "currentConfig" -}}
{{- $currentComponent := mustFirst (mustRegexSplit ":" $currentConfig -1) -}}
{{- $currentPath := mustLast (mustRegexSplit ":" $currentConfig -1) -}}
{{- $outputConfigKey := printf "_config_%s" $currentConfig -}}
{{- $_ := set $Global.Values $outputConfigKey dict -}}
{{- include "helpers.template.merge" ( dict "merge_same_named" true "values" ( tuple (index $Global.Values $outputConfigKey ) ( include $currentConfig $Global | toString | fromYaml ) (index $Global.Values.params.config $currentComponent $currentPath) ) ) -}}
{{- tpl (include "helpers.osh.oslo.convert" (index $Global.Values $outputConfigKey )) $Global -}}
{{- end -}}