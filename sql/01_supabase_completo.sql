-- ═══════════════════════════════════════════════════════════════
-- SISTEMA PQR TODODROGAS — SQL COMPLETO SUPABASE
-- Ejecutar en: Supabase > SQL Editor > New Query
-- Copiar y pegar TODO de una sola vez
-- ═══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- PASO 1: Ampliar tabla correos existente
-- ──────────────────────────────────────────────────────────────
ALTER TABLE correos
  ADD COLUMN IF NOT EXISTS origen            TEXT DEFAULT 'correo',
  ADD COLUMN IF NOT EXISTS tipo_pqr          TEXT,
  ADD COLUMN IF NOT EXISTS prioridad         TEXT DEFAULT 'media',
  ADD COLUMN IF NOT EXISTS canal_contacto    TEXT,
  ADD COLUMN IF NOT EXISTS ticket_id         TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS audio_url         TEXT,
  ADD COLUMN IF NOT EXISTS canvas_url        TEXT,
  ADD COLUMN IF NOT EXISTS transcripcion     TEXT,
  ADD COLUMN IF NOT EXISTS sentimiento       TEXT,
  ADD COLUMN IF NOT EXISTS categoria_ia      TEXT,
  ADD COLUMN IF NOT EXISTS fecha_limite_sla  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS telefono_contacto TEXT,
  ADD COLUMN IF NOT EXISTS datos_legales     JSONB DEFAULT '{}';

-- Índices para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_correos_ticket    ON correos(ticket_id);
CREATE INDEX IF NOT EXISTS idx_correos_estado    ON correos(estado);
CREATE INDEX IF NOT EXISTS idx_correos_agente    ON correos(agente_id);
CREATE INDEX IF NOT EXISTS idx_correos_sla       ON correos(fecha_limite_sla);
CREATE INDEX IF NOT EXISTS idx_correos_prioridad ON correos(prioridad);

-- ──────────────────────────────────────────────────────────────
-- PASO 2: Tabla chatbot_sesiones
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chatbot_sesiones (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at   TIMESTAMPTZ DEFAULT now(),
  session_id   TEXT        NOT NULL UNIQUE,
  canal_origen TEXT        DEFAULT 'tablet',
  mensajes     JSONB       DEFAULT '[]',
  resuelto     BOOLEAN     DEFAULT false,
  radicado_id  UUID        REFERENCES correos(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_chatbot_session ON chatbot_sesiones(session_id);

-- ──────────────────────────────────────────────────────────────
-- PASO 3: Tabla configuracion_sistema (fila única)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS configuracion_sistema (
  id               UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  updated_at       TIMESTAMPTZ DEFAULT now(),
  updated_by       TEXT    DEFAULT 'admin',
  -- Branding
  logo_url         TEXT,
  nombre_empresa   TEXT    DEFAULT 'Tododrogas',
  color_primario   TEXT    DEFAULT '#006D77',
  color_secundario TEXT    DEFAULT '#E29578',
  -- Carrusel de bienvenida
  slides           JSONB   DEFAULT '[
    {"id":1,"titulo":"Bienvenido a Tododrogas","subtitulo":"Tu salud es nuestra prioridad","activo":true},
    {"id":2,"titulo":"Canales de atención","subtitulo":"Formulario, Audio, WhatsApp, Correo","activo":true},
    {"id":3,"titulo":"Respondemos en 15 días hábiles","subtitulo":"Tu solicitud es importante para nosotros","activo":true}
  ]',
  -- FAQ para chatbot
  faq              JSONB   DEFAULT '[
    {"id":1,"pregunta":"¿Cómo hago seguimiento a mi PQR?","respuesta":"Recibes un correo con tu número de radicado.","activo":true},
    {"id":2,"pregunta":"¿Cuánto tiempo tarda la respuesta?","respuesta":"Máximo 15 días hábiles según normativa.","activo":true},
    {"id":3,"pregunta":"¿Qué tipos de PQR puedo radicar?","respuesta":"Peticiones, quejas, reclamos, sugerencias y felicitaciones.","activo":true}
  ]',
  -- QR
  qr_url           TEXT,
  qr_destino       TEXT    DEFAULT 'https://td-pruebas.online/pqr_form.html',
  -- Chatbot
  chatbot_contexto TEXT    DEFAULT 'Eres el asistente de PQR de Tododrogas. Ayuda al usuario a resolver dudas sobre sus peticiones, quejas o reclamos. Sé amable, conciso y responde siempre en español.',
  chatbot_activo   BOOLEAN DEFAULT true,
  -- Canales
  whatsapp_numero  TEXT    DEFAULT '573000000000',
  telefono_llamada TEXT    DEFAULT '6016000000',
  correo_atencion  TEXT    DEFAULT 'pqrsmirror@tododrogas.com.co',
  -- SLA en horas
  sla_peticion     INTEGER DEFAULT 168,
  sla_queja        INTEGER DEFAULT 120,
  sla_reclamo      INTEGER DEFAULT 168,
  sla_sugerencia   INTEGER DEFAULT 240,
  sla_urgente      INTEGER DEFAULT 24
);

-- Insertar fila única si no existe
INSERT INTO configuracion_sistema (id)
VALUES (gen_random_uuid())
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- PASO 4: Tabla historial_admin
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS historial_admin (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  usuario    TEXT        DEFAULT 'admin',
  accion     TEXT        NOT NULL,
  detalle    JSONB       DEFAULT '{}'
);

-- ──────────────────────────────────────────────────────────────
-- PASO 5: RLS — Row Level Security
-- ──────────────────────────────────────────────────────────────
ALTER TABLE chatbot_sesiones    ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracion_sistema ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_admin     ENABLE ROW LEVEL SECURITY;

-- Acceso total desde n8n (service_role key)
DROP POLICY IF EXISTS "service_key_all" ON chatbot_sesiones;
CREATE POLICY "service_key_all" ON chatbot_sesiones
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_key_all" ON configuracion_sistema;
CREATE POLICY "service_key_all" ON configuracion_sistema
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_key_all" ON historial_admin;
CREATE POLICY "service_key_all" ON historial_admin
  USING (true) WITH CHECK (true);

-- Lectura pública de configuracion (para los HTML del frontend)
DROP POLICY IF EXISTS "public_read" ON configuracion_sistema;
CREATE POLICY "public_read" ON configuracion_sistema
  FOR SELECT USING (true);

-- ──────────────────────────────────────────────────────────────
-- PASO 6: Storage Buckets
-- (Ejecutar manualmente en Supabase > Storage > New Bucket)
-- ──────────────────────────────────────────────────────────────
-- Bucket: audios         | Public: false | Limit: 10MB | MIME: audio/webm, audio/mp4, audio/mpeg
-- Bucket: canvas-images  | Public: false | Limit: 5MB  | MIME: image/png, image/jpeg
-- Bucket: logos-config   | Public: true  | Limit: 2MB  | MIME: image/png, image/jpeg, image/svg+xml
-- Bucket: adjuntos       | Public: false | Limit: 20MB | (si no existe ya)

-- ──────────────────────────────────────────────────────────────
-- VERIFICACIÓN FINAL
-- ──────────────────────────────────────────────────────────────
SELECT 'correos'               AS tabla, COUNT(*) AS filas FROM correos
UNION ALL
SELECT 'agentes',               COUNT(*) FROM agentes
UNION ALL
SELECT 'chatbot_sesiones',      COUNT(*) FROM chatbot_sesiones
UNION ALL
SELECT 'configuracion_sistema', COUNT(*) FROM configuracion_sistema
UNION ALL
SELECT 'historial_admin',       COUNT(*) FROM historial_admin
UNION ALL
SELECT 'historial_eventos',     COUNT(*) FROM historial_eventos
UNION ALL
SELECT 'adjuntos',              COUNT(*) FROM adjuntos;
