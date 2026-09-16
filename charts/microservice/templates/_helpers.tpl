{{/*
Nombre del release/servicio. Como cada servicio se instala como su propia
Application/release de ArgoCD (release name = nombre del servicio), basta
con usar el nombre del release directamente.
*/}}
{{- define "microservice.name" -}}
{{- .Values.nameOverride | default .Release.Name -}}
{{- end -}}

{{- define "microservice.labels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/part-of: sa-platform
app.kubernetes.io/managed-by: argocd
{{- end -}}

{{- define "microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
{{- end -}}
