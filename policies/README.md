# P8/policies — Kyverno

4 `ClusterPolicy`: las 3 obligatorias del PDF (`disallow-latest-tag`,
`require-resource-limits`, `require-non-root`) más la verificación de
firma de Cosign (`verify-cosign-signature`), que sustenta el requisito
"verificación de la firma antes del despliegue".

## Aplicarlas al clúster

```powershell
kubectl apply -f P8/policies/disallow-latest-tag.yaml
kubectl apply -f P8/policies/require-resource-limits.yaml
kubectl apply -f P8/policies/require-non-root.yaml
kubectl apply -f P8/policies/verify-cosign-signature.yaml
```

Verifica que quedaron activas:

```powershell
kubectl get clusterpolicy
```

Deben aparecer las 4, con `READY: true`.

> **Orden recomendado**: aplica las 3 primeras desde el principio (no
> dependen de nada más). La de Cosign (`verify-cosign-signature`)
> aplícala **después** de que ya tengas al menos una imagen firmada y
> verificada en GHCR (paso "Firmar la imagen" del workflow) — si la
> aplicas antes, cualquier despliegue de prueba con una imagen sin
> firmar quedará rechazado (que es exactamente lo que se demuestra en el
> entregable "Despliegue rechazado por política", ver abajo).

## Generar la evidencia obligatoria: "despliegue rechazado por política"

El PDF pide evidencia de un rechazo real. La forma más simple de
provocarlo a propósito, sin afectar nada de lo que ya está desplegado:

```powershell
kubectl run test-latest --image=nginx:latest -n sa-p8 --dry-run=client -o yaml | kubectl apply -f -
```

Debe salir un error explícito de Kyverno rechazando el pod por usar
`:latest` (política `disallow-latest-tag`). Captura esa pantalla — es la
evidencia que va en la tabla de enlaces del README de P8 (ítem
"Despliegue rechazado por política").

Limpieza (por si el intento anterior sí llegó a crear algo, no debería):

```powershell
kubectl delete pod test-latest -n sa-p8 --ignore-not-found
```
