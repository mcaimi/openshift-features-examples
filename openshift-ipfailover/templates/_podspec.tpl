{{- define "keepalived.pod" -}}
serviceAccountName: {{ .Values.ipFailover.serviceAccountName }}
privileged: true
hostNetwork: true
{{- with .Values.deployment.placement.selectors }}
nodeSelector:
{{- range . }}
  {{ .key }}: {{ .value | default "" | quote }}
{{- end }}
{{- end }}
{{- with .Values.deployment.placement.tolerations }}
tolerations:
  {{- . | toYaml | nindent 2 }}
{{- end }}
containers:
  - name: {{ .Values.ipFailover.instanceName }}-keepalived
    image: {{ .Values.deployment.containerImage }}
    imagePullPolicy: {{ .Values.deployment.pullPolicy }}
    securityContext:
      privileged: true
    volumeMounts:
      - name: lib-modules
        mountPath: /lib/modules
        readOnly: true
      - name: host-slash
        mountPath: /host
        readOnly: true
        mountPropagation: HostToContainer
      - name: etc-sysconfig
        mountPath: /etc/sysconfig
        readOnly: true
      - name: config-volume
        mountPath: /etc/keepalive
    env:
      - name: OPENSHIFT_HA_REPLICA_COUNT
        value: {{ .Values.deployment.replicas | quote }}
    {{- with .Values.ipFailover.envParams }}
    {{- range . }}
      - name: {{ .name }}
        value: {{ .value }}
    {{- end }}
    {{- end }}
    livenessProbe:
      initialDelaySeconds: 10
      exec:
        command:
        - pgrep
        - keepalived
volumes:
  - name: lib-modules
    hostPath:
      path: /lib/modules
  - name: host-slash
    hostPath:
      path: /
  - name: etc-sysconfig
    hostPath:
      path: /etc/sysconfig
  - name: config-volume
    configMap:
      name: {{ .Values.ipFailover.instanceName }}-checkscript
imagePullSecrets:
  - name: {{ .Values.deployment.imagePullSecret }}
{{- end -}}
