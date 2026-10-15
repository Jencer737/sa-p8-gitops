# sa-p8-gitops: rama `p10`

Repositorio GitOps de la plataforma (P8 → P9 → P10). ArgoCD aplica al clúster **solo** lo que está aquí.

| Rama | Práctica | Clúster / Application raíz |
|---|---|---|
| `main` | P8 y P9 (entregadas; se conserva tal cual) | `sa-p9` / `sa-p9-root` |
| **`p10`** | P10: observabilidad y canary gobernado por métricas | `sa-p10` / `sa-p10-root` |

## Qué agrega la rama `p10`

| Ruta | Contenido |
|---|---|
| `app-of-apps/children/kube-prometheus-stack.yaml` | Prometheus, Alertmanager (rutas page/ticket) y Grafana (fuentes Loki y Tempo enlazadas por `trace_id`). Sin las reglas por umbral del chart. |
| `app-of-apps/children/loki.yaml`, `tempo.yaml` | Almacén de registros (SingleBinary) y backend de trazas |
| `app-of-apps/children/otel-collector.yaml` | Collector *gateway*: recibe OTLP de los servicios; trazas → Tempo, métricas → `:8889` para Prometheus |
| `app-of-apps/children/otel-agent.yaml` | Collector *agente* (DaemonSet): registros JSON de `/var/log/pods/sa-p8_*` → Loki |
| `app-of-apps/children/observabilidad-config.yaml` → `observability/` | **PrometheusRule `sa-slo`** (SLO, presupuesto, alertas por consumo), ServiceMonitor del collector, ConfigMap del tablero |
| `app-of-apps/children/generador-trafico.yaml` → `carga/` | Tráfico continuo (k6) contra el api-gateway |
| `charts/microservice/templates/analysistemplate.yaml` | **AnalysisTemplate por métricas** (`<servicio>-analisis-metricas`): tasa de error y p95 de la versión candidata, consultados en Prometheus. Reemplaza al Job de smoke test de P8. |
| `charts/microservice/templates/rollout.yaml` | Inyecta la configuración de OpenTelemetry y el hash de Argo Rollouts (`rollout.pod_template_hash`) que separa canary de estable |
| `environments/prod/*/values.yaml` | Imágenes `p10-v*`, límites de memoria para el SDK y umbral de p95 = 0.3 s en productos (igual al SLO) |

Todas las `Application` que leen este repo apuntan a `targetRevision: p10`.

El código, la documentación y las evidencias de P10 están en [`Practicas-SA-B-202002141/P10`](https://github.com/Jencer737/Practicas-SA-B-202002141/tree/main/P10). `observability/dashboard-tienda-operacion.yaml` y `carga/configmap-script.yaml` se generan desde ese repo con `P10/scripts/sincronizar-gitops.sh`: no se editan a mano.
