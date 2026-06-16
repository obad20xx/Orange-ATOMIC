{{/*
FIX 7: _helpers.tpl — shared template helpers for naming and labeling.
Replaces duplicated {{ .Values.global.releaseName }}-* expressions across templates.
*/}}

{{/*
Release name — uses global.releaseName if set, falls back to Helm .Release.Name.
*/}}
{{- define "tasky.releaseName" -}}
{{- .Values.global.releaseName | default .Release.Name }}
{{- end }}

{{/*
Common Helm-recommended labels applied to all resources.
*/}}
{{- define "tasky.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Backend selector label — used by Deployment selector and Service selector.
*/}}
{{- define "tasky.backend.selectorLabels" -}}
app: {{ include "tasky.releaseName" . }}-backend
{{- end }}

{{/*
Frontend selector label — used by Deployment selector and Service selector.
*/}}
{{- define "tasky.frontend.selectorLabels" -}}
app: {{ include "tasky.releaseName" . }}-frontend
{{- end }}
