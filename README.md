# 🏥 Sistema PQR — Tododrogas CIA SAS

Sistema centralizado de Peticiones, Quejas y Reclamos para Tododrogas.  
Automatización completa con N8N, IA (GPT-4o), Microsoft Graph API y Supabase.

---

## 📁 Estructura del Repositorio

```
correo-td-pqr/
│
├── .github/
│   └── workflows/
│       └── deploy.yml              ← CI/CD: push a main → deploy automático al VPS
│
├── n8n/
│   ├── flujo_01_recepcion_pqr.json
│   ├── flujo_02_clasificacion_ia.json
│   ├── flujo_03_asignacion_agente.json
│   ├── flujo_04_acuse_ciudadano.json
│   ├── flujo_05_notificacion_agente.json
│   ├── flujo_06_vigilante_sla.json
│   ├── flujo_07_reporte_diario.json
│   ├── flujo_08_canal_canvas.json
│   ├── flujo_09_canal_audio.json
│   ├── flujo_10_confirmacion_universal.json
│   ├── flujo_11_chatbot_ia.json
│   └── flujo_12_generacion_qr.json
│
├── sql/
│   └── 01_supabase_completo.sql    ← Ejecutar 1 sola vez en Supabase SQL Editor
│
├── docs/
│   ├── CREDENCIALES.md             ← Qué secrets configurar y dónde (SIN valores reales)
│   ├── DEPLOY.md                   ← Pasos para desplegar desde cero
│   └── N8N_IMPORTAR.md             ← Cómo importar los 12 flujos en N8N
│
├── public/                         ← Archivos desplegados en /var/www/pqr del VPS
│   ├── index.html                  ← Redirect → pqr_bienvenida.html
│   ├── login.html                  ← Login agentes
│   ├── agente.html                 ← Panel del agente (agente_v8)
│   ├── admin.html                  ← Panel admin PQR (admin_v9)
│   ├── panel_config.html           ← Panel configuración sistema
│   ├── pqr_bienvenida.html         ← Pantalla bienvenida tablet
│   ├── pqr_form.html               ← Formulario PQR
│   ├── chatbot.html                ← Chatbot web embebido
│   └── assets/
│       ├── css/
│       │   └── shared.css          ← Estilos comunes a todas las páginas
│       ├── js/
│       │   └── config.js           ← Variables públicas (generada por CI/CD desde secrets)
│       └── img/
│           └── logo.png            ← Logo Tododrogas
│
├── config.example.js               ← Plantilla de config.js (sin valores reales)
├── .gitignore
└── README.md
```

---

## ⚡ Flujos N8N — Resumen

| # | Flujo | Trigger | Función |
|---|-------|---------|---------|
| 1 | Recepción PQR Web | Webhook POST | Recibe formulario, genera ticket, guarda en Supabase |
| 2 | Clasificación IA | Schedule 2 min | GPT-4o-mini clasifica tipo, prioridad, sentimiento |
| 3 | Auto-asignación | Schedule 3 min | Asigna agente con menos carga |
| 4 | Acuse Ciudadano | Schedule 5 min | Envía email de confirmación con ticket |
| 5 | Notificación Agente | Schedule 5 min | Alerta al agente asignado |
| 6 | Vigilante SLA | Cada hora | Detecta PQR vencidas y en riesgo, escala |
| 7 | Reporte Diario | 7AM L-V | KPIs del día a gerencia |
| 8 | Canal Canvas | Webhook POST | Recibe PNG escrito a mano → Vision API → radica |
| 9 | Canal Audio | Webhook POST | Recibe audio → Whisper → transcribe → radica |
| 10 | Confirmación Universal | Llamado interno | Template de correo centralizado para todos los flujos |
| 11 | Chatbot Web | Webhook POST | Responde preguntas con FAQ + GPT, detecta intención |
| 12 | Generación QR | Webhook POST | Regenera QR y actualiza configuración |

---

## 🗄️ Tablas Supabase

| Tabla | Función |
|-------|---------|
| `correos` | Tabla principal — todas las PQR radicadas |
| `agentes` | Agentes del sistema con carga actual |
| `adjuntos` | Archivos adjuntos de correos |
| `historial_eventos` | Log de eventos por PQR |
| `historial_admin` | Log de acciones del panel admin |
| `chatbot_sesiones` | Conversaciones del chatbot |
| `configuracion_sistema` | Config dinámica: slides, FAQ, QR, SLA, branding |
| `respuestas` | Respuestas enviadas por agentes |
| `chat_mensajes` | Mensajes del chat interno agente-ciudadano |

---

## 🔐 Secrets requeridos en GitHub

Ir a: **Settings → Secrets and variables → Actions**

| Secret | Descripción |
|--------|-------------|
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_KEY` | `anon` key (pública) de Supabase |
| `AZURE_TENANT_ID` | ID del tenant de Azure AD |
| `AZURE_CLIENT_ID` | Client ID de la App en Azure |
| `GRAPH_USER_ID` | Email del buzón: pqrsmirror@tododrogas.com.co |
| `N8N_WEBHOOK_BASE` | https://td-pruebas.online/webhook |
| `VPS_SSH_KEY` | Clave privada SSH para el VPS |

> ⚠️ **NUNCA** agregar `AZURE_CLIENT_SECRET` ni `SUPABASE_SERVICE_KEY` en el frontend.  
> Esas claves solo van en N8N (backend).

---

## 🚀 Deploy

El deploy es automático con cada `git push` a la rama `main`:

```bash
git add .
git commit -m "descripción del cambio"
git push origin main
# → GitHub Actions ejecuta deploy.yml → archivos llegan al VPS
```

Ver `.github/workflows/deploy.yml` para detalles.

---

## 🏗️ Infraestructura

| Servicio | Detalle |
|----------|---------|
| VPS | Hostinger KVM2 · 187.124.71.241 · Ubuntu 24.04 |
| Dominio | td-pruebas.online |
| Supabase | yeiupcumvdvdswfhcoty |
| N8N | Self-hosted en VPS puerto 5678 |
| Correo | pqrsmirror@tododrogas.com.co (Microsoft Graph) |
