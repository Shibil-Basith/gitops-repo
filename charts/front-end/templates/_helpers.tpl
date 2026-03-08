{{/*
Expand the name of the chart.
*/}}
{{- define "front-end.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "front-end.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "front-end.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{ include "front-end.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: sock-shop
{{- end }}

{{/*
Selector labels
*/}}
{{- define "front-end.selectorLabels" -}}
app.kubernetes.io/name: {{ include "front-end.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
name: {{ include "front-end.name" . }}
{{- end }}
