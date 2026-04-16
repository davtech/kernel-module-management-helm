{{/*
Common labels - used across all resources
*/}}
{{- define "kmm.labels" -}}
app.kubernetes.io/component: kmm
app.kubernetes.io/name: kmm
app.kubernetes.io/part-of: kmm
{{- end }}

{{/*
Return the proper image name for controller manager
*/}}
{{- define "kernel-module-management.controllerManager.image" -}}
{{- $registry := .Values.controller.image.registry }}
{{- $repository := .Values.controller.image.repository }}
{{- $tag := .Values.controller.image.tag | toString }}
{{- if .Values.global.imageRegistry }}
{{- $registry = .Values.global.imageRegistry }}
{{- end }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Return the proper image name for webhook server
*/}}
{{- define "kernel-module-management.webhook.image" -}}
{{- $registry := .Values.webhook.image.registry }}
{{- $repository := .Values.webhook.image.repository }}
{{- $tag := .Values.webhook.image.tag | toString }}
{{- if .Values.global.imageRegistry }}
{{- $registry = .Values.global.imageRegistry }}
{{- end }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Return the proper image name for worker
*/}}
{{- define "kernel-module-management.worker.image" -}}
{{- $registry := .Values.worker.image.registry }}
{{- $repository := .Values.worker.image.repository }}
{{- $tag := .Values.worker.image.tag | toString }}
{{- if .Values.global.imageRegistry }}
{{- $registry = .Values.global.imageRegistry }}
{{- end }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Return the proper image name for sign
*/}}
{{- define "kernel-module-management.sign.image" -}}
{{- $registry := .Values.sign.image.registry }}
{{- $repository := .Values.sign.image.repository }}
{{- $tag := .Values.sign.image.tag | toString }}
{{- if .Values.global.imageRegistry }}
{{- $registry = .Values.global.imageRegistry }}
{{- end }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Return the proper image name for build (Kaniko)
*/}}
{{- define "kernel-module-management.build.image" -}}
{{- $registry := .Values.build.image.registry }}
{{- $repository := .Values.build.image.repository }}
{{- $tag := .Values.build.image.tag | toString }}
{{- if .Values.global.imageRegistry }}
{{- $registry = .Values.global.imageRegistry }}
{{- end }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Return image pull secrets
*/}}
{{- define "kernel-module-management.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
