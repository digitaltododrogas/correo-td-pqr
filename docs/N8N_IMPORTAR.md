# 📥 Cómo importar los 12 flujos en N8N

## Prerequisito: Crear las credenciales primero

Antes de importar cualquier flujo, crea las credenciales en:  
**N8N → Settings → Credentials**

Ver `docs/CREDENCIALES.md` para los valores exactos.

Credenciales necesarias:
1. `Supabase-ServiceKey` (Header Auth)
2. `MicrosoftGraph-OAuth2` o token manual
3. `OpenAI-PQR-Tododrogas` (OpenAI API)
4. `AdminWebhookKey` (Header Auth)

---

## Orden de importación (IMPORTANTE — respetar el orden)

Importar en este orden porque los flujos se llaman entre sí:

```
10 → Confirmación Universal    (base, llamado por otros)
 1 → Recepción PQR Web         (base, llamado por canales)
 2 → Clasificación IA
 3 → Auto-asignación Agente
 4 → Acuse Ciudadano
 5 → Notificación Agente
 6 → Vigilante SLA
 7 → Reporte Diario
 8 → Canal Canvas              (llama al Flujo 1)
 9 → Canal Audio               (llama al Flujo 1)
11 → Chatbot Web
12 → Generación QR
```
El Flujo 8 ya existe como "MI PROYECTO PQR" — verificar que esté activo.

---

## Pasos para importar cada flujo

1. Abrir N8N: `https://td-pruebas.online/n8n`
2. Click en **"+"** (nuevo workflow) → **"Import from file"**
3. Seleccionar el archivo JSON de la carpeta `n8n/`
4. Una vez importado, **asignar las credenciales**:
   - Cada nodo HTTP que llama a Supabase → asignar `Supabase-ServiceKey`
   - Cada nodo que llama a Graph API → asignar `MicrosoftGraph-OAuth2`
   - Nodos OpenAI → asignar `OpenAI-PQR-Tododrogas`
5. Click **"Save"** (Ctrl+S)
6. Click **"Activate"** (toggle arriba a la derecha)

---

## Flujo 10 — Nota especial (Llamado interno)

El Flujo 10 NO tiene Schedule ni Webhook propio.  
Es llamado por otros flujos usando el nodo **"Execute Workflow"**.

Para usar el Flujo 10 desde otro flujo:
1. Agregar nodo **"Execute Workflow"**
2. En "Workflow" → seleccionar "FLUJO 10 — Confirmación Universal"
3. En "Workflow Input Data" → pasar el JSON:
```json
{
  "para":          "{{ $json.correo }}",
  "nombre":        "{{ $json.nombre }}",
  "ticket_id":     "{{ $json.ticket_id }}",
  "tipo_pqr":      "{{ $json.tipo_pqr }}",
  "tipo_evento":   "confirmacion",
  "mensaje_extra": ""
}
```

---

## Webhooks activos después de importar

Una vez todos los flujos activados, estos endpoints quedan disponibles:

| Endpoint | Flujo |
|----------|-------|
| `POST /webhook/pqr-recepcion` | Flujo 1 |
| `POST /webhook/pqr-canvas`    | Flujo 8 |
| `POST /webhook/pqr-audio`     | Flujo 9 |
| `POST /webhook/chatbot`       | Flujo 11 |
| `POST /webhook/admin/generar-qr` | Flujo 12 |

URL base: `https://td-pruebas.online/webhook/...`

---

## Verificar que todo funciona

```bash
# Test Flujo 1 — Recepción PQR
curl -X POST https://td-pruebas.online/webhook/pqr-recepcion \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Test Usuario",
    "correo": "test@test.com",
    "telefono": "3001234567",
    "tipo_pqr": "peticion",
    "descripcion": "Prueba del sistema PQR",
    "canal_contacto": "formulario_web"
  }'
# Respuesta esperada: { "success": true, "ticket_id": "TD-XXXXXXXX-XXXX" }

# Test Flujo 11 — Chatbot
curl -X POST https://td-pruebas.online/webhook/chatbot \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "mensaje": "Hola, quiero hacer una queja"
  }'
# Respuesta esperada: { "respuesta": "...", "mostrar_canales": true/false }
```

