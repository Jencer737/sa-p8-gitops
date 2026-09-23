# Cómo generar las `SealedSecret` (una vez, en tu compu)

> **Nota P9**: cada vez que el clúster se destruye y reconstruye (la
> prueba de DR), el controlador de Sealed Secrets genera una llave nueva
> — SALVO que se restaure la llave respaldada antes de que arranque (ver
> `P9/scripts/restore-sealed-secrets-key.sh`). Si restauraste la llave,
> los `sealed-secret.yaml` ya commiteados siguen siendo válidos tal cual
> y **no hace falta repetir nada de esta guía**. Solo regenera los de
> abajo si es la primera vez, o si decidiste NO restaurar la llave vieja.

Estas sí puedes ver, compartir y **commitear en el repo público** — es
justamente el punto de Sealed Secrets: quedan cifradas con la llave
pública del controlador que corre en tu clúster; solo ese controlador
puede descifrarlas. Nadie más (ni yo, ni quien vea el repo en GitHub)
puede recuperar el valor original a partir del archivo.

Reutiliza las mismas 8 contraseñas/secretos que ya generaste para
`P7/values-secrets.yaml` (abre ese archivo con `notepad` para copiarlas)
— es la misma base de datos de Neon, no hace falta generar nada nuevo.

## ghcr-pull-secret (P9 — reemplaza el kubectl create secret manual de P7/P8)

Necesitas un GitHub PAT con scope `read:packages` (uno nuevo o el mismo
que ya usaste en P7/P8, si sigue vigente — créalo en
https://github.com/settings/tokens).

```powershell
kubectl create secret docker-registry ghcr-pull-secret `
  --namespace sa-p8 `
  --docker-server=ghcr.io `
  --docker-username="<tu-usuario-de-github>" `
  --docker-password="<tu-PAT-con-scope-read:packages>" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/ghcr-pull-secret/secrets/sealed-secret.yaml
```

## auth-service (necesita JWT_SECRET, AES_SECRET, DATABASE_URL)

```powershell
kubectl create secret generic auth-service-secrets `
  --namespace sa-p8 `
  --from-literal=JWT_SECRET="<tu-auth-service.jwt.secret-de-values-secrets.yaml>" `
  --from-literal=AES_SECRET="<tu-auth-service.aesSecret-de-values-secrets.yaml>" `
  --from-literal=DATABASE_URL="postgresql://svc_auth:<tu-auth-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/auth-service/secrets/sealed-secret.yaml
```

## postgres-productos (P9 — credenciales del Postgres en el clúster)

Este ya NO es Neon: desde P9, `productos-service` usa un Postgres propio
dentro del clúster (StatefulSet con la imagen oficial `postgres:16.4`,
ver `environments/prod/postgres-productos/manifests/statefulset.yaml` —
se abandonó el chart de Bitnami porque su registro gratuito de Docker
Hub dejó de publicar tags versionados en 2025, solo `:latest`, que
además viola nuestra propia política `disallow-latest-tag`). Solo hace
falta UNA contraseña (a diferencia de Bitnami, que pedía admin + usuario
por separado) — elige una nueva, no reutilices ninguna de Neon, y
úsala también en el comando de `productos-service` de abajo.

```powershell
kubectl create secret generic postgres-productos-credentials `
  --namespace sa-p8 `
  --from-literal=password="<contraseña-nueva-de-productos>" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/postgres-productos/secrets/sealed-secret.yaml
```

## productos-service (DATABASE_URL — P9, apunta al Postgres del clúster)

```powershell
kubectl create secret generic productos-service-secrets `
  --namespace sa-p8 `
  --from-literal=DATABASE_URL="postgresql://productos:<misma-contraseña-nueva-de-productos>@postgres-productos.sa-p8.svc.cluster.local:5432/productos" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/productos-service/secrets/sealed-secret.yaml
```

## ordenes-service (DATABASE_URL)

```powershell
kubectl create secret generic ordenes-service-secrets `
  --namespace sa-p8 `
  --from-literal=DATABASE_URL="postgresql://svc_ordenes:<tu-ordenes-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/ordenes-service/secrets/sealed-secret.yaml
```

## pagos-service (DATABASE_URL)

```powershell
kubectl create secret generic pagos-service-secrets `
  --namespace sa-p8 `
  --from-literal=DATABASE_URL="postgresql://svc_pagos:<tu-pagos-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/pagos-service/secrets/sealed-secret.yaml
```

## cloud-credentials (P9 — Velero necesita escribir en el bucket de GCS)

Requiere una Service Account de GCP propia, con permiso solo sobre el
bucket de respaldos (no la misma que usa GitHub Actions para GHCR — otra
superficie separada). Créala una vez:

```powershell
gcloud iam service-accounts create sa-p9-velero `
  --project "$env:GCP_PROJECT" `
  --display-name "Velero backups P9"

gcloud storage buckets add-iam-policy-binding "gs://<tu-bucket-de-velero>" `
  --member="serviceAccount:sa-p9-velero@$env:GCP_PROJECT.iam.gserviceaccount.com" `
  --role="roles/storage.objectAdmin"

gcloud iam service-accounts keys create sa-p9-velero-key.json `
  --iam-account="sa-p9-velero@$env:GCP_PROJECT.iam.gserviceaccount.com"
```

Sella esa llave (formato que espera el plugin `velero-plugin-for-gcp`, un
solo campo `cloud`):

```powershell
kubectl create secret generic cloud-credentials `
  --namespace velero `
  --from-file=cloud=sa-p9-velero-key.json `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets-controller --controller-namespace=kube-system `
  > environments/prod/velero/secrets/sealed-secret.yaml
```

**Borra `sa-p9-velero-key.json` de tu disco inmediatamente después** — ya
quedó cifrada dentro del `sealed-secret.yaml`, no necesitas conservar el
archivo plano.

## Notas

- Sustituye cada `<...>` por tu valor real, tecleado directo en tu
  propia terminal (nunca me los mandes a mí).
- `<tu-NEON_HOST>` es el mismo host que ya pusiste en
  `P7/values-p7.yaml` (ej. `ep-young-block-axscnmbq-pooler.c-4.us-east-2.aws.neon.tech`).
- El comando necesita `kubectl` apuntando al clúster real (para que
  `kubeseal` pueda consultar la llave pública del controlador) — no hace
  falta estar loggeado como admin, cualquier acceso de lectura basta.
- Ya verifiqué los nombres de variable contra el código real de `/P4`:
  los 4 servicios leen `process.env.DATABASE_URL` (Node) /
  `os.environ.get("DATABASE_URL")` (Python) como connection string
  completo, y `auth-service` además `JWT_SECRET`/`JWT_EXPIRES_IN`/
  `AES_SECRET` — los comandos de arriba ya usan esos nombres exactos.
- Cada archivo `sealed-secret.yaml` generado ya es seguro de
  **commitear tal cual** en `sa-p8-gitops` — está referenciado
  automáticamente por el chart vía `envFromSealedSecret` en cada
  `values.yaml` de servicio (ya viene configurado).
