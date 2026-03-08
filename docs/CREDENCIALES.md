# 🔐 Guía de Credenciales y Secrets

> Este documento explica QUÉ configurar y DÓNDE.  
> Nunca contiene valores reales.

---

## 1. GitHub Secrets (para CI/CD)

**Dónde:** Repositorio → Settings → Secrets and variables → Actions → New repository secret

| Secret | Valor | Para qué se usa |
|--------|-------|-----------------|
| `SUPABASE_URL` | `https://yeiupcumvdvdswfhcoty.supabase.co` | config.js en el VPS |
| `SUPABASE_KEY` | `anon` key de Supabase → Settings → API | config.js en el VPS |
| `AZURE_TENANT_ID` | Azure Portal → App Registrations → Overview | config.js en el VPS |
| `AZURE_CLIENT_ID` | Azure Portal → App Registrations → Overview | config.js en el VPS |
| `GRAPH_USER_ID` | `pqrsmirror@tododrogas.com.co` | config.js en el VPS |
| `N8N_WEBHOOK_BASE` | `https://td-pruebas.online/webhook` | config.js en el VPS |
| `VPS_SSH_KEY` | Contenido completo de `~/.ssh/github_actions_key` | SSH al VPS para deploy |

---

## 2. Credenciales N8N (NO van en GitHub)

**Dónde:** N8N → Settings → Credentials → New Credential

### Supabase (HTTP Request con service_role)
```
Tipo: Header Auth
Nombre: Supabase-ServiceKey
Header name: apikey
Header value: [service_role key de Supabase → Settings → API]
```
> ⚠️ Usar service_role SOLO en N8N. Nunca en el frontend.

### Microsoft Graph Token
```
Tipo: HTTP Request — Header Auth  
Nombre: MicrosoftGraph-BearerToken
Header name: Authorization
Header value: Bearer [token — gestionado por Flujo 1 nodo "Obtener Token Microsoft"]
```
O crear credencial OAuth2:
```
Tipo: Microsoft OAuth2 API
Client ID:     [Azure → App Registrations → tu app → Client ID]
Client Secret: [Azure → App Registrations → Certificates & secrets]
Tenant ID:     [Azure → App Registrations → Overview → Directory ID]
Scope:         https://graph.microsoft.com/.default
```

### OpenAI
```
Tipo: OpenAI API
API Key: [platform.openai.com → API Keys → Create new]
Nombre sugerido: OpenAI-PQR-Tododrogas
```

### Admin Webhook Key (para Flujo 12)
```
Tipo: Header Auth — o variable de entorno en N8N
Nombre: AdminWebhookKey
Valor: [generar con: openssl rand -hex 24]
```
Este mismo valor va en el panel admin HTML cuando llama al webhook de generación de QR.

---

## 3. Variables de entorno N8N (docker-compose.yml)

```yaml
environment:
  N8N_HOST:               td-pruebas.online
  WEBHOOK_URL:            https://td-pruebas.online/webhook
  N8N_BASIC_AUTH_ACTIVE:  "true"
  N8N_BASIC_AUTH_USER:    admin
  N8N_BASIC_AUTH_PASSWORD: [contraseña segura mínimo 16 chars]
  GENERIC_TIMEZONE:       America/Bogota
  N8N_ENCRYPTION_KEY:     [openssl rand -hex 32]
```

---

## 4. Generar clave SSH para GitHub Actions

```bash
# En tu PC local:
ssh-keygen -t ed25519 -C "github-actions-pqr" -f ~/.ssh/github_actions_pqr

# Agregar clave pública al VPS:
ssh-copy-id -i ~/.ssh/github_actions_pqr.pub root@187.124.71.241

# Copiar clave PRIVADA al secret VPS_SSH_KEY:
cat ~/.ssh/github_actions_pqr
# Copiar TODO el contenido incluyendo -----BEGIN y -----END-----
```

---

## 5. Checklist de seguridad antes de producción

- [ ] `config.js` está en `.gitignore` ✅
- [ ] `AZURE_CLIENT_SECRET` nunca está en el frontend
- [ ] `SUPABASE_SERVICE_KEY` nunca está en el frontend
- [ ] N8N protegido con usuario/contraseña
- [ ] SSL activo: `https://td-pruebas.online`
- [ ] Rotar `client_secret` en Azure (el anterior puede estar expuesto)
- [ ] RLS habilitado en tablas sensibles de Supabase
- [ ] Rate limiting en Nginx para los webhooks

