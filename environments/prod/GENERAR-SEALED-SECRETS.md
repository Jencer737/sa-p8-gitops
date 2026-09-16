# Cómo generar las `SealedSecret` (una vez, en tu compu)

Estas sí puedes ver, compartir y **commitear en el repo público** — es
justamente el punto de Sealed Secrets: quedan cifradas con la llave
pública del controlador que corre en tu clúster; solo ese controlador
puede descifrarlas. Nadie más (ni yo, ni quien vea el repo en GitHub)
puede recuperar el valor original a partir del archivo.

Reutiliza las mismas 8 contraseñas/secretos que ya generaste para
`P7/values-secrets.yaml` (abre ese archivo con `notepad` para copiarlas)
— es la misma base de datos de Neon, no hace falta generar nada nuevo.

## auth-service (necesita JWT_SECRET, AES_SECRET, DATABASE_URL)

```powershell
kubectl create secret generic auth-service-secrets `
  --namespace sa-p8 `
  --from-literal=JWT_SECRET="<tu-auth-service.jwt.secret-de-values-secrets.yaml>" `
  --from-literal=AES_SECRET="<tu-auth-service.aesSecret-de-values-secrets.yaml>" `
  --from-literal=DATABASE_URL="postgresql://svc_auth:<tu-auth-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets --controller-namespace=kube-system `
  > environments/prod/auth-service/sealed-secret.yaml
```

## productos-service (DATABASE_URL)

```powershell
kubectl create secret generic productos-service-secrets `
  --namespace sa-p8 `
  --from-literal=DATABASE_URL="postgresql://svc_productos:<tu-productos-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets --controller-namespace=kube-system `
  > environments/prod/productos-service/sealed-secret.yaml
```

## ordenes-service (DATABASE_URL)

```powershell
kubectl create secret generic ordenes-service-secrets `
  --namespace sa-p8 `
  --from-literal=DATABASE_URL="postgresql://svc_ordenes:<tu-ordenes-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets --controller-namespace=kube-system `
  > environments/prod/ordenes-service/sealed-secret.yaml
```

## pagos-service (DATABASE_URL)

```powershell
kubectl create secret generic pagos-service-secrets `
  --namespace sa-p8 `
  --from-literal=DATABASE_URL="postgresql://svc_pagos:<tu-pagos-service.db.password>@<tu-NEON_HOST>/sa_platform?sslmode=require" `
  --dry-run=client -o yaml | kubeseal --format yaml `
  --controller-name=sealed-secrets --controller-namespace=kube-system `
  > environments/prod/pagos-service/sealed-secret.yaml
```

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
