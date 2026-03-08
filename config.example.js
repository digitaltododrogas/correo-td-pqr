/**
 * config.example.js — Plantilla de configuración
 * ─────────────────────────────────────────────────
 * Este archivo ES seguro para subir al repositorio.
 * NO contiene valores reales.
 *
 * El archivo config.js REAL es generado automáticamente
 * por GitHub Actions (deploy.yml) usando los GitHub Secrets.
 * Nunca edites config.js a mano ni lo subas al repo.
 *
 * Para desarrollo local: copia este archivo como config.js
 * y rellena tus valores de desarrollo.
 */

window.CONFIG = {
  // ── Supabase ──────────────────────────────────────
  SUPABASE_URL: 'https://TU_PROYECTO.supabase.co',
  SUPABASE_KEY: 'eyJhbGci...tu_anon_key',   // Solo la anon key — NUNCA la service_role

  // ── Azure AD (solo IDs públicos, NUNCA el secret) ─
  GRAPH_TENANT:    'TU_TENANT_ID',
  GRAPH_CLIENT_ID: 'TU_CLIENT_ID',
  GRAPH_USER_ID:   'pqrsmirror@tododrogas.com.co',

  // ── N8N Webhooks ──────────────────────────────────
  N8N_WEBHOOK_BASE:      'https://td-pruebas.online/webhook',
  WEBHOOK_PQR_RECEPCION: 'https://td-pruebas.online/webhook/pqr-recepcion',
  WEBHOOK_CANVAS:        'https://td-pruebas.online/webhook/pqr-canvas',
  WEBHOOK_AUDIO:         'https://td-pruebas.online/webhook/pqr-audio',
  WEBHOOK_CHATBOT:       'https://td-pruebas.online/webhook/chatbot',

  // ── App ───────────────────────────────────────────
  APP_VERSION: '1.0.0',
  EMPRESA:     'Tododrogas CIA SAS',
};
