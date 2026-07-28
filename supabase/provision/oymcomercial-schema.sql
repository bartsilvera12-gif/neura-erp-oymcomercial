-- =====================================================================
-- Provisión schema 'oymcomercial' (estructura-only) desde 'reservacaacupe'
-- Generado por introspección de catálogos + reescritura de referencias.
-- Sin datos productivos. FKs a auth.users preservadas (Supabase compartido).
-- Funciones de plataforma neura_* excluidas (aislamiento de zentra_erp).
-- =====================================================================
BEGIN;
SET LOCAL check_function_bodies = false;
SET LOCAL client_min_messages = warning;

CREATE SCHEMA IF NOT EXISTS "oymcomercial";
GRANT USAGE ON SCHEMA "oymcomercial" TO anon, authenticated, service_role;

-- ---------- TABLAS (126) ----------
CREATE TABLE "oymcomercial"."categorias_productos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "codigo" text,
  "descripcion" text,
  "parent_id" uuid,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."chat_agents" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "queue_id" uuid NOT NULL,
  "is_online" boolean DEFAULT false NOT NULL,
  "max_conversations" integer DEFAULT 5 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "receives_new_chats" boolean DEFAULT true NOT NULL,
  "priority_in_queue" integer DEFAULT 0 NOT NULL,
  "operational_status_changed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "last_heartbeat_at" timestamp with time zone,
  "operational_status" text DEFAULT 'ready'::text NOT NULL
);
CREATE TABLE "oymcomercial"."chat_campaign_events" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "campaign_id" uuid NOT NULL,
  "recipient_id" uuid,
  "event_type" text NOT NULL,
  "event_payload_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_campaign_jobs" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "campaign_id" uuid NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "batch_size" integer DEFAULT 25 NOT NULL,
  "locked_at" timestamp with time zone,
  "locked_by" text,
  "attempts" integer DEFAULT 0 NOT NULL,
  "last_error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_campaign_recipients" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "campaign_id" uuid NOT NULL,
  "row_number" integer NOT NULL,
  "phone_raw" text,
  "phone_e164" text NOT NULL,
  "contact_id" uuid,
  "conversation_id" uuid,
  "row_payload_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "mapped_variables_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "validation_error" text,
  "provider_message_id" text,
  "provider_payload_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "last_status_raw_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "error_code" text,
  "error_message" text,
  "queued_at" timestamp with time zone,
  "sent_at" timestamp with time zone,
  "failed_at" timestamp with time zone,
  "first_reply_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_campaign_templates" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "channel_id" uuid NOT NULL,
  "provider" text NOT NULL,
  "provider_template_id" text,
  "name" text NOT NULL,
  "language" text DEFAULT 'es'::text NOT NULL,
  "category" text,
  "status" text DEFAULT 'unknown'::text NOT NULL,
  "components_json" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "variable_schema_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "provider_payload_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "last_synced_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_campaigns" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "name" text NOT NULL,
  "channel_id" uuid NOT NULL,
  "queue_id" uuid,
  "provider" text NOT NULL,
  "template_id" uuid,
  "template_name" text NOT NULL,
  "template_language" text DEFAULT 'es'::text NOT NULL,
  "template_category" text,
  "template_components_json" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "variable_mapping_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "import_original_filename" text,
  "import_storage_bucket" text,
  "import_storage_path" text,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "total_count" integer DEFAULT 0 NOT NULL,
  "valid_count" integer DEFAULT 0 NOT NULL,
  "invalid_count" integer DEFAULT 0 NOT NULL,
  "pending_count" integer DEFAULT 0 NOT NULL,
  "queued_count" integer DEFAULT 0 NOT NULL,
  "sent_count" integer DEFAULT 0 NOT NULL,
  "failed_count" integer DEFAULT 0 NOT NULL,
  "replied_count" integer DEFAULT 0 NOT NULL,
  "send_config_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "started_at" timestamp with time zone,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_channel_quick_replies" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "channel_id" uuid NOT NULL,
  "title" text NOT NULL,
  "body" text NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_channels" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "type" text DEFAULT 'whatsapp'::text NOT NULL,
  "meta_phone_number_id" text,
  "config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "nombre" text,
  "provider" text DEFAULT 'meta'::text NOT NULL,
  "provider_channel_id" text,
  "activo" boolean DEFAULT true NOT NULL,
  "whatsapp_access_token" text,
  "connection_mode" text,
  "config_status" text DEFAULT 'incomplete'::text NOT NULL
);
CREATE TABLE "oymcomercial"."chat_comprobante_validaciones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "flow_session_id" uuid NOT NULL,
  "channel_id" uuid,
  "flow_code" text DEFAULT ''::text NOT NULL,
  "comprobante_url" text,
  "comprobante_media_id" text,
  "comprobante_hash" text NOT NULL,
  "estado_validacion" text DEFAULT 'pendiente'::text NOT NULL,
  "motivo_validacion" text,
  "ocr_text_raw" text,
  "ocr_monto" text,
  "ocr_referencia" text,
  "ocr_fecha" text,
  "ocr_hora" text,
  "ocr_banco" text,
  "ocr_fingerprint" text,
  "sorteo_entrada_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "monto_validacion_esperado_gs" bigint,
  "monto_validacion_ocr_gs" bigint,
  "monto_validacion_diferencia_gs" bigint,
  "monto_validacion_status" text,
  "bank_val_titular_esperado" text,
  "bank_val_cuenta_esperada" text,
  "bank_val_alias_esperado" text,
  "bank_val_titular_ocr" text,
  "bank_val_cuenta_ocr" text,
  "bank_val_alias_ocr" text,
  "bank_val_coincidencias" integer,
  "bank_val_min_requeridas" integer,
  "bank_val_status" text,
  "manual_approval_usuario_id" uuid,
  "manual_approval_at" timestamp with time zone,
  "manual_approval_source" text,
  "manual_approval_note" text,
  "previous_estado_validacion" text,
  "previous_motivo_validacion" text
);
CREATE TABLE "oymcomercial"."chat_contacts" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "phone_number" text NOT NULL,
  "name" text,
  "cliente_id" uuid,
  "crm_prospecto_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "phone_normalized" text,
  "last_routed_chat_agent_id" uuid,
  "last_routed_at" timestamp with time zone,
  "last_routed_channel_id" uuid
);
CREATE TABLE "oymcomercial"."chat_conversation_closures" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "queue_id" uuid,
  "closure_state_id" uuid,
  "closure_substate_id" uuid,
  "closure_state_label" text NOT NULL,
  "closure_substate_label" text NOT NULL,
  "comment" text NOT NULL,
  "closed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "closed_by_usuario_id" uuid NOT NULL
);
CREATE TABLE "oymcomercial"."chat_conversations" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "channel_id" uuid NOT NULL,
  "contact_id" uuid NOT NULL,
  "status" text DEFAULT 'open'::text NOT NULL,
  "last_message_at" timestamp with time zone,
  "last_message_preview" text,
  "unread_count" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "flow_code" text,
  "flow_current_node" text,
  "flow_status" text DEFAULT 'bot'::text NOT NULL,
  "human_taken_over" boolean DEFAULT false NOT NULL,
  "active_flow_session_id" uuid,
  "first_revendedor_id" uuid,
  "first_referral_captured_at" timestamp with time zone,
  "assigned_agent_id" uuid,
  "queue_id" uuid,
  "priority" text DEFAULT 'medium'::text NOT NULL,
  "closed_at" timestamp with time zone,
  "closed_by_usuario_id" uuid,
  "initial_assignment_at" timestamp with time zone,
  "first_human_response_at" timestamp with time zone,
  "initial_reassign_count" integer DEFAULT 0 NOT NULL,
  "assignment_wait_code" text
);
CREATE TABLE "oymcomercial"."chat_empresa_operator_roles" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "role" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_data" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "flow_code" text NOT NULL,
  "field_name" text NOT NULL,
  "field_value" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "flow_session_id" uuid NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_events" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "flow_code" text,
  "node_code" text,
  "event_type" text NOT NULL,
  "selected_option_id" uuid,
  "meta_button_id" text,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "flow_session_id" uuid
);
CREATE TABLE "oymcomercial"."chat_flow_node_blocks" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "node_id" uuid NOT NULL,
  "block_type" text NOT NULL,
  "content_text" text,
  "media_url" text,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_nodes" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "flow_code" text NOT NULL,
  "node_code" text NOT NULL,
  "message_text" text,
  "node_type" text NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "save_as_field" text,
  "next_node_code" text,
  "crm_action_type" text,
  "crm_action_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "sort_order" integer NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_options" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "node_id" uuid NOT NULL,
  "label" text NOT NULL,
  "option_value" text NOT NULL,
  "meta_button_id" text NOT NULL,
  "next_node_code" text,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "option_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "group_title" text,
  "group_order" integer DEFAULT 0 NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_recontact_rules" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "flow_code" text NOT NULL,
  "nombre" text NOT NULL,
  "descripcion" text,
  "activo" boolean DEFAULT false NOT NULL,
  "prioridad" integer DEFAULT 100 NOT NULL,
  "included_node_codes" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "excluded_node_codes" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "idle_after_seconds" integer DEFAULT 3600 NOT NULL,
  "max_attempts" integer DEFAULT 1 NOT NULL,
  "cooldown_seconds" integer DEFAULT 86400 NOT NULL,
  "schedule_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "guard_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "message_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_recontact_runs" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "rule_id" uuid NOT NULL,
  "flow_code" text NOT NULL,
  "conversation_id" uuid,
  "flow_session_id" uuid,
  "decision" text NOT NULL,
  "skip_reason" text,
  "attempt_no" integer,
  "correlation_id" text,
  "payload_snapshot" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_flow_sessions" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "flow_code" text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "ended_at" timestamp with time zone,
  "end_reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "revendedor_id" uuid,
  "codigo_referido_snapshot" text,
  "referral_source" text
);
CREATE TABLE "oymcomercial"."chat_flows" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "flow_code" text NOT NULL,
  "label" text,
  "channel" text DEFAULT 'whatsapp'::text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sorteo_id" uuid,
  "sorteo_datos_incompletos_message" text,
  "flow_config" jsonb DEFAULT '{}'::jsonb NOT NULL
);
CREATE TABLE "oymcomercial"."chat_messages" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "wa_message_id" text,
  "from_me" boolean DEFAULT false NOT NULL,
  "message_type" text DEFAULT 'text'::text NOT NULL,
  "content" text,
  "raw_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sender_type" text DEFAULT 'system'::text,
  "sent_by_user_id" uuid,
  "sent_by_user_name" text,
  "automation_source" text,
  "whatsapp_delivery_status" text,
  "whatsapp_delivered_at" timestamp with time zone,
  "whatsapp_read_at" timestamp with time zone
);
CREATE TABLE "oymcomercial"."chat_omnicanal_work_schedules" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "time_start" time without time zone NOT NULL,
  "time_end" time without time zone NOT NULL,
  "days_of_week" smallint[] DEFAULT '{}'::smallint[] NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_queue_channels" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "queue_id" uuid NOT NULL,
  "channel_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_queue_closure_states" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "queue_id" uuid NOT NULL,
  "label" text NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_queue_closure_substates" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "closure_state_id" uuid NOT NULL,
  "label" text NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_queue_supervisors" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "queue_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_queues" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "channel_type" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "descripcion" text,
  "distribution_strategy" text DEFAULT 'least_load'::text NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "routing_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "assignment_state" jsonb DEFAULT '{}'::jsonb NOT NULL
);
CREATE TABLE "oymcomercial"."chat_routing_events" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "queue_id" uuid,
  "event_type" text NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_supervisor_agents" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "supervisor_usuario_id" uuid NOT NULL,
  "agent_usuario_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."chat_usuario_omnicanal" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "omnicanal_agent_enabled" boolean DEFAULT false NOT NULL,
  "work_schedule_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."cliente_historial" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "suscripcion_id" uuid,
  "tipo" text NOT NULL,
  "accion" text NOT NULL,
  "plan_anterior_id" uuid,
  "plan_nuevo_id" uuid,
  "plan_anterior_nombre" text,
  "plan_nuevo_nombre" text,
  "modo" text,
  "factura_id" uuid,
  "plan_pendiente_vigente_desde" date,
  "creado_por_auth_user_id" uuid,
  "creado_por_email" text,
  "detalle" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."cliente_obligaciones_tributarias" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_perfil_id" uuid NOT NULL,
  "obligacion_catalogo_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."cliente_perfil_tributario" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "perfil_activo" boolean DEFAULT false NOT NULL,
  "dv" text,
  "razon_social_fiscal" text,
  "clave_tributaria_encrypted" text,
  "honorario_mensual" numeric,
  "honorario_anual" numeric,
  "notas_tributarias" text,
  "obligacion_otro_detalle" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "dia_vencimiento_tributario" smallint
);
CREATE TABLE "oymcomercial"."cliente_tipos_servicio_catalogo" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "slug" text NOT NULL,
  "nombre" text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "orden" smallint DEFAULT 0 NOT NULL,
  "es_sistema" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."clientes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid,
  "nombre" text,
  "telefono" text,
  "email" text,
  "direccion" text,
  "created_at" timestamp without time zone DEFAULT now(),
  "tipo_cliente" text DEFAULT 'empresa'::text,
  "empresa" text,
  "ruc" text,
  "documento" text,
  "telefono_secundario" text,
  "email_secundario" text,
  "ciudad" text,
  "pais" text,
  "sitio_web" text,
  "instagram" text,
  "linkedin" text,
  "categoria_cliente" text,
  "industria" text,
  "valor_cliente" numeric,
  "condicion_pago" text,
  "moneda_preferida" text DEFAULT 'GS'::text,
  "vendedor_asignado" text,
  "origen" text DEFAULT 'MANUAL'::text,
  "prospecto_id" integer,
  "estado" text DEFAULT 'activo'::text,
  "notas" jsonb DEFAULT '[]'::jsonb,
  "updated_at" timestamp with time zone DEFAULT now(),
  "nombre_contacto" text,
  "created_by_user_id" uuid,
  "created_by_nombre" text,
  "tipo_servicio_cliente" text,
  "deleted_at" timestamp with time zone,
  "deleted_by_user_id" uuid,
  "deletion_reason" text,
  "baja_operativa_at" timestamp with time zone,
  "baja_operativa_by_user_id" uuid,
  "baja_operativa_motivo" text,
  "baja_operativa_anulo_factura" boolean,
  "baja_operativa_by_nombre" text,
  "vendedor_usuario_id" uuid,
  "sifen_receptor_extranjero" boolean DEFAULT false NOT NULL,
  "sifen_codigo_pais" text,
  "sifen_tipo_doc_receptor" smallint,
  "sifen_receptor_manual" boolean DEFAULT false NOT NULL,
  "sifen_receptor_naturaleza" text,
  "sifen_ti_ope" smallint,
  "sifen_num_id_de" text,
  "sifen_direccion_de" text,
  "sifen_num_casa_de" integer,
  "sifen_descripcion_tipo_doc" text,
  "plan_comercial_id" uuid,
  "usa_nota_remision" boolean DEFAULT false NOT NULL,
  "nombre_facturacion" text,
  "nivel_precio" text DEFAULT 'minorista'::text NOT NULL,
  "es_contribuyente" boolean DEFAULT false NOT NULL
);
CREATE TABLE "oymcomercial"."cobros_clientes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "cuenta_por_cobrar_id" uuid NOT NULL,
  "venta_id" uuid,
  "fecha_pago" timestamp with time zone DEFAULT now() NOT NULL,
  "monto" numeric DEFAULT 0 NOT NULL,
  "metodo_pago" text DEFAULT 'efectivo'::text NOT NULL,
  "entidad_bancaria_id" uuid,
  "referencia" text,
  "titular" text,
  "observaciones" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "usuario_id" uuid,
  "usuario_nombre" text,
  "entidad_nombre_snapshot" text,
  "conciliacion_estado" text DEFAULT 'pendiente'::text NOT NULL,
  "conciliado_at" timestamp with time zone,
  "conciliado_por" text,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."comision_ajustes" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "periodo_id" uuid,
  "linea_id" uuid,
  "monto" numeric(18,2) NOT NULL,
  "motivo" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid
);
CREATE TABLE "oymcomercial"."comision_equipo_miembros" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "equipo_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."comision_equipos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "supervisor_usuario_id" uuid NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."comision_escalas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "politica_id" uuid NOT NULL,
  "orden" integer DEFAULT 0 NOT NULL,
  "desde_monto" numeric(18,2) NOT NULL,
  "hasta_monto" numeric(18,2),
  "porcentaje_comision" numeric(9,4) NOT NULL,
  "premio_fijo" numeric(18,2),
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."comision_lineas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "periodo_id" uuid NOT NULL,
  "usuario_vendedor_id" uuid NOT NULL,
  "fuente_tipo" text,
  "fuente_id" uuid,
  "monto_base" numeric(18,2) DEFAULT 0 NOT NULL,
  "monto_comision" numeric(18,2) DEFAULT 0 NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."comision_periodos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "politica_id" uuid NOT NULL,
  "estado" text DEFAULT 'borrador'::text NOT NULL,
  "fecha_inicio" timestamp with time zone NOT NULL,
  "fecha_fin" timestamp with time zone NOT NULL,
  "label" text,
  "congelado_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."comision_politica_versiones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "politica_id" uuid NOT NULL,
  "version_no" integer NOT NULL,
  "nombre" text NOT NULL,
  "activo" boolean NOT NULL,
  "base_calculo" text NOT NULL,
  "timezone" text NOT NULL,
  "modo_periodo" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid
);
CREATE TABLE "oymcomercial"."comision_politicas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "base_calculo" text NOT NULL,
  "timezone" text DEFAULT 'America/Asuncion'::text NOT NULL,
  "modo_periodo" text DEFAULT 'mensual_penultimo_dia_habil'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid,
  "updated_by" uuid
);
CREATE TABLE "oymcomercial"."compras" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "proveedor_id" uuid NOT NULL,
  "proveedor_nombre" text NOT NULL,
  "producto_id" uuid NOT NULL,
  "producto_nombre" text NOT NULL,
  "cantidad" numeric NOT NULL,
  "moneda" text DEFAULT 'PYG'::text NOT NULL,
  "tipo_cambio" numeric DEFAULT 1 NOT NULL,
  "costo_unitario_original" numeric NOT NULL,
  "costo_unitario" numeric NOT NULL,
  "iva_tipo" text DEFAULT '10'::text NOT NULL,
  "subtotal" numeric NOT NULL,
  "monto_iva" numeric NOT NULL,
  "total" numeric NOT NULL,
  "precio_venta" numeric NOT NULL,
  "margen_venta" numeric,
  "tipo_pago" text DEFAULT 'contado'::text NOT NULL,
  "plazo_dias" integer,
  "nro_timbrado" text NOT NULL,
  "numero_control" text NOT NULL,
  "estado" text DEFAULT 'registrada'::text NOT NULL,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid,
  "usuario_nombre" text,
  "comprobante_url" text,
  "comprobante_storage_path" text,
  "comprobante_nombre" text,
  "comprobante_mime_type" text,
  "anulada_at" timestamp with time zone,
  "anulada_por" uuid,
  "anulacion_motivo" text,
  "fecha_factura" date,
  "metodo_pago" text,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."crm_etapas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "codigo" text NOT NULL,
  "nombre" text NOT NULL,
  "color" text DEFAULT 'gray'::text NOT NULL,
  "orden" integer DEFAULT 0 NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."crm_notas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "prospecto_id" uuid NOT NULL,
  "texto" text NOT NULL,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."crm_prospectos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "numero_control" text NOT NULL,
  "empresa" text NOT NULL,
  "contacto" text NOT NULL,
  "email" text,
  "telefono" text,
  "servicio" text NOT NULL,
  "valor_estimado" numeric DEFAULT 0,
  "etapa" text DEFAULT 'LEAD'::text NOT NULL,
  "proxima_accion" text,
  "fecha_proxima_accion" date,
  "creado_por" text,
  "responsable" text,
  "cliente_creado" boolean DEFAULT false,
  "fecha_creacion" timestamp with time zone DEFAULT now() NOT NULL,
  "fecha_actualizacion" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "origen_creacion" text DEFAULT 'manual'::text NOT NULL,
  "origen_detalle" text,
  "observaciones" text
);
CREATE TABLE "oymcomercial"."cuentas_por_cobrar" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "venta_id" uuid NOT NULL,
  "numero_venta" text,
  "fecha_emision" date DEFAULT CURRENT_DATE NOT NULL,
  "fecha_vencimiento" date,
  "moneda" text DEFAULT 'PYG'::text NOT NULL,
  "total" numeric DEFAULT 0 NOT NULL,
  "saldo" numeric DEFAULT 0 NOT NULL,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "observaciones" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."dashboard_views" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "slug" text NOT NULL,
  "nombre" text NOT NULL,
  "orden" integer DEFAULT 0 NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."empresa_autoimpresor_config" (
  "empresa_id" uuid NOT NULL,
  "activo" boolean DEFAULT false NOT NULL,
  "ruc_emisor" text,
  "razon_social_emisor" text,
  "nombre_fantasia" text,
  "direccion_matriz" text,
  "telefono" text,
  "timbrado_numero" text,
  "timbrado_inicio_vigencia" date,
  "timbrado_fin_vigencia" date,
  "establecimiento_codigo" text,
  "punto_expedicion_codigo" text,
  "numero_actual" integer,
  "numero_inicial" integer,
  "numero_final" integer,
  "tipo_documento_default" text DEFAULT 'factura'::text NOT NULL,
  "formato_impresion_default" text DEFAULT 'pdf_a4'::text NOT NULL,
  "leyenda_papel_termico" text,
  "observaciones" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."empresa_dashboard_views" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "dashboard_view_id" uuid NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."empresa_facturacion_modo" (
  "empresa_id" uuid NOT NULL,
  "modo" text DEFAULT 'sin_factura_fiscal'::text NOT NULL,
  "impresion_tipo_default" text DEFAULT 'pdf_a4'::text NOT NULL,
  "imprimir_al_confirmar" boolean DEFAULT false NOT NULL,
  "preguntar_datos_al_confirmar" boolean DEFAULT false NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."empresa_modulos" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "created_at" timestamp without time zone DEFAULT now() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "modulo_id" uuid
);
CREATE TABLE "oymcomercial"."empresa_sifen_config" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "ambiente" text DEFAULT 'test'::text NOT NULL,
  "ruc" text NOT NULL,
  "razon_social" text NOT NULL,
  "timbrado_numero" text NOT NULL,
  "establecimiento" text NOT NULL,
  "punto_expedicion" text NOT NULL,
  "csc" text,
  "certificado_path" text,
  "certificado_vencimiento" timestamp with time zone,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "certificado_password_encrypted" text,
  "direccion_fiscal" text,
  "timbrado_fecha_inicio_vigencia" date,
  "actividad_economica_codigo" text,
  "actividad_economica_descripcion" text,
  "sifen_plazo_cancelacion_horas" integer DEFAULT 48 NOT NULL,
  "kude_logo_path" text,
  "kude_color_primario" text,
  "kude_color_primario_fill" text,
  "emisor_telefono" text,
  "emisor_email" text
);
CREATE TABLE "oymcomercial"."empresas" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nombre_empresa" text NOT NULL,
  "ruc" text,
  "telefono" text,
  "email" text,
  "direccion" text,
  "pais" text DEFAULT 'PARAGUAY'::text,
  "plan" text,
  "estado" text DEFAULT 'ACTIVA'::text,
  "created_at" timestamp without time zone DEFAULT now(),
  "data_schema" text,
  "gestion_tributaria_clientes" boolean DEFAULT false NOT NULL
);
CREATE TABLE "oymcomercial"."entidades_bancarias" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "tipo" text,
  "activo" boolean DEFAULT true NOT NULL,
  "orden" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "codigo" text
);
CREATE TABLE "oymcomercial"."factura_correlativos" (
  "empresa_id" uuid NOT NULL,
  "prefijo" text DEFAULT 'FAC-'::text NOT NULL,
  "ultimo_numero" bigint DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."factura_electronica" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "factura_id" uuid NOT NULL,
  "estado_sifen" text DEFAULT 'borrador'::text NOT NULL,
  "cdc" text,
  "xml_path" text,
  "kude_url" text,
  "qr_data" text,
  "error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "xml_firmado_path" text,
  "sifen_d_prot_cons_lote" text,
  "sifen_ultima_respuesta_recibe_lote" jsonb,
  "sifen_ultima_respuesta_consulta_lote" jsonb,
  "sifen_aprobado_at" timestamp with time zone,
  "sifen_cancelado_at" timestamp with time zone,
  "sifen_cancelacion_motivo" text,
  "sifen_regeneracion_seq" integer DEFAULT 0 NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."factura_electronica_evento" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "factura_electronica_id" uuid NOT NULL,
  "tipo" text NOT NULL,
  "detalle" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."factura_items" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "factura_id" uuid NOT NULL,
  "empresa_id" uuid NOT NULL,
  "descripcion" text NOT NULL,
  "cantidad" numeric DEFAULT 1 NOT NULL,
  "precio_unitario" numeric DEFAULT 0 NOT NULL,
  "subtotal" numeric DEFAULT 0 NOT NULL,
  "iva" numeric DEFAULT 0 NOT NULL,
  "total" numeric DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "tipo_iva" text NOT NULL
);
CREATE TABLE "oymcomercial"."facturas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid,
  "numero_factura" text NOT NULL,
  "fecha" date NOT NULL,
  "fecha_vencimiento" date NOT NULL,
  "monto" numeric NOT NULL,
  "saldo" numeric DEFAULT 0 NOT NULL,
  "estado" text DEFAULT 'Pendiente'::text NOT NULL,
  "tipo" text NOT NULL,
  "moneda" text DEFAULT 'GS'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "suscripcion_id" uuid,
  "cliente_razon_social" text,
  "cliente_ruc" text,
  "origen_venta_id" uuid,
  "observaciones" text,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."gastos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "categoria" text,
  "descripcion" text,
  "monto" numeric(12,2) NOT NULL,
  "tipo" text DEFAULT 'variable'::text NOT NULL,
  "recurrente" boolean DEFAULT false NOT NULL,
  "frecuencia" text,
  "fecha" date NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "beneficiario" text,
  "metodo_pago" text,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."imports_audit" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "entidad" text NOT NULL,
  "filename" text,
  "total_rows" integer DEFAULT 0 NOT NULL,
  "inserted_count" integer DEFAULT 0 NOT NULL,
  "updated_count" integer DEFAULT 0 NOT NULL,
  "skipped_count" integer DEFAULT 0 NOT NULL,
  "error_count" integer DEFAULT 0 NOT NULL,
  "warning_count" integer DEFAULT 0 NOT NULL,
  "errors_json" jsonb,
  "warnings_json" jsonb,
  "created_by" text,
  "usuario_nombre" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."inventario_stock_ubicacion" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "producto_id" uuid NOT NULL,
  "ubicacion_id" uuid NOT NULL,
  "stock_actual" numeric DEFAULT 0 NOT NULL,
  "stock_minimo" numeric,
  "stock_maximo" numeric,
  "es_principal" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."inventario_ubicaciones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "codigo" text,
  "tipo" text DEFAULT 'deposito'::text NOT NULL,
  "parent_id" uuid,
  "descripcion" text,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."marketing_calendarios" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid,
  "mes" text,
  "semana" integer,
  "fecha_inicio" date,
  "fecha_fin" date,
  "estado_calendario" text DEFAULT 'pendiente'::text NOT NULL,
  "enviado_estado" text DEFAULT 'no_enviado'::text NOT NULL,
  "aprobado_estado" text DEFAULT 'pendiente'::text NOT NULL,
  "observaciones" text,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."marketing_comentarios" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "pieza_id" uuid NOT NULL,
  "usuario_id" uuid,
  "comentario" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."marketing_historial_estados" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "pieza_id" uuid NOT NULL,
  "campo" text NOT NULL,
  "estado_anterior" text,
  "estado_nuevo" text,
  "changed_by" uuid,
  "changed_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."marketing_piezas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "calendario_id" uuid,
  "cliente_id" uuid,
  "titulo" text NOT NULL,
  "tipo_pieza" text,
  "canal" text,
  "responsable_id" uuid,
  "fecha_limite" date,
  "fecha_publicacion" date,
  "prioridad" text DEFAULT 'media'::text NOT NULL,
  "estado_produccion" text DEFAULT 'por_hacer'::text NOT NULL,
  "estado_cliente" text DEFAULT 'no_enviado'::text NOT NULL,
  "estado_publicacion" text DEFAULT 'pendiente'::text NOT NULL,
  "link_archivo" text,
  "observaciones" text,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."marketing_tasks" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "titulo" text NOT NULL,
  "descripcion" text,
  "tipo_contenido" text NOT NULL,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "fecha_entrega" date NOT NULL,
  "responsable_user_id" uuid,
  "prioridad" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "suscripcion_id" uuid,
  "plan_id" uuid,
  "generada_automaticamente" boolean DEFAULT false NOT NULL
);
CREATE TABLE "oymcomercial"."modulos" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "nombre" text,
  "descripcion" text,
  "slug" text
);
CREATE TABLE "oymcomercial"."movimientos_inventario" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "producto_id" uuid NOT NULL,
  "producto_nombre" text NOT NULL,
  "producto_sku" text NOT NULL,
  "tipo" text NOT NULL,
  "cantidad" numeric NOT NULL,
  "costo_unitario" numeric DEFAULT 0 NOT NULL,
  "origen" text NOT NULL,
  "referencia" text,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "venta_id" uuid,
  "created_by" uuid,
  "usuario_nombre" text,
  "produccion_id" uuid,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."nota_credito" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "factura_id" uuid NOT NULL,
  "monto" numeric NOT NULL,
  "motivo" text NOT NULL,
  "observacion_interna" text,
  "estado_erp" text DEFAULT 'borrador'::text NOT NULL,
  "created_by_user_id" uuid,
  "created_by_email_snapshot" text,
  "created_by_nombre_snapshot" text,
  "saldo_previo_snapshot" numeric NOT NULL,
  "monto_factura_snapshot" numeric NOT NULL,
  "suma_pagos_snapshot" numeric NOT NULL,
  "moneda_snapshot" text NOT NULL,
  "factura_electronica_origen_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "tipo_nc" text DEFAULT 'total'::text NOT NULL,
  "numero" integer,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."nota_credito_electronica" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nota_credito_id" uuid NOT NULL,
  "estado_sifen" text DEFAULT 'sin_envio'::text NOT NULL,
  "cdc" text,
  "cdc_factura_origen" text,
  "xml_path" text,
  "xml_firmado_path" text,
  "kude_url" text,
  "response_json" jsonb,
  "error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sifen_d_prot_cons_lote" text,
  "sifen_ultima_respuesta_recibe_lote" jsonb,
  "sifen_ultima_respuesta_consulta_lote" jsonb,
  "sifen_aprobado_at" timestamp with time zone,
  "last_response_json" jsonb,
  "last_error" text,
  "sifen_cancelado_at" timestamp with time zone,
  "sifen_cancelacion_motivo" text
);
CREATE TABLE "oymcomercial"."nota_credito_evento" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nota_credito_id" uuid NOT NULL,
  "actor_user_id" uuid,
  "tipo_evento" text NOT NULL,
  "detalle_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."nota_credito_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nota_credito_id" uuid NOT NULL,
  "factura_item_id" uuid,
  "producto_id" uuid,
  "producto_nombre_snapshot" text NOT NULL,
  "sku_snapshot" text,
  "cantidad" numeric(14,4) NOT NULL,
  "precio_unitario" numeric(14,4) NOT NULL,
  "tipo_iva" text NOT NULL,
  "subtotal" numeric(14,2) NOT NULL,
  "monto_iva" numeric(14,2) NOT NULL,
  "total_linea" numeric(14,2) NOT NULL,
  "modo" text DEFAULT 'unidades'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."obligaciones_tributarias_catalogo" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "slug" text NOT NULL,
  "nombre" text NOT NULL,
  "requiere_detalle_otro" boolean DEFAULT false NOT NULL,
  "orden" smallint DEFAULT 0 NOT NULL
);
CREATE TABLE "oymcomercial"."omnichannel_routes" (
  "meta_phone_number_id" text NOT NULL,
  "empresa_id" uuid NOT NULL,
  "channel_id" uuid NOT NULL,
  "data_schema" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."pagos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "factura_id" uuid NOT NULL,
  "monto" numeric NOT NULL,
  "fecha_pago" date NOT NULL,
  "metodo_pago" text DEFAULT 'efectivo'::text NOT NULL,
  "referencia" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "cliente_id" uuid,
  "usuario_id" uuid,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."planes" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "codigo_plan" text NOT NULL,
  "nombre" text NOT NULL,
  "descripcion" text,
  "precio" numeric NOT NULL,
  "moneda" text DEFAULT 'GS'::text NOT NULL,
  "periodicidad" text DEFAULT 'mensual'::text NOT NULL,
  "limite_usuarios" integer,
  "limite_clientes" integer,
  "limite_facturas" integer,
  "estado" text DEFAULT 'activo'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "es_plan_marketing" boolean DEFAULT false NOT NULL,
  "plantilla_operativa" jsonb
);
CREATE TABLE "oymcomercial"."presupuesto_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "presupuesto_id" uuid NOT NULL,
  "producto_id" uuid,
  "producto_nombre" text NOT NULL,
  "sku" text,
  "cantidad" numeric NOT NULL,
  "unidad_medida" text,
  "precio_unitario" numeric DEFAULT 0 NOT NULL,
  "iva_tipo" text DEFAULT '10%'::text NOT NULL,
  "subtotal" numeric DEFAULT 0 NOT NULL,
  "monto_iva" numeric DEFAULT 0 NOT NULL,
  "descuento" numeric DEFAULT 0 NOT NULL,
  "total" numeric DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."presupuestos" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid,
  "cliente_nombre" text NOT NULL,
  "cliente_ruc" text,
  "cliente_telefono" text,
  "cliente_direccion" text,
  "numero_control" text NOT NULL,
  "estado" text DEFAULT 'creado'::text NOT NULL,
  "moneda" text DEFAULT 'PYG'::text NOT NULL,
  "subtotal" numeric DEFAULT 0 NOT NULL,
  "monto_iva" numeric DEFAULT 0 NOT NULL,
  "descuento_total" numeric DEFAULT 0 NOT NULL,
  "total" numeric DEFAULT 0 NOT NULL,
  "validez_dias" integer,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "fecha_vencimiento" date,
  "forma_pago" text,
  "plazo_entrega" text,
  "observaciones" text,
  "convertido_pedido_id" uuid,
  "convertido_venta_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "fecha_entrega" date,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."produccion_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "produccion_id" uuid NOT NULL,
  "insumo_producto_id" uuid NOT NULL,
  "insumo_nombre" text NOT NULL,
  "cantidad" numeric NOT NULL,
  "unidad_medida" text,
  "costo_unitario" numeric DEFAULT 0 NOT NULL,
  "subcosto" numeric DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."producciones" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "receta_id" uuid,
  "producto_id" uuid NOT NULL,
  "producto_nombre" text NOT NULL,
  "cantidad_fabricada" numeric NOT NULL,
  "rendimiento_cantidad" numeric DEFAULT 1 NOT NULL,
  "unidad_rendimiento" text,
  "costo_total" numeric DEFAULT 0 NOT NULL,
  "costo_unitario" numeric DEFAULT 0 NOT NULL,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "usuario_id" uuid,
  "usuario_nombre" text,
  "observaciones" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."producto_categorias" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "producto_id" uuid NOT NULL,
  "categoria_id" uuid NOT NULL,
  "es_principal" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."productos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "sku" text NOT NULL,
  "costo_promedio" numeric DEFAULT 0 NOT NULL,
  "precio_venta" numeric DEFAULT 0 NOT NULL,
  "stock_actual" numeric DEFAULT 0 NOT NULL,
  "stock_minimo" numeric DEFAULT 0 NOT NULL,
  "unidad_medida" text DEFAULT 'Unidad'::text NOT NULL,
  "metodo_valuacion" text DEFAULT 'CPP'::text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "imagen_url" text,
  "imagen_path" text,
  "codigo_barras" text,
  "codigo_barras_interno" boolean DEFAULT false NOT NULL,
  "proveedor_principal_id" uuid,
  "categoria_principal_id" uuid,
  "ubicacion_principal_id" uuid,
  "es_insumo" boolean DEFAULT false NOT NULL,
  "es_vendible" boolean DEFAULT true NOT NULL,
  "controla_stock" boolean DEFAULT true NOT NULL,
  "valorizado" boolean DEFAULT true NOT NULL,
  "unidad_compra" text,
  "unidad_receta" text,
  "factor_compra_receta" numeric DEFAULT 1 NOT NULL,
  "tiempo_prep_minutos" integer DEFAULT 0 NOT NULL,
  "descripcion" text,
  "precio_mayorista" numeric,
  "cantidad_minima_mayorista" numeric,
  "precio_distribuidor" numeric,
  "modo_receta" text DEFAULT 'preparado_al_vender'::text NOT NULL,
  "tipo_iva" text DEFAULT '10%'::text NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."productos_codigo_secuencia" (
  "empresa_id" uuid NOT NULL,
  "last_value" bigint DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proveedor_categoria_rel" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "proveedor_id" uuid NOT NULL,
  "categoria_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proveedor_categorias" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "descripcion" text,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proveedor_productos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "producto_id" uuid NOT NULL,
  "proveedor_id" uuid NOT NULL,
  "es_principal" boolean DEFAULT false NOT NULL,
  "codigo_proveedor" text,
  "costo_habitual" numeric,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "marca" text
);
CREATE TABLE "oymcomercial"."proveedores" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "ruc" text,
  "telefono" text,
  "email" text,
  "direccion" text,
  "contacto" text,
  "estado" text DEFAULT 'activo'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "nombre_comercial" text,
  "razon_social" text,
  "condicion_pago" text,
  "plazo_pago_dias" integer,
  "moneda_preferida" text,
  "observaciones" text
);
CREATE TABLE "oymcomercial"."proyecto_archivos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "proyecto_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "storage_bucket" text DEFAULT 'proyectos'::text NOT NULL,
  "storage_path" text NOT NULL,
  "mime_type" text,
  "size_bytes" bigint,
  "uploaded_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proyecto_comentarios" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "proyecto_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "comentario" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proyecto_estado_historial" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "proyecto_id" uuid NOT NULL,
  "estado_anterior_id" uuid,
  "estado_nuevo_id" uuid NOT NULL,
  "changed_by" uuid,
  "changed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "entered_at" timestamp with time zone DEFAULT now() NOT NULL,
  "exited_at" timestamp with time zone,
  "duration_seconds" bigint,
  "tipo_sla_snapshot" text,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL
);
CREATE TABLE "oymcomercial"."proyecto_estados" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "codigo" text NOT NULL,
  "descripcion" text,
  "color" text DEFAULT '#64748b'::text NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "cuenta_sla" boolean DEFAULT true NOT NULL,
  "tipo_sla" text NOT NULL,
  "sla_horas_objetivo" integer,
  "es_estado_inicial" boolean DEFAULT false NOT NULL,
  "es_estado_final" boolean DEFAULT false NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proyecto_prioridades_config" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "codigo" text NOT NULL,
  "nombre" text NOT NULL,
  "color" text,
  "bg_color" text,
  "text_color" text,
  "border_color" text,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proyecto_tareas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "proyecto_id" uuid NOT NULL,
  "titulo" text NOT NULL,
  "descripcion" text,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "responsable_id" uuid,
  "fecha_limite" timestamp with time zone,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "completed_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proyecto_tipos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "codigo" text NOT NULL,
  "descripcion" text,
  "config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."proyectos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid,
  "tipo_id" uuid NOT NULL,
  "estado_id" uuid NOT NULL,
  "titulo" text NOT NULL,
  "descripcion" text,
  "prioridad" text DEFAULT 'normal'::text NOT NULL,
  "responsable_comercial_id" uuid,
  "responsable_tecnico_id" uuid,
  "fecha_ingreso" timestamp with time zone DEFAULT now() NOT NULL,
  "fecha_prometida" timestamp with time zone,
  "fecha_entrega" timestamp with time zone,
  "monto_vendido" numeric(14,2),
  "observaciones_comerciales" text,
  "brief_data" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "bloqueado" boolean DEFAULT false NOT NULL,
  "bloqueo_motivo" text,
  "archivado" boolean DEFAULT false NOT NULL,
  "ultimo_movimiento_at" timestamp with time zone DEFAULT now() NOT NULL,
  "last_activity_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."receta_items" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "receta_id" uuid NOT NULL,
  "insumo_producto_id" uuid NOT NULL,
  "cantidad" numeric NOT NULL,
  "unidad_medida" text,
  "merma_pct" numeric DEFAULT 0 NOT NULL,
  "orden" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."recetas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "producto_id" uuid NOT NULL,
  "nombre" text,
  "rendimiento_cantidad" numeric DEFAULT 1 NOT NULL,
  "rendimiento_unidad" text,
  "notas" text,
  "activa" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."recibos_dinero" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "numero_recibo" text NOT NULL,
  "cliente_id" uuid,
  "cliente_nombre" text NOT NULL,
  "cliente_documento" text,
  "origen" text DEFAULT 'manual'::text NOT NULL,
  "venta_id" uuid,
  "cuenta_por_cobrar_id" uuid,
  "cobro_cliente_id" uuid,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "moneda" text DEFAULT 'PYG'::text NOT NULL,
  "monto" numeric DEFAULT 0 NOT NULL,
  "metodo_pago" text,
  "entidad_bancaria_id" uuid,
  "referencia" text,
  "concepto" text,
  "observaciones" text,
  "usuario_id" uuid,
  "usuario_nombre" text,
  "anulado" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."recibos_dinero_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "recibo_id" uuid NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cuenta_por_cobrar_id" uuid,
  "cobro_cliente_id" uuid,
  "factura_id" uuid,
  "numero_documento" text,
  "fecha_vencimiento" date,
  "importe_aplicado" numeric NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."sifen_jobs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "data_schema" text NOT NULL,
  "factura_id" uuid NOT NULL,
  "factura_electronica_id" uuid NOT NULL,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "etapa" text,
  "intentos" integer DEFAULT 0 NOT NULL,
  "max_intentos_auto" integer DEFAULT 2 NOT NULL,
  "intentos_log" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "codigo_error_set" text,
  "codigo_sub_error_set" text,
  "mensaje_set" text,
  "ultimo_error" text,
  "tipo_error" text,
  "respuesta_recibe_lote" jsonb,
  "respuesta_consulta_lote" jsonb,
  "cdc" text,
  "protocolo_lote" text,
  "tiempo_xml_ms" integer,
  "tiempo_firmar_ms" integer,
  "tiempo_enviar_ms" integer,
  "tiempo_consulta_ms" integer,
  "tiempo_total_ms" integer,
  "origen" text DEFAULT 'auto_venta'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "started_at" timestamp with time zone,
  "finished_at" timestamp with time zone,
  "procesando_desde" timestamp with time zone,
  "lock_owner" text,
  "proximo_reintento_at" timestamp with time zone,
  "veces_re_encolado_consulta" integer DEFAULT 0 NOT NULL,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."sorteo_conversaciones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "sorteo_id" uuid NOT NULL,
  "whatsapp_numero" text NOT NULL,
  "cliente_id" uuid,
  "estado" text DEFAULT 'new_lead'::text NOT NULL,
  "ultimo_mensaje" text,
  "cantidad_boletos" integer,
  "datos_cliente" jsonb DEFAULT '{}'::jsonb,
  "recordatorio_24h" boolean DEFAULT false,
  "recordatorio_48h" boolean DEFAULT false,
  "recordatorio_72h" boolean DEFAULT false,
  "ultimo_recordatorio_at" timestamp with time zone,
  "human_handoff_at" timestamp with time zone,
  "activa" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."sorteo_cupones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "sorteo_id" uuid NOT NULL,
  "entrada_id" uuid NOT NULL,
  "numero_cupon" text NOT NULL,
  "ganador" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "coupon_number_value" integer
);
CREATE TABLE "oymcomercial"."sorteo_entradas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "sorteo_id" uuid NOT NULL,
  "conversacion_id" uuid,
  "cliente_id" uuid,
  "whatsapp_numero" text NOT NULL,
  "nombre_participante" text NOT NULL,
  "documento" text,
  "cantidad_boletos" integer NOT NULL,
  "monto_total" numeric NOT NULL,
  "moneda" text DEFAULT 'PYG'::text NOT NULL,
  "estado_pago" text DEFAULT 'pendiente'::text NOT NULL,
  "fecha_pago" timestamp with time zone,
  "monto_pagado" numeric,
  "banco_origen" text,
  "comprobante_url" text,
  "comprobante_ia_resultado" jsonb DEFAULT '{}'::jsonb,
  "comprobante_ia_confianza" numeric,
  "validado_por" text DEFAULT 'IA'::text,
  "validado_por_user_id" uuid,
  "validado_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "numero_orden" integer NOT NULL,
  "chat_conversation_id" uuid,
  "flow_code" text,
  "idempotency_key" text,
  "promo_nombre" text,
  "precio_fuente" text,
  "precio_regular_referencia" numeric,
  "comprobante_validacion_id" uuid,
  "revendedor_id" uuid,
  "codigo_referido_snapshot" text,
  "observacion_interna" text,
  "venta_origen" text,
  "venta_canal" text,
  "pago_metodo" text,
  "cupones_impresos_at" timestamp with time zone,
  "cupones_impresos_by" uuid,
  "cupones_impresion_count" integer
);
CREATE TABLE "oymcomercial"."sorteo_revendedor_clicks" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "sorteo_id" uuid NOT NULL,
  "revendedor_id" uuid NOT NULL,
  "attribution_token" text NOT NULL,
  "user_agent" text,
  "ip_hash" text,
  "conversation_id" uuid,
  "flow_session_id" uuid,
  "contact_phone_norm" text,
  "redeemed_at" timestamp with time zone,
  "expires_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."sorteo_revendedores" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "sorteo_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "telefono" text,
  "codigo_referido" text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."sorteo_ticket_deliveries" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "sorteo_id" uuid NOT NULL,
  "entrada_id" uuid NOT NULL,
  "conversation_id" uuid,
  "flow_session_id" uuid,
  "delivery_mode" text NOT NULL,
  "status" text NOT NULL,
  "cliente_nombre" text,
  "cliente_documento" text,
  "telefono" text,
  "numero_orden" text,
  "cupones" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "storage_bucket" text,
  "storage_path" text,
  "whatsapp_message_id" text,
  "provider" text,
  "channel_id" uuid,
  "error_message" text,
  "payload_snapshot" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "config_snapshot" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "template_revision" integer DEFAULT 1 NOT NULL,
  "is_current" boolean DEFAULT true NOT NULL,
  "png_bytes_hash" text,
  "generated_at" timestamp with time zone,
  "sent_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."sorteos" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "descripcion" text,
  "precio_por_boleto" numeric DEFAULT 0 NOT NULL,
  "max_boletos" integer DEFAULT 100 NOT NULL,
  "total_boletos_vendidos" integer DEFAULT 0 NOT NULL,
  "ultimo_numero_cupon" integer DEFAULT 0 NOT NULL,
  "fecha_sorteo" timestamp with time zone,
  "estado" text DEFAULT 'activo'::text NOT NULL,
  "datos_bancarios" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "imagen_url" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "ultimo_numero_orden" integer DEFAULT 0 NOT NULL,
  "ticket_delivery_mode" text DEFAULT 'text_only'::text NOT NULL,
  "ticket_image_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "coupon_numbering_enabled" boolean DEFAULT false NOT NULL,
  "coupon_number_start" integer,
  "coupon_number_mode" text,
  "coupon_number_limit" integer
);
CREATE TABLE "oymcomercial"."sucursales" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "codigo" text NOT NULL,
  "nombre" text NOT NULL,
  "es_principal" boolean DEFAULT false NOT NULL,
  "activa" boolean DEFAULT true NOT NULL,
  "establecimiento" text,
  "punto_expedicion" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."suscripciones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "plan_id" uuid,
  "precio" numeric DEFAULT 0 NOT NULL,
  "moneda" text DEFAULT 'GS'::text NOT NULL,
  "fecha_inicio" date NOT NULL,
  "duracion_meses" integer DEFAULT 12 NOT NULL,
  "dia_facturacion" integer DEFAULT 1 NOT NULL,
  "dia_vencimiento" integer DEFAULT 10 NOT NULL,
  "estado" text DEFAULT 'activa'::text NOT NULL,
  "generar_factura_este_mes" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "plan_pendiente_id" uuid,
  "precio_pendiente" numeric,
  "moneda_pendiente" text,
  "plan_pendiente_vigente_desde" date
);
CREATE TABLE "oymcomercial"."tipificaciones" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid NOT NULL,
  "usuario" text NOT NULL,
  "tipo_gestion" text NOT NULL,
  "resultado" text NOT NULL,
  "observacion" text NOT NULL,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."transferencias_inventario" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "numero" text NOT NULL,
  "sucursal_origen_id" uuid NOT NULL,
  "sucursal_destino_id" uuid NOT NULL,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "observacion_solicitud" text,
  "motivo_rechazo" text,
  "solicitada_por" uuid,
  "aprobada_por" uuid,
  "despachada_por" uuid,
  "recibida_por" uuid,
  "solicitada_at" timestamp with time zone DEFAULT now() NOT NULL,
  "aprobada_at" timestamp with time zone,
  "rechazada_at" timestamp with time zone,
  "despachada_at" timestamp with time zone,
  "recibida_at" timestamp with time zone,
  "cancelada_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."transferencias_inventario_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "transferencia_id" uuid NOT NULL,
  "empresa_id" uuid NOT NULL,
  "producto_destino_id" uuid NOT NULL,
  "producto_origen_id" uuid,
  "sku_snapshot" text,
  "nombre_snapshot" text,
  "unidad_snapshot" text,
  "cantidad_solicitada" numeric NOT NULL,
  "cantidad_aprobada" numeric DEFAULT 0 NOT NULL,
  "cantidad_despachada" numeric DEFAULT 0 NOT NULL,
  "cantidad_recibida" numeric DEFAULT 0 NOT NULL,
  "costo_unitario_transferencia" numeric DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."usuario_dashboard_views" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "usuario_id" uuid NOT NULL,
  "dashboard_view_id" uuid NOT NULL,
  "es_default" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."usuario_modulos" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "usuario_id" uuid NOT NULL,
  "modulo_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE "oymcomercial"."usuarios" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "email" text,
  "nombre" text,
  "rol" text,
  "empresa_id" uuid,
  "auth_user_id" uuid,
  "created_at" timestamp with time zone DEFAULT now(),
  "activo" boolean DEFAULT true,
  "porcentaje_comision" numeric,
  "estado" text DEFAULT 'activo'::text NOT NULL,
  "telefono" text,
  "fecha_nacimiento" date,
  "fecha_ingreso" date,
  "tipo_contrato" text,
  "salario_base" numeric,
  "ips" boolean DEFAULT false NOT NULL,
  "area" text,
  "sucursal_predeterminada_id" uuid
);
CREATE TABLE "oymcomercial"."ventas" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "cliente_id" uuid,
  "numero_control" text NOT NULL,
  "moneda" text DEFAULT 'GS'::text NOT NULL,
  "tipo_cambio" numeric DEFAULT 1 NOT NULL,
  "subtotal" numeric DEFAULT 0 NOT NULL,
  "monto_iva" numeric DEFAULT 0 NOT NULL,
  "total" numeric DEFAULT 0 NOT NULL,
  "estado" text DEFAULT 'completada'::text NOT NULL,
  "tipo_venta" text DEFAULT 'CONTADO'::text NOT NULL,
  "plazo_dias" integer,
  "fecha" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "observaciones" text,
  "metodo_pago" text,
  "genera_nota_remision" boolean DEFAULT false NOT NULL,
  "nota_remision_numero" text,
  "anulada_at" timestamp with time zone,
  "anulada_por" uuid,
  "anulacion_motivo" text,
  "factura_id" uuid,
  "sucursal_id" uuid
);
CREATE TABLE "oymcomercial"."ventas_items" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "venta_id" uuid NOT NULL,
  "producto_id" uuid NOT NULL,
  "producto_nombre" text NOT NULL,
  "sku" text NOT NULL,
  "cantidad" numeric NOT NULL,
  "precio_venta_original" numeric NOT NULL,
  "precio_venta" numeric NOT NULL,
  "tipo_iva" text DEFAULT '10%'::text NOT NULL,
  "subtotal" numeric NOT NULL,
  "monto_iva" numeric NOT NULL,
  "total_linea" numeric NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "tipo_precio" text DEFAULT 'minorista'::text NOT NULL
);
CREATE TABLE "oymcomercial"."ventas_pagos_detalle" (
  "id" uuid DEFAULT extensions.gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "venta_id" uuid NOT NULL,
  "metodo_pago" text NOT NULL,
  "entidad_bancaria_id" uuid,
  "entidad_nombre_snapshot" text,
  "monto" numeric DEFAULT 0 NOT NULL,
  "referencia" text,
  "fecha_pago" timestamp with time zone DEFAULT now() NOT NULL,
  "fecha_acreditacion" date,
  "observacion" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "titular" text,
  "conciliacion_estado" text DEFAULT 'pendiente'::text NOT NULL,
  "conciliado_at" timestamp with time zone,
  "conciliado_por" text
);

-- ---------- FUNCIONES ----------
CREATE OR REPLACE FUNCTION oymcomercial._ensure_categoria(p_empresa uuid, p_nombre text, p_codigo text, p_parent uuid)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE v_id uuid;
BEGIN
  SELECT id INTO v_id FROM oymcomercial.categorias_productos
    WHERE empresa_id = p_empresa AND nombre = p_nombre;
  IF v_id IS NULL THEN
    INSERT INTO oymcomercial.categorias_productos (empresa_id, nombre, codigo, parent_id, activo)
    VALUES (p_empresa, p_nombre, p_codigo, p_parent, true)
    RETURNING id INTO v_id;
  ELSE
    UPDATE oymcomercial.categorias_productos
    SET parent_id = COALESCE(p_parent, parent_id), activo = true
    WHERE id = v_id;
  END IF;
  RETURN v_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial._touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial._upsert_producto_menu(p_empresa uuid, p_categoria uuid, p_sku text, p_nombre text, p_precio numeric, p_descripcion text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_id uuid;
BEGIN
  SELECT id INTO v_id FROM oymcomercial.productos WHERE empresa_id = p_empresa AND sku = p_sku;
  IF v_id IS NULL THEN
    INSERT INTO oymcomercial.productos (
      empresa_id, nombre, sku, descripcion,
      costo_promedio, precio_venta, stock_actual, stock_minimo,
      unidad_medida, metodo_valuacion, activo,
      categoria_principal_id,
      es_vendible, es_insumo, controla_stock, valorizado,
      tiempo_prep_minutos, factor_compra_receta
    ) VALUES (
      p_empresa, p_nombre, p_sku, p_descripcion,
      0, p_precio, 0, 0,
      'UNIDAD', 'CPP', true,
      p_categoria,
      true, false, false, false,
      0, 1
    ) RETURNING id INTO v_id;
  ELSE
    UPDATE oymcomercial.productos
    SET nombre = p_nombre, descripcion = p_descripcion, precio_venta = p_precio,
        es_vendible = true, es_insumo = false, controla_stock = false, valorizado = false,
        categoria_principal_id = p_categoria, unidad_medida = 'UNIDAD',
        activo = true, updated_at = now()
    WHERE id = v_id;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM oymcomercial.producto_categorias
    WHERE empresa_id = p_empresa AND producto_id = v_id AND categoria_id = p_categoria
  ) THEN
    INSERT INTO oymcomercial.producto_categorias (empresa_id, producto_id, categoria_id, es_principal)
    VALUES (p_empresa, v_id, p_categoria, true);
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial._upsert_producto_reventa(p_empresa uuid, p_categoria uuid, p_sku text, p_nombre text, p_precio numeric, p_descripcion text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_id uuid;
BEGIN
  SELECT id INTO v_id FROM oymcomercial.productos WHERE empresa_id = p_empresa AND sku = p_sku;
  IF v_id IS NULL THEN
    INSERT INTO oymcomercial.productos (
      empresa_id, nombre, sku, descripcion,
      costo_promedio, precio_venta, stock_actual, stock_minimo,
      unidad_medida, metodo_valuacion, activo,
      categoria_principal_id,
      es_vendible, es_insumo, controla_stock, valorizado,
      tiempo_prep_minutos, factor_compra_receta
    ) VALUES (
      p_empresa, p_nombre, p_sku, p_descripcion,
      0, p_precio, 0, 0,
      'UNIDAD', 'CPP', true,
      p_categoria,
      true, false, true, true,
      0, 1
    ) RETURNING id INTO v_id;
  ELSE
    UPDATE oymcomercial.productos
    SET nombre = p_nombre, descripcion = p_descripcion, precio_venta = p_precio,
        es_vendible = true, es_insumo = false, controla_stock = true, valorizado = true,
        categoria_principal_id = p_categoria, unidad_medida = 'UNIDAD',
        activo = true, updated_at = now()
    WHERE id = v_id;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM oymcomercial.producto_categorias
    WHERE empresa_id = p_empresa AND producto_id = v_id AND categoria_id = p_categoria
  ) THEN
    INSERT INTO oymcomercial.producto_categorias (empresa_id, producto_id, categoria_id, es_principal)
    VALUES (p_empresa, v_id, p_categoria, true);
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.empresa_id_actual()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'oymcomercial'
AS $function$
  SELECT empresa_id
  FROM oymcomercial.usuarios
  WHERE lower(trim(COALESCE(email, ''))) = oymcomercial.jwt_email_normalized()
  LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.es_super_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'oymcomercial'
AS $function$
  SELECT rol = 'super_admin'
  FROM oymcomercial.usuarios
  WHERE lower(trim(COALESCE(email, ''))) = oymcomercial.jwt_email_normalized()
  LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.fn_heredar_sucursal_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_suc uuid;
BEGIN
  -- Si ya viene informada, respetarla tal cual.
  IF NEW.sucursal_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  IF TG_TABLE_NAME = 'factura_electronica' THEN
    SELECT f.sucursal_id INTO v_suc FROM oymcomercial.facturas f WHERE f.id = NEW.factura_id;

  ELSIF TG_TABLE_NAME = 'sifen_jobs' THEN
    SELECT f.sucursal_id INTO v_suc FROM oymcomercial.facturas f WHERE f.id = NEW.factura_id;

  ELSIF TG_TABLE_NAME = 'movimientos_inventario' THEN
    SELECT p.sucursal_id INTO v_suc FROM oymcomercial.productos p WHERE p.id = NEW.producto_id;

  ELSIF TG_TABLE_NAME = 'producciones' THEN
    SELECT p.sucursal_id INTO v_suc FROM oymcomercial.productos p WHERE p.id = NEW.producto_id;

  ELSIF TG_TABLE_NAME = 'cobros_clientes' THEN
    SELECT c.sucursal_id INTO v_suc FROM oymcomercial.cuentas_por_cobrar c
     WHERE c.id = NEW.cuenta_por_cobrar_id;

  ELSIF TG_TABLE_NAME = 'recibos_dinero' THEN
    SELECT c.sucursal_id INTO v_suc FROM oymcomercial.cobros_clientes c
     WHERE c.id = NEW.cobro_cliente_id;
    IF v_suc IS NULL AND NEW.venta_id IS NOT NULL THEN
      SELECT v.sucursal_id INTO v_suc FROM oymcomercial.ventas v WHERE v.id = NEW.venta_id;
    END IF;
  END IF;

  -- Último recurso: si no hay padre resoluble, la sucursal principal de la
  -- empresa. Preferible a dejarla huérfana e invisible.
  IF v_suc IS NULL THEN
    SELECT s.id INTO v_suc FROM oymcomercial.sucursales s
     WHERE s.empresa_id = NEW.empresa_id AND s.es_principal LIMIT 1;
  END IF;

  NEW.sucursal_id := v_suc;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.fn_receta_costeo(p_receta_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'oymcomercial', 'public'
AS $function$
DECLARE
  v_costo_total       numeric := 0;
  v_precio_venta      numeric := 0;
  v_rendimiento       numeric := 1;
  v_unidades_posibles numeric;
  v_items             jsonb;
  v_producto_id       uuid;
BEGIN
  SELECT r.producto_id, COALESCE(r.rendimiento_cantidad, 1), COALESCE(p.precio_venta, 0)
    INTO v_producto_id, v_rendimiento, v_precio_venta
  FROM oymcomercial.recetas r
  JOIN oymcomercial.productos p ON p.id = r.producto_id
  WHERE r.id = p_receta_id;

  IF v_producto_id IS NULL THEN
    RETURN jsonb_build_object('error', 'receta_no_encontrada');
  END IF;

  WITH base AS (
    SELECT
      ri.id, ri.insumo_producto_id, pi.nombre AS insumo_nombre, ri.orden,
      ri.cantidad, ri.unidad_medida, COALESCE(ri.merma_pct, 0) AS merma_pct,
      pi.costo_promedio, pi.stock_actual,
      upper(trim(COALESCE(NULLIF(ri.unidad_medida, ''), pi.unidad_medida))) AS u_item,
      upper(trim(pi.unidad_medida)) AS u_ins
    FROM oymcomercial.receta_items ri
    JOIN oymcomercial.productos pi ON pi.id = ri.insumo_producto_id
    WHERE ri.receta_id = p_receta_id
  ),
  fam AS (
    SELECT b.*,
      CASE u_item WHEN 'G' THEN 1 WHEN 'GR' THEN 1 WHEN 'GRS' THEN 1 WHEN 'KG' THEN 1000
                  WHEN 'ML' THEN 1 WHEN 'L' THEN 1000 WHEN 'LT' THEN 1000 WHEN 'LTS' THEN 1000
                  WHEN 'UNIDAD' THEN 1 WHEN 'UNID' THEN 1 WHEN 'U' THEN 1 ELSE NULL END AS f_item,
      CASE u_ins  WHEN 'G' THEN 1 WHEN 'GR' THEN 1 WHEN 'GRS' THEN 1 WHEN 'KG' THEN 1000
                  WHEN 'ML' THEN 1 WHEN 'L' THEN 1000 WHEN 'LT' THEN 1000 WHEN 'LTS' THEN 1000
                  WHEN 'UNIDAD' THEN 1 WHEN 'UNID' THEN 1 WHEN 'U' THEN 1 ELSE NULL END AS f_ins,
      CASE
        WHEN u_item IN ('G','GR','GRS','KG') AND u_ins IN ('G','GR','GRS','KG') THEN true
        WHEN u_item IN ('ML','L','LT','LTS') AND u_ins IN ('ML','L','LT','LTS') THEN true
        WHEN u_item IN ('UNIDAD','UNID','U') AND u_ins IN ('UNIDAD','UNID','U') THEN true
        ELSE false
      END AS compat
    FROM base b
  ),
  item_calc AS (
    SELECT *,
      (CASE WHEN compat AND f_ins > 0 THEN cantidad * f_item / f_ins ELSE NULL END) AS cant_insumo,
      (CASE WHEN compat AND f_ins > 0 THEN (cantidad * f_item / f_ins) * (1 + merma_pct) ELSE NULL END) AS cantidad_efectiva,
      (CASE WHEN compat AND f_ins > 0 THEN (cantidad * f_item / f_ins) * (1 + merma_pct) * COALESCE(costo_promedio, 0) ELSE 0 END) AS subcosto,
      (CASE WHEN compat AND f_ins > 0 AND (cantidad * f_item / f_ins) * (1 + merma_pct) > 0
            THEN FLOOR(COALESCE(stock_actual, 0) / ((cantidad * f_item / f_ins) * (1 + merma_pct)))
            ELSE NULL END) AS unidades_aporte,
      (NOT compat) AS unidad_incompatible
    FROM fam
  )
  SELECT
    COALESCE(SUM(subcosto), 0),
    COALESCE(MIN(unidades_aporte), 0),
    COALESCE(jsonb_agg(jsonb_build_object(
      'item_id', id,
      'insumo_producto_id', insumo_producto_id,
      'insumo_nombre', insumo_nombre,
      'cantidad', cantidad,
      'unidad_medida', unidad_medida,
      'merma_pct', merma_pct,
      'costo_promedio', costo_promedio,
      'stock_actual', stock_actual,
      'subcosto', subcosto,
      'unidades_aporte', unidades_aporte,
      'unidad_incompatible', unidad_incompatible
    ) ORDER BY orden, insumo_nombre), '[]'::jsonb)
    INTO v_costo_total, v_unidades_posibles, v_items
  FROM item_calc;

  IF NOT EXISTS (SELECT 1 FROM oymcomercial.receta_items WHERE receta_id = p_receta_id) THEN
    v_unidades_posibles := NULL;
  END IF;

  RETURN jsonb_build_object(
    'receta_id', p_receta_id,
    'producto_id', v_producto_id,
    'rendimiento_cantidad', v_rendimiento,
    'costo_total', v_costo_total,
    'costo_unitario', CASE WHEN v_rendimiento > 0 THEN v_costo_total / v_rendimiento ELSE NULL END,
    'precio_venta', v_precio_venta,
    'margen_abs', v_precio_venta - (CASE WHEN v_rendimiento > 0 THEN v_costo_total / v_rendimiento ELSE 0 END),
    'margen_pct', CASE
      WHEN v_precio_venta > 0 AND v_rendimiento > 0
      THEN ROUND(((v_precio_venta - (v_costo_total / v_rendimiento)) / v_precio_venta * 100)::numeric, 2)
      ELSE NULL
    END,
    'unidades_posibles', v_unidades_posibles,
    'items', v_items
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.incrementar_secuencia_producto(p_empresa_id uuid)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
      DECLARE v bigint;
      BEGIN
        INSERT INTO oymcomercial.productos_codigo_secuencia (empresa_id, last_value)
        VALUES (p_empresa_id, 1)
        ON CONFLICT (empresa_id) DO UPDATE
          SET last_value = oymcomercial.productos_codigo_secuencia.last_value + 1,
              updated_at = now()
        RETURNING last_value INTO v;
        RETURN v;
      END;
      $function$
;

CREATE OR REPLACE FUNCTION oymcomercial.jwt_email_normalized()
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'oymcomercial'
AS $function$
  SELECT lower(trim(COALESCE(auth.jwt() ->> 'email', '')));
$function$
;

-- [EXCLUIDA] neura_clone_omnicanal_schema (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_clone_zentra_erp_to_tenant (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_enlodemari_block_other_empresas (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_fix_foreign_keys_retarget_from_public (tooling de plataforma; referencia otros schemas)
CREATE OR REPLACE FUNCTION oymcomercial.neura_inbox_awaiting_reply_since_batch(p_schema text, p_empresa_id uuid, p_conversation_ids uuid[])
 RETURNS TABLE(conversation_id uuid, awaiting_since timestamp with time zone, client_turn_since timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  sch text := trim(both from coalesce(p_schema, ''));
BEGIN
  IF sch IS NULL OR sch = '' OR sch !~ '^(zentra_erp|public|er_[0-9a-f]{32}|erp_[a-z0-9_]+)$' THEN
    RAISE EXCEPTION 'schema no permitido: %', p_schema;
  END IF;

  RETURN QUERY EXECUTE format(
    $q$
    WITH conv AS (SELECT unnest($1::uuid[]) AS id),
    last_contact AS (
      SELECT DISTINCT ON (m.conversation_id)
        m.conversation_id,
        m.created_at AS at
      FROM %I.chat_messages m
      INNER JOIN conv c ON c.id = m.conversation_id
      WHERE m.empresa_id = $2::uuid
        AND m.from_me = false
        AND lower(coalesce(m.sender_type, 'contact')) IN ('contact')
      ORDER BY m.conversation_id, m.created_at DESC
    ),
    last_human AS (
      SELECT m.conversation_id, max(m.created_at) AS at
      FROM %I.chat_messages m
      INNER JOIN conv c ON c.id = m.conversation_id
      WHERE m.empresa_id = $2::uuid
        AND m.from_me = true
        AND lower(coalesce(m.sender_type, '')) = 'human'
      GROUP BY m.conversation_id
    ),
    last_global AS (
      SELECT DISTINCT ON (m.conversation_id)
        m.conversation_id,
        m.from_me,
        m.created_at AS at
      FROM %I.chat_messages m
      INNER JOIN conv c ON c.id = m.conversation_id
      WHERE m.empresa_id = $2::uuid
      ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT
      conv.id AS conversation_id,
      CASE
        WHEN lc.at IS NOT NULL AND lc.at > coalesce(lh.at, '-infinity'::timestamptz) THEN lc.at
        ELSE NULL::timestamptz
      END AS awaiting_since,
      CASE
        WHEN lc.at IS NOT NULL AND lc.at > coalesce(lh.at, '-infinity'::timestamptz) THEN NULL::timestamptz
        WHEN lg.from_me IS TRUE THEN lg.at
        ELSE NULL::timestamptz
      END AS client_turn_since
    FROM conv
    LEFT JOIN last_contact lc ON lc.conversation_id = conv.id
    LEFT JOIN last_human lh ON lh.conversation_id = conv.id
    LEFT JOIN last_global lg ON lg.conversation_id = conv.id
    $q$,
    sch
  )
  USING p_conversation_ids, p_empresa_id;
END;
$function$
;

-- [EXCLUIDA] neura_install_nota_credito_tables (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_provision_empresa_data_schema (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_teardown_provision_failed (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_upgrade_factura_correlativo (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_upgrade_factura_estado_corregida_nc (tooling de plataforma; referencia otros schemas)
-- [EXCLUIDA] neura_upgrade_nota_credito_fase2 (tooling de plataforma; referencia otros schemas)
CREATE OR REPLACE FUNCTION oymcomercial.next_numero_factura_empresa(p_empresa_id uuid, p_prefijo_default text DEFAULT 'FAC-'::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
    DECLARE
      v_prefijo text;
      v_num bigint;
      v_ancho int := 6;
    BEGIN
      IF p_empresa_id IS NULL THEN
        RAISE EXCEPTION 'next_numero_factura_empresa: empresa_id es obligatorio';
      END IF;

      -- Inicializa contador si no existe (toma max numérico real de facturas de la empresa).
      IF NOT EXISTS (
        SELECT 1 FROM oymcomercial.factura_correlativos c WHERE c.empresa_id = p_empresa_id
      ) THEN
        SELECT
          COALESCE(
            (
              SELECT NULLIF(regexp_replace(f.numero_factura, '([0-9]+)$', ''), '')
              FROM oymcomercial.facturas f
              WHERE f.empresa_id = p_empresa_id
                AND f.numero_factura ~ '[0-9]+$'
              ORDER BY COALESCE(f.created_at, f.updated_at) DESC NULLS LAST, f.id DESC
              LIMIT 1
            ),
            NULLIF(btrim(p_prefijo_default), ''),
            'FAC-'
          ),
          COALESCE(
            (
              SELECT max((regexp_match(f.numero_factura, '([0-9]+)$'))[1]::bigint)
              FROM oymcomercial.facturas f
              WHERE f.empresa_id = p_empresa_id
                AND f.numero_factura ~ '[0-9]+$'
            ),
            0
          )
        INTO v_prefijo, v_num;

        INSERT INTO oymcomercial.factura_correlativos(empresa_id, prefijo, ultimo_numero)
        VALUES (p_empresa_id, v_prefijo, v_num)
        ON CONFLICT (empresa_id) DO NOTHING;
      END IF;

      UPDATE oymcomercial.factura_correlativos c
      SET
        prefijo = COALESCE(NULLIF(btrim(p_prefijo_default), ''), c.prefijo, 'FAC-'),
        ultimo_numero = c.ultimo_numero + 1,
        updated_at = now()
      WHERE c.empresa_id = p_empresa_id
      RETURNING c.prefijo, c.ultimo_numero
      INTO v_prefijo, v_num;

      IF v_num IS NULL THEN
        RAISE EXCEPTION 'No se pudo reservar correlativo de factura';
      END IF;

      RETURN COALESCE(v_prefijo, 'FAC-') || lpad(v_num::text, v_ancho, '0');
    END;
    $function$
;

CREATE OR REPLACE FUNCTION oymcomercial.nota_credito_aplicar_aprobacion_set(p_data_schema text, p_nota_credito_id uuid, p_factura_id uuid, p_empresa_id uuid, p_monto numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_temp'
AS $function$
DECLARE
  s  text := btrim(p_data_schema);
  fq text := quote_ident(btrim(p_data_schema));
  saldo_act    numeric;
  monto_fact   numeric;
  nc_aprobadas numeric;
  acreditable  numeric;
  total_nc     numeric;
BEGIN
  IF s IS NULL OR s = '' THEN
    RAISE EXCEPTION 'nota_credito_aplicar_aprobacion_set: schema vacío';
  END IF;

  EXECUTE format(
    'SELECT saldo, monto FROM %s.facturas WHERE id = $1 AND empresa_id = $2 FOR UPDATE',
    fq
  ) INTO saldo_act, monto_fact USING p_factura_id, p_empresa_id;

  IF saldo_act IS NULL THEN
    RAISE EXCEPTION 'Factura no encontrada';
  END IF;

  -- NC ya aprobadas de esta factura (excluye la que estamos aprobando ahora).
  EXECUTE format(
    'SELECT COALESCE(SUM(monto), 0) FROM %s.nota_credito
      WHERE factura_id = $1 AND empresa_id = $2
        AND estado_erp = ''aprobada'' AND id <> $3',
    fq
  ) INTO nc_aprobadas USING p_factura_id, p_empresa_id, p_nota_credito_id;

  -- Tope por MONTO facturado (no por saldo): es lo que habilita contado/pagadas.
  acreditable := GREATEST(0::numeric, COALESCE(monto_fact, 0) - COALESCE(nc_aprobadas, 0));
  IF p_monto > acreditable + 0.02 THEN
    RAISE EXCEPTION
      'El monto de la NC (%) supera el importe acreditable de la factura (%)',
      p_monto, acreditable;
  END IF;

  total_nc := COALESCE(nc_aprobadas, 0) + p_monto;

  EXECUTE format(
    'UPDATE %s.facturas SET
       saldo = GREATEST(0::numeric, saldo - $1),
       estado = CASE
         WHEN estado = ''Anulado'' THEN ''Anulado''
         -- Acreditada por completo (contado o crédito).
         WHEN $4 >= $5 - 0.02 THEN ''Corregida NC''
         -- Compat crédito: tenía saldo pendiente y esta NC lo deja en 0.
         WHEN $6 > 0.0001 AND GREATEST(0::numeric, $6 - $1) <= 0.0001 THEN ''Corregida NC''
         ELSE estado
       END,
       updated_at = now()
     WHERE id = $2 AND empresa_id = $3',
    fq
  ) USING p_monto, p_factura_id, p_empresa_id, total_nc, COALESCE(monto_fact, 0), saldo_act;

  EXECUTE format(
    'UPDATE %s.nota_credito SET estado_erp = ''aprobada'', updated_at = now()
     WHERE id = $1 AND empresa_id = $2 AND estado_erp <> ''anulada_borrador''',
    fq
  ) USING p_nota_credito_id, p_empresa_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.nota_credito_aplicar_cancelacion_set(p_data_schema text, p_nota_credito_id uuid, p_ne_id uuid, p_factura_id uuid, p_empresa_id uuid, p_motivo text, p_cancelado_at timestamp with time zone)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_temp'
AS $function$
DECLARE
  s  text := btrim(p_data_schema);
  fq text := quote_ident(btrim(p_data_schema));
  estado_nc     text;
  tipo_fact     text;
  monto_fact    numeric;
  estado_fact   text;
  suma_pagos    numeric;
  nc_restantes  numeric;
  saldo_nuevo   numeric;
  estado_nuevo  text;
BEGIN
  IF s IS NULL OR s = '' THEN
    RAISE EXCEPTION 'nota_credito_aplicar_cancelacion_set: schema vacío';
  END IF;

  -- Solo se cancela una NC efectivamente aprobada. Idempotente si ya está cancelada.
  EXECUTE format(
    'SELECT estado_erp FROM %s.nota_credito WHERE id = $1 AND empresa_id = $2 FOR UPDATE',
    fq
  ) INTO estado_nc USING p_nota_credito_id, p_empresa_id;

  IF estado_nc IS NULL THEN
    RAISE EXCEPTION 'Nota de crédito no encontrada';
  END IF;
  IF estado_nc = 'cancelada' THEN
    RETURN;
  END IF;
  IF estado_nc <> 'aprobada' THEN
    RAISE EXCEPTION 'Solo se puede cancelar una nota de crédito aprobada (estado actual: %)', estado_nc;
  END IF;

  EXECUTE format(
    'SELECT tipo, monto, estado FROM %s.facturas WHERE id = $1 AND empresa_id = $2 FOR UPDATE',
    fq
  ) INTO tipo_fact, monto_fact, estado_fact USING p_factura_id, p_empresa_id;

  IF monto_fact IS NULL THEN
    RAISE EXCEPTION 'Factura no encontrada';
  END IF;

  -- Marcar la NC como cancelada ANTES de recalcular, para que no se cuente.
  EXECUTE format(
    'UPDATE %s.nota_credito SET estado_erp = ''cancelada'', updated_at = now()
      WHERE id = $1 AND empresa_id = $2',
    fq
  ) USING p_nota_credito_id, p_empresa_id;

  EXECUTE format(
    'UPDATE %s.nota_credito_electronica SET
       estado_sifen = ''cancelado'',
       sifen_cancelado_at = $1,
       sifen_cancelacion_motivo = $2,
       updated_at = now()
     WHERE id = $3 AND empresa_id = $4',
    fq
  ) USING p_cancelado_at, p_motivo, p_ne_id, p_empresa_id;

  EXECUTE format(
    'SELECT COALESCE(SUM(monto), 0) FROM %s.pagos WHERE factura_id = $1 AND empresa_id = $2',
    fq
  ) INTO suma_pagos USING p_factura_id, p_empresa_id;

  EXECUTE format(
    'SELECT COALESCE(SUM(monto), 0) FROM %s.nota_credito
      WHERE factura_id = $1 AND empresa_id = $2 AND estado_erp = ''aprobada''',
    fq
  ) INTO nc_restantes USING p_factura_id, p_empresa_id;

  -- Recalcular saldo desde la verdad (ver cabecera: NO sumar el monto de vuelta).
  IF lower(COALESCE(tipo_fact, '')) = 'contado' THEN
    saldo_nuevo := 0;
  ELSE
    saldo_nuevo := GREATEST(0::numeric,
      COALESCE(monto_fact, 0) - COALESCE(suma_pagos, 0) - COALESCE(nc_restantes, 0));
  END IF;

  IF estado_fact = 'Anulado' THEN
    estado_nuevo := 'Anulado';
  ELSIF COALESCE(nc_restantes, 0) >= COALESCE(monto_fact, 0) - 0.02 THEN
    estado_nuevo := 'Corregida NC';
  ELSIF saldo_nuevo <= 0.0001 THEN
    estado_nuevo := 'Pagado';
  ELSE
    estado_nuevo := 'Pendiente';
  END IF;

  EXECUTE format(
    'UPDATE %s.facturas SET saldo = $1, estado = $2, updated_at = now()
      WHERE id = $3 AND empresa_id = $4',
    fq
  ) USING saldo_nuevo, estado_nuevo, p_factura_id, p_empresa_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.nota_credito_tras_aprobacion_set_transaccional(p_data_schema text, p_ne_id uuid, p_nc_id uuid, p_factura_id uuid, p_empresa_id uuid, p_monto numeric, p_ultima_consulta jsonb, p_sifen_aprobado_at timestamp with time zone)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_temp'
AS $function$
DECLARE
  sch text := btrim(p_data_schema);
  prev_ne text;
BEGIN
  IF sch IS NULL OR sch = '' THEN
    RAISE EXCEPTION 'nota_credito_tras_aprobacion_set_transaccional: schema vacío';
  END IF;

  EXECUTE format(
    'SELECT estado_sifen::text FROM %I.nota_credito_electronica WHERE id = $1 AND empresa_id = $2 FOR UPDATE',
    sch
  ) INTO prev_ne USING p_ne_id, p_empresa_id;

  IF prev_ne IS NULL THEN
    RAISE EXCEPTION 'nota_credito_electronica no encontrada';
  END IF;
  IF prev_ne = 'aprobado' THEN
    RETURN;
  END IF;

  EXECUTE format(
    'UPDATE %I.nota_credito_electronica SET
       estado_sifen = ''aprobado'',
       sifen_aprobado_at = $1,
       sifen_ultima_respuesta_consulta_lote = $2,
       last_response_json = $2,
       last_error = NULL,
       error = NULL,
       updated_at = now()
     WHERE id = $3 AND empresa_id = $4 AND estado_sifen <> ''aprobado''',
    sch
  ) USING p_sifen_aprobado_at, p_ultima_consulta, p_ne_id, p_empresa_id;

  PERFORM oymcomercial.nota_credito_aplicar_aprobacion_set(
    sch,
    p_nc_id,
    p_factura_id,
    p_empresa_id,
    p_monto
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.puede_acceder_empresa(empresa_uuid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT oymcomercial.es_super_admin()
     OR empresa_uuid = oymcomercial.empresa_id_actual();
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.set_chat_contact_phone_normalized()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.phone_normalized := NULLIF(regexp_replace(COALESCE(NEW.phone_number, ''), '\D', '', 'g'), '');
  IF NEW.phone_normalized IS NOT NULL THEN
    NEW.phone_number := NEW.phone_normalized;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.set_crm_prospectos_updated()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  NEW.fecha_actualizacion = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.sorteos_ensure_order_from_chat(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_empresa_id          uuid := (p->>'empresa_id')::uuid;
  v_sorteo_id           uuid := (p->>'sorteo_id')::uuid;
  v_conv_id             uuid := (p->>'chat_conversation_id')::uuid;
  v_flow_code           text := nullif(trim(p->>'flow_code'), '');
  v_idem                text := nullif(trim(p->>'idempotency_key'), '');
  v_wa                  text := trim(p->>'whatsapp_numero');
  v_nombre              text := trim(p->>'nombre_completo');
  v_cedula              text := nullif(trim(p->>'cedula'), '');
  v_ciudad              text := nullif(trim(p->>'ciudad'), '');
  v_qty                 int := coalesce((p->>'cantidad_boletos')::int, 0);
  v_comp_url            text := nullif(trim(p->>'comprobante_url'), '');
  v_validado_por        text := coalesce(nullif(trim(p->>'validado_por'), ''), 'chat_flow');

  v_monto_explicit      numeric := NULL;
  v_promo_nombre        text := nullif(trim(p->>'promo_nombre'), '');
  v_precio_regular_ref  numeric := NULL;

  v_revendedor_id       uuid := NULL;
  v_codigo_ref_snap     text := NULL;

  s                     record;
  v_entrada_id          uuid;
  v_numero_orden        int;
  v_cliente_id          uuid;
  v_monto_total         numeric;
  v_precio_fuente_ins   text;
  v_lista_calc          numeric;
  i                     int;
  v_num                 int;
  v_num_str             text;
  v_existing            record;
  v_cant_existente      int;
  v_mt_existente        numeric;
  v_promo_existente     text;
  v_pf_existente        text;
BEGIN
  IF v_empresa_id IS NULL OR v_sorteo_id IS NULL OR v_conv_id IS NULL OR v_idem IS NULL OR v_idem = '' THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Faltan empresa_id, sorteo_id, chat_conversation_id o idempotency_key');
  END IF;
  IF v_wa = '' OR v_nombre = '' THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Faltan whatsapp_numero o nombre_completo');
  END IF;
  IF v_qty < 1 THEN
    RETURN jsonb_build_object('ok', false, 'message', 'cantidad_boletos debe ser mayor a 0');
  END IF;

  IF p ? 'monto_compra' THEN
    BEGIN
      v_monto_explicit := NULLIF(trim(p->>'monto_compra'), '')::numeric;
    EXCEPTION WHEN OTHERS THEN
      v_monto_explicit := NULL;
    END;
  END IF;
  IF v_monto_explicit IS NOT NULL AND v_monto_explicit <= 0 THEN
    v_monto_explicit := NULL;
  END IF;

  IF p ? 'precio_regular_referencia' THEN
    BEGIN
      v_precio_regular_ref := NULLIF(trim(p->>'precio_regular_referencia'), '')::numeric;
    EXCEPTION WHEN OTHERS THEN
      v_precio_regular_ref := NULL;
    END;
  END IF;
  IF v_precio_regular_ref IS NOT NULL AND v_precio_regular_ref <= 0 THEN
    v_precio_regular_ref := NULL;
  END IF;

  v_codigo_ref_snap := nullif(trim(p->>'codigo_referido'), '');
  IF p ? 'revendedor_id' AND nullif(trim(p->>'revendedor_id'), '') IS NOT NULL THEN
    BEGIN
      v_revendedor_id := (p->>'revendedor_id')::uuid;
    EXCEPTION WHEN OTHERS THEN
      v_revendedor_id := NULL;
    END;
  END IF;

  SELECT e.id, e.numero_orden, e.estado_pago
  INTO v_existing
  FROM oymcomercial.sorteo_entradas e
  WHERE e.idempotency_key = v_idem
  LIMIT 1;

  IF FOUND THEN
    SELECT
      e.cantidad_boletos,
      e.monto_total,
      e.promo_nombre,
      e.precio_fuente
    INTO v_cant_existente, v_mt_existente, v_promo_existente, v_pf_existente
    FROM oymcomercial.sorteo_entradas e
    WHERE e.id = (v_existing).id;

    RETURN jsonb_build_object(
      'ok', true,
      'idempotent', true,
      'message', 'Orden ya existía (idempotencia)',
      'entrada', jsonb_build_object(
        'id', (v_existing).id,
        'numero_orden', (v_existing).numero_orden,
        'cantidad_boletos', coalesce(v_cant_existente, v_qty),
        'monto_total', v_mt_existente,
        'promo_nombre', coalesce(v_promo_existente, ''),
        'precio_fuente', coalesce(v_pf_existente, 'lista'),
        'estado_pago', (v_existing).estado_pago
      ),
      'cupones', (
        SELECT coalesce(jsonb_agg(
          jsonb_build_object('id', c.id, 'numero_cupon', c.numero_cupon)
          ORDER BY c.numero_cupon
        ), '[]'::jsonb)
        FROM oymcomercial.sorteo_cupones c
        WHERE c.entrada_id = (v_existing).id
      )
    );
  END IF;

  SELECT * INTO s FROM oymcomercial.sorteos WHERE id = v_sorteo_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Sorteo no encontrado');
  END IF;
  IF s.empresa_id IS DISTINCT FROM v_empresa_id THEN
    RETURN jsonb_build_object('ok', false, 'message', 'El sorteo no pertenece a la empresa indicada');
  END IF;
  IF s.estado IS DISTINCT FROM 'activo' THEN
    RETURN jsonb_build_object('ok', false, 'message', 'El sorteo no está activo');
  END IF;
  IF s.total_boletos_vendidos + v_qty > s.max_boletos THEN
    RETURN jsonb_build_object('ok', false, 'message', 'No hay boletos disponibles para esta cantidad');
  END IF;

  v_lista_calc := s.precio_por_boleto * v_qty;

  IF v_monto_explicit IS NOT NULL THEN
    v_monto_total := v_monto_explicit;
    v_precio_fuente_ins := 'promo';
    IF v_precio_regular_ref IS NULL THEN
      v_precio_regular_ref := v_lista_calc;
    END IF;
  ELSE
    v_monto_total := v_lista_calc;
    v_precio_fuente_ins := 'lista';
    v_precio_regular_ref := NULL;
  END IF;

  SELECT id INTO v_cliente_id
  FROM oymcomercial.clientes
  WHERE empresa_id = v_empresa_id
    AND deleted_at IS NULL
    AND (
      (v_cedula IS NOT NULL AND documento IS NOT NULL AND trim(documento) = v_cedula)
      OR (trim(telefono) = v_wa)
    )
  LIMIT 1;

  IF v_cliente_id IS NULL THEN
    INSERT INTO oymcomercial.clientes (
      empresa_id, tipo_cliente, nombre_contacto, nombre, documento, telefono, ciudad, origen
    ) VALUES (
      v_empresa_id, 'persona', v_nombre, v_nombre, v_cedula, v_wa, v_ciudad, 'SORTEO_CHAT'
    )
    RETURNING id INTO v_cliente_id;
  END IF;

  v_numero_orden := s.ultimo_numero_orden + 1;

  IF v_revendedor_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM oymcomercial.sorteo_revendedores r
      WHERE r.id = v_revendedor_id
        AND r.empresa_id = v_empresa_id
        AND r.sorteo_id = v_sorteo_id
        AND r.activo = true
    ) THEN
      v_revendedor_id := NULL;
      v_codigo_ref_snap := NULL;
    END IF;
  ELSE
    v_codigo_ref_snap := NULL;
  END IF;

  INSERT INTO oymcomercial.sorteo_entradas (
    empresa_id,
    sorteo_id,
    conversacion_id,
    cliente_id,
    whatsapp_numero,
    nombre_participante,
    documento,
    cantidad_boletos,
    monto_total,
    moneda,
    estado_pago,
    comprobante_url,
    validado_por,
    numero_orden,
    chat_conversation_id,
    flow_code,
    idempotency_key,
    promo_nombre,
    precio_fuente,
    precio_regular_referencia,
    revendedor_id,
    codigo_referido_snapshot
  ) VALUES (
    v_empresa_id,
    v_sorteo_id,
    NULL,
    v_cliente_id,
    v_wa,
    v_nombre,
    v_cedula,
    v_qty,
    v_monto_total,
    'PYG',
    'pendiente_revision',
    v_comp_url,
    v_validado_por,
    v_numero_orden,
    v_conv_id,
    v_flow_code,
    v_idem,
    v_promo_nombre,
    v_precio_fuente_ins,
    v_precio_regular_ref,
    v_revendedor_id,
    v_codigo_ref_snap
  )
  RETURNING id INTO v_entrada_id;

  FOR i IN 1..v_qty LOOP
    v_num := s.ultimo_numero_cupon + i;
    v_num_str := lpad(v_num::text, 4, '0');
    INSERT INTO oymcomercial.sorteo_cupones (empresa_id, sorteo_id, entrada_id, numero_cupon)
    VALUES (v_empresa_id, v_sorteo_id, v_entrada_id, v_num_str);
  END LOOP;

  UPDATE oymcomercial.sorteos SET
    total_boletos_vendidos = total_boletos_vendidos + v_qty,
    ultimo_numero_cupon = s.ultimo_numero_cupon + v_qty,
    ultimo_numero_orden = v_numero_orden,
    updated_at = now()
  WHERE id = v_sorteo_id;

  RETURN jsonb_build_object(
    'ok', true,
    'idempotent', false,
    'message', 'Orden y cupones creados',
    'entrada', jsonb_build_object(
      'id', v_entrada_id,
      'numero_orden', v_numero_orden,
      'cantidad_boletos', v_qty,
      'monto_total', v_monto_total,
      'promo_nombre', coalesce(v_promo_nombre, ''),
      'precio_fuente', v_precio_fuente_ins,
      'estado_pago', 'pendiente_revision'
    ),
    'cupones', (
      SELECT coalesce(jsonb_agg(
        jsonb_build_object('id', c.id, 'numero_cupon', c.numero_cupon)
        ORDER BY c.numero_cupon
      ), '[]'::jsonb)
      FROM oymcomercial.sorteo_cupones c
      WHERE c.entrada_id = v_entrada_id
    )
  );

EXCEPTION
  WHEN unique_violation THEN
    SELECT e.id, e.numero_orden, e.estado_pago
    INTO v_existing
    FROM oymcomercial.sorteo_entradas e
    WHERE e.idempotency_key = v_idem
    LIMIT 1;
    IF FOUND THEN
      SELECT
        e.cantidad_boletos,
        e.monto_total,
        e.promo_nombre,
        e.precio_fuente
      INTO v_cant_existente, v_mt_existente, v_promo_existente, v_pf_existente
      FROM oymcomercial.sorteo_entradas e
      WHERE e.id = (v_existing).id;
      RETURN jsonb_build_object(
        'ok', true,
        'idempotent', true,
        'message', 'Orden ya existía (carrera concurrente)',
        'entrada', jsonb_build_object(
          'id', (v_existing).id,
          'numero_orden', (v_existing).numero_orden,
          'cantidad_boletos', coalesce(v_cant_existente, v_qty),
          'monto_total', v_mt_existente,
          'promo_nombre', coalesce(v_promo_existente, ''),
          'precio_fuente', coalesce(v_pf_existente, 'lista'),
          'estado_pago', (v_existing).estado_pago
        ),
        'cupones', (
          SELECT coalesce(jsonb_agg(
            jsonb_build_object('id', c.id, 'numero_cupon', c.numero_cupon)
            ORDER BY c.numero_cupon
          ), '[]'::jsonb)
          FROM oymcomercial.sorteo_cupones c
          WHERE c.entrada_id = (v_existing).id
        )
      );
    END IF;
    RETURN jsonb_build_object('ok', false, 'message', 'Error de unicidad al crear orden');
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.sorteos_registrar_compra_n8n(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_empresa_id       uuid := (p->>'empresa_id')::uuid;
  v_sorteo_id        uuid := (p->>'sorteo_id')::uuid;
  v_wa               text := trim(p->>'whatsapp_numero');
  v_nombre           text := trim(p->>'nombre_completo');
  v_cedula           text := nullif(trim(p->>'cedula'), '');
  v_celular          text := nullif(trim(p->>'celular'), '');
  v_ciudad           text := nullif(trim(p->>'ciudad'), '');
  v_qty              int := coalesce((p->>'cantidad_boletos')::int, 0);
  v_fecha_pago       timestamptz := nullif(p->>'fecha_pago', '')::timestamptz;
  v_monto_pago       numeric := coalesce((p->>'monto_pago')::numeric, 0);
  v_banco            text := nullif(trim(p->>'banco_origen'), '');
  v_comp_url         text := p->>'comprobante_url';
  v_ultimo_msg       text := p->>'ultimo_mensaje';

  s                  record;
  v_cliente_id       uuid;
  v_conv_id          uuid;
  v_entrada_id       uuid;
  v_monto_total      numeric;
  i                  int;
  v_num              int;
  v_num_str          text;
BEGIN
  IF v_empresa_id IS NULL OR v_sorteo_id IS NULL OR v_wa = '' OR v_nombre = '' THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Faltan datos obligatorios (empresa_id, sorteo_id, whatsapp_numero, nombre_completo)');
  END IF;
  IF v_qty < 1 THEN
    RETURN jsonb_build_object('ok', false, 'message', 'cantidad_boletos debe ser mayor a 0');
  END IF;

  SELECT * INTO s FROM oymcomercial.sorteos WHERE id = v_sorteo_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Sorteo no encontrado');
  END IF;
  IF s.empresa_id IS DISTINCT FROM v_empresa_id THEN
    RETURN jsonb_build_object('ok', false, 'message', 'El sorteo no pertenece a la empresa indicada');
  END IF;
  IF s.estado IS DISTINCT FROM 'activo' THEN
    RETURN jsonb_build_object('ok', false, 'message', 'El sorteo no está activo');
  END IF;
  IF s.total_boletos_vendidos + v_qty > s.max_boletos THEN
    RETURN jsonb_build_object('ok', false, 'message', 'No hay boletos disponibles para esta cantidad');
  END IF;

  v_monto_total := s.precio_por_boleto * v_qty;

  -- Cliente: por documento o teléfono en la empresa
  SELECT id INTO v_cliente_id
  FROM oymcomercial.clientes
  WHERE empresa_id = v_empresa_id
    AND deleted_at IS NULL
    AND (
      (v_cedula IS NOT NULL AND documento IS NOT NULL AND trim(documento) = v_cedula)
      OR (v_celular IS NOT NULL AND telefono IS NOT NULL AND trim(telefono) = v_celular)
    )
  LIMIT 1;

  IF v_cliente_id IS NULL THEN
    INSERT INTO oymcomercial.clientes (
      empresa_id, tipo_cliente, nombre_contacto, nombre, documento, telefono, ciudad, origen
    ) VALUES (
      v_empresa_id, 'persona', v_nombre, v_nombre, v_cedula, coalesce(v_celular, v_wa), v_ciudad, 'SORTEO'
    )
    RETURNING id INTO v_cliente_id;
  END IF;

  SELECT id INTO v_conv_id
  FROM oymcomercial.sorteo_conversaciones
  WHERE sorteo_id = v_sorteo_id AND whatsapp_numero = v_wa AND activa = true
  LIMIT 1;

  IF v_conv_id IS NULL THEN
    INSERT INTO oymcomercial.sorteo_conversaciones (
      empresa_id, sorteo_id, whatsapp_numero, cliente_id, estado, ultimo_mensaje, cantidad_boletos, datos_cliente
    ) VALUES (
      v_empresa_id, v_sorteo_id, v_wa, v_cliente_id, 'paid_confirmed', v_ultimo_msg, v_qty,
      jsonb_build_object('nombre_completo', v_nombre, 'cedula', v_cedula, 'celular', v_celular, 'ciudad', v_ciudad)
    )
    RETURNING id INTO v_conv_id;
  ELSE
    UPDATE oymcomercial.sorteo_conversaciones SET
      cliente_id = coalesce(v_cliente_id, cliente_id),
      estado = 'paid_confirmed',
      ultimo_mensaje = coalesce(v_ultimo_msg, ultimo_mensaje),
      cantidad_boletos = v_qty,
      datos_cliente = coalesce(datos_cliente, '{}'::jsonb) || jsonb_build_object(
        'nombre_completo', v_nombre, 'cedula', v_cedula, 'celular', v_celular, 'ciudad', v_ciudad
      ),
      updated_at = now()
    WHERE id = v_conv_id;
  END IF;

  INSERT INTO oymcomercial.sorteo_entradas (
    empresa_id, sorteo_id, conversacion_id, cliente_id, whatsapp_numero, nombre_participante, documento,
    cantidad_boletos, monto_total, moneda, estado_pago, fecha_pago, monto_pagado, banco_origen, comprobante_url, validado_por
  ) VALUES (
    v_empresa_id, v_sorteo_id, v_conv_id, v_cliente_id, v_wa, v_nombre, v_cedula,
    v_qty, v_monto_total, 'PYG', 'confirmado', v_fecha_pago, v_monto_pago, v_banco, v_comp_url, 'n8n'
  )
  RETURNING id INTO v_entrada_id;

  FOR i IN 1..v_qty LOOP
    v_num := s.ultimo_numero_cupon + i;
    v_num_str := lpad(v_num::text, 4, '0');
    INSERT INTO oymcomercial.sorteo_cupones (empresa_id, sorteo_id, entrada_id, numero_cupon)
    VALUES (v_empresa_id, v_sorteo_id, v_entrada_id, v_num_str);
  END LOOP;

  UPDATE oymcomercial.sorteos SET
    total_boletos_vendidos = total_boletos_vendidos + v_qty,
    ultimo_numero_cupon = s.ultimo_numero_cupon + v_qty,
    updated_at = now()
  WHERE id = v_sorteo_id;

  RETURN jsonb_build_object(
    'ok', true,
    'message', 'Compra registrada correctamente',
    'cliente', jsonb_build_object('id', v_cliente_id, 'nombre', v_nombre),
    'conversacion', jsonb_build_object('id', v_conv_id, 'estado', 'paid_confirmed'),
    'entrada', jsonb_build_object(
      'id', v_entrada_id,
      'cantidad_boletos', v_qty,
      'monto_total', v_monto_total,
      'estado_pago', 'confirmado'
    ),
    'cupones', (
      SELECT coalesce(jsonb_agg(
        jsonb_build_object('id', c.id, 'numero_cupon', c.numero_cupon)
        ORDER BY c.numero_cupon
      ), '[]'::jsonb)
      FROM oymcomercial.sorteo_cupones c
      WHERE c.entrada_id = v_entrada_id
    )
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.trg_clientes_tipo_servicio_requiere_catalogo()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  sch   text := TG_TABLE_SCHEMA;
  tslug text;
  ok    boolean;
BEGIN
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.empresa_id IS NOT NULL THEN
    tslug := NEW.tipo_servicio_cliente;
    IF tslug IS NULL OR btrim(tslug) = '' THEN
      NEW.tipo_servicio_cliente := NULL;
    ELSE
      NEW.tipo_servicio_cliente := lower(btrim(tslug));
      tslug := NEW.tipo_servicio_cliente;
      EXECUTE format(
        $f$
        SELECT EXISTS(
          SELECT 1
          FROM %I.cliente_tipos_servicio_catalogo t
          WHERE t.empresa_id = $1
            AND t.slug = $2
        )
        $f$,
        sch
      ) INTO ok USING NEW.empresa_id, tslug;
      IF NOT coalesce(ok, false) THEN
        RAISE EXCEPTION 'tipo_servicio_cliente inexistente en el catálogo: % (empresa %, schema %)', tslug, NEW.empresa_id, sch
          USING ERRCODE = '23514';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION oymcomercial.trg_usuario_modulos_validar_modulo_empresa()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_empresa_id uuid;
BEGIN
  SELECT u.empresa_id INTO v_empresa_id
  FROM oymcomercial.usuarios u
  WHERE u.id = NEW.usuario_id;

  IF v_empresa_id IS NULL THEN
    RAISE EXCEPTION 'usuario_modulos: el usuario % no tiene empresa asignada', NEW.usuario_id
      USING ERRCODE = '23514';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM oymcomercial.empresa_modulos em
    WHERE em.empresa_id = v_empresa_id
      AND em.modulo_id = NEW.modulo_id
      AND em.activo IS TRUE
  ) THEN
    RAISE EXCEPTION 'usuario_modulos: el módulo % no está habilitado para la empresa del usuario', NEW.modulo_id
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$function$
;

-- ---------- CONSTRAINTS (PK / UNIQUE / CHECK) ----------
ALTER TABLE "oymcomercial"."categorias_productos" ADD CONSTRAINT "categorias_productos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_usuario_id_queue_id_key" UNIQUE (usuario_id, queue_id);
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_max_conversations_check" CHECK ((max_conversations >= 1));
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_operational_status_check" CHECK ((operational_status = ANY (ARRAY['ready'::text, 'offline'::text])));
ALTER TABLE "oymcomercial"."chat_campaign_events" ADD CONSTRAINT "chat_campaign_events_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_campaign_jobs" ADD CONSTRAINT "chat_campaign_jobs_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_campaign_jobs" ADD CONSTRAINT "chat_campaign_jobs_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'running'::text, 'done'::text, 'failed'::text])));
ALTER TABLE "oymcomercial"."chat_campaign_recipients" ADD CONSTRAINT "chat_campaign_recipients_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_campaign_recipients" ADD CONSTRAINT "chat_campaign_recipients_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'invalid'::text, 'queued'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'replied'::text, 'skipped'::text])));
ALTER TABLE "oymcomercial"."chat_campaign_templates" ADD CONSTRAINT "chat_campaign_templates_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_campaign_templates" ADD CONSTRAINT "chat_campaign_templates_name_trim" CHECK ((length(TRIM(BOTH FROM name)) > 0));
ALTER TABLE "oymcomercial"."chat_campaign_templates" ADD CONSTRAINT "chat_campaign_templates_provider_check" CHECK ((provider = ANY (ARRAY['meta'::text, 'ycloud'::text])));
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_name_trim" CHECK ((length(TRIM(BOTH FROM name)) > 0));
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_provider_check" CHECK ((provider = ANY (ARRAY['meta'::text, 'ycloud'::text])));
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'ready'::text, 'sending'::text, 'completed'::text, 'failed'::text, 'cancelled'::text])));
ALTER TABLE "oymcomercial"."chat_channel_quick_replies" ADD CONSTRAINT "chat_channel_quick_replies_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_channel_quick_replies" ADD CONSTRAINT "chat_channel_quick_replies_body_trim" CHECK ((length(TRIM(BOTH FROM body)) > 0));
ALTER TABLE "oymcomercial"."chat_channel_quick_replies" ADD CONSTRAINT "chat_channel_quick_replies_title_trim" CHECK ((length(TRIM(BOTH FROM title)) > 0));
ALTER TABLE "oymcomercial"."chat_channels" ADD CONSTRAINT "chat_channels_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_channels" ADD CONSTRAINT "chat_channels_config_status_check" CHECK ((config_status = ANY (ARRAY['inactive'::text, 'incomplete'::text, 'active'::text])));
ALTER TABLE "oymcomercial"."chat_channels" ADD CONSTRAINT "chat_channels_type_check" CHECK ((type = ANY (ARRAY['whatsapp'::text, 'instagram'::text, 'facebook'::text, 'email'::text, 'linkedin'::text])));
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_estado_validacion_check" CHECK ((estado_validacion = ANY (ARRAY['pendiente'::text, 'valido'::text, 'duplicado_hash'::text, 'duplicado_ocr'::text, 'revision_manual'::text, 'ocr_error'::text, 'monto_incoherente'::text, 'datos_bancarios_incoherentes'::text, 'aprobado_manual'::text, 'rechazado_manual'::text])));
ALTER TABLE "oymcomercial"."chat_contacts" ADD CONSTRAINT "chat_contacts_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_contacts" ADD CONSTRAINT "chat_contacts_empresa_id_phone_number_key" UNIQUE (empresa_id, phone_number);
ALTER TABLE "oymcomercial"."chat_conversation_closures" ADD CONSTRAINT "chat_conversation_closures_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_contact_id_channel_id_key" UNIQUE (contact_id, channel_id);
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_priority_check" CHECK ((priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])));
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_status_check" CHECK ((status = ANY (ARRAY['open'::text, 'pending'::text, 'closed'::text])));
ALTER TABLE "oymcomercial"."chat_empresa_operator_roles" ADD CONSTRAINT "chat_empresa_operator_roles_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_empresa_operator_roles" ADD CONSTRAINT "chat_empresa_operator_roles_empresa_usuario_key" UNIQUE (empresa_id, usuario_id);
ALTER TABLE "oymcomercial"."chat_empresa_operator_roles" ADD CONSTRAINT "chat_empresa_operator_roles_role_check" CHECK ((role = ANY (ARRAY['admin'::text, 'supervisor'::text, 'agente'::text])));
ALTER TABLE "oymcomercial"."chat_flow_data" ADD CONSTRAINT "chat_flow_data_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_events" ADD CONSTRAINT "chat_flow_events_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_node_blocks" ADD CONSTRAINT "chat_flow_node_blocks_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_node_blocks" ADD CONSTRAINT "chat_flow_node_blocks_block_type_check" CHECK ((block_type = ANY (ARRAY['text'::text, 'image'::text, 'buttons'::text])));
ALTER TABLE "oymcomercial"."chat_flow_nodes" ADD CONSTRAINT "chat_flow_nodes_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_nodes" ADD CONSTRAINT "chat_flow_nodes_empresa_id_flow_code_node_code_key" UNIQUE (empresa_id, flow_code, node_code);
ALTER TABLE "oymcomercial"."chat_flow_nodes" ADD CONSTRAINT "chat_flow_nodes_node_type_check" CHECK ((node_type = ANY (ARRAY['buttons'::text, 'list'::text, 'text'::text, 'media'::text, 'image_input'::text, 'human'::text, 'end'::text])));
ALTER TABLE "oymcomercial"."chat_flow_options" ADD CONSTRAINT "chat_flow_options_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_options" ADD CONSTRAINT "chat_flow_options_node_id_meta_button_id_key" UNIQUE (node_id, meta_button_id);
ALTER TABLE "oymcomercial"."chat_flow_recontact_rules" ADD CONSTRAINT "chat_flow_recontact_rules_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_recontact_rules" ADD CONSTRAINT "cfr_rules_cooldown_min" CHECK ((cooldown_seconds >= 60));
ALTER TABLE "oymcomercial"."chat_flow_recontact_rules" ADD CONSTRAINT "cfr_rules_idle_min" CHECK ((idle_after_seconds >= 60));
ALTER TABLE "oymcomercial"."chat_flow_recontact_rules" ADD CONSTRAINT "cfr_rules_max_attempts" CHECK ((max_attempts >= 1));
ALTER TABLE "oymcomercial"."chat_flow_recontact_runs" ADD CONSTRAINT "chat_flow_recontact_runs_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_sessions" ADD CONSTRAINT "chat_flow_sessions_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flow_sessions" ADD CONSTRAINT "chat_flow_sessions_referral_source_check" CHECK (((referral_source IS NULL) OR (referral_source = ANY (ARRAY['click_token'::text, 'inbound_text'::text]))));
ALTER TABLE "oymcomercial"."chat_flow_sessions" ADD CONSTRAINT "chat_flow_sessions_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'abandoned'::text, 'restarted'::text])));
ALTER TABLE "oymcomercial"."chat_flows" ADD CONSTRAINT "chat_flows_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_flows" ADD CONSTRAINT "chat_flows_empresa_id_flow_code_key" UNIQUE (empresa_id, flow_code);
ALTER TABLE "oymcomercial"."chat_messages" ADD CONSTRAINT "chat_messages_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_messages" ADD CONSTRAINT "chat_messages_sender_type_check" CHECK ((sender_type = ANY (ARRAY['contact'::text, 'ai'::text, 'human'::text, 'system'::text])));
ALTER TABLE "oymcomercial"."chat_omnicanal_work_schedules" ADD CONSTRAINT "chat_omnicanal_work_schedules_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_omnicanal_work_schedules" ADD CONSTRAINT "chat_omnicanal_work_schedules_days_check" CHECK ((days_of_week <@ ARRAY[(1)::smallint, (2)::smallint, (3)::smallint, (4)::smallint, (5)::smallint, (6)::smallint, (7)::smallint]));
ALTER TABLE "oymcomercial"."chat_queue_channels" ADD CONSTRAINT "chat_queue_channels_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_queue_channels" ADD CONSTRAINT "chat_queue_channels_queue_id_channel_id_key" UNIQUE (queue_id, channel_id);
ALTER TABLE "oymcomercial"."chat_queue_closure_states" ADD CONSTRAINT "chat_queue_closure_states_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_queue_closure_substates" ADD CONSTRAINT "chat_queue_closure_substates_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_queue_supervisors" ADD CONSTRAINT "chat_queue_supervisors_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_queue_supervisors" ADD CONSTRAINT "chat_queue_supervisors_queue_usuario_key" UNIQUE (queue_id, usuario_id);
ALTER TABLE "oymcomercial"."chat_queues" ADD CONSTRAINT "chat_queues_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_queues" ADD CONSTRAINT "chat_queues_channel_type_check" CHECK (((channel_type IS NULL) OR (channel_type = ANY (ARRAY['whatsapp'::text, 'instagram'::text, 'facebook'::text, 'email'::text, 'linkedin'::text]))));
ALTER TABLE "oymcomercial"."chat_queues" ADD CONSTRAINT "chat_queues_distribution_strategy_check" CHECK ((distribution_strategy = ANY (ARRAY['round_robin'::text, 'least_load'::text, 'manual_pull'::text])));
ALTER TABLE "oymcomercial"."chat_routing_events" ADD CONSTRAINT "chat_routing_events_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_supervisor_agents" ADD CONSTRAINT "chat_supervisor_agents_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_supervisor_agents" ADD CONSTRAINT "chat_supervisor_agents_empresa_sup_agent_key" UNIQUE (empresa_id, supervisor_usuario_id, agent_usuario_id);
ALTER TABLE "oymcomercial"."chat_supervisor_agents" ADD CONSTRAINT "chat_supervisor_agents_no_self" CHECK ((supervisor_usuario_id <> agent_usuario_id));
ALTER TABLE "oymcomercial"."chat_usuario_omnicanal" ADD CONSTRAINT "chat_usuario_omnicanal_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."chat_usuario_omnicanal" ADD CONSTRAINT "chat_usuario_omnicanal_empresa_usuario_key" UNIQUE (empresa_id, usuario_id);
ALTER TABLE "oymcomercial"."cliente_historial" ADD CONSTRAINT "cliente_historial_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cliente_historial" ADD CONSTRAINT "cliente_historial_modo_check" CHECK (((modo IS NULL) OR (modo = ANY (ARRAY['inmediato'::text, 'proximo_mes'::text, 'actualizar_factura_pendiente'::text]))));
ALTER TABLE "oymcomercial"."cliente_obligaciones_tributarias" ADD CONSTRAINT "cliente_obligaciones_tributarias_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cliente_obligaciones_tributarias" ADD CONSTRAINT "cliente_obligaciones_tributarias_uniq" UNIQUE (cliente_perfil_id, obligacion_catalogo_id);
ALTER TABLE "oymcomercial"."cliente_perfil_tributario" ADD CONSTRAINT "cliente_perfil_tributario_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cliente_perfil_tributario" ADD CONSTRAINT "cliente_perfil_tributario_empresa_cliente_unique" UNIQUE (empresa_id, cliente_id);
ALTER TABLE "oymcomercial"."cliente_perfil_tributario" ADD CONSTRAINT "cliente_perfil_tributario_dia_vencimiento_range" CHECK (((dia_vencimiento_tributario IS NULL) OR ((dia_vencimiento_tributario >= 1) AND (dia_vencimiento_tributario <= 31))));
ALTER TABLE "oymcomercial"."cliente_tipos_servicio_catalogo" ADD CONSTRAINT "cliente_tipos_servicio_catalogo_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cliente_tipos_servicio_catalogo" ADD CONSTRAINT "uq_cxtcat_empresa_slug" UNIQUE (empresa_id, slug);
ALTER TABLE "oymcomercial"."cliente_tipos_servicio_catalogo" ADD CONSTRAINT "c_cliente_tipo_cat_slug_format" CHECK (((char_length(btrim(slug)) > 0) AND (slug = lower(btrim(slug))) AND (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text)));
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_nivel_precio_check" CHECK ((nivel_precio = ANY (ARRAY['minorista'::text, 'mayorista'::text, 'distribuidor'::text])));
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_sifen_receptor_naturaleza_check" CHECK (((sifen_receptor_naturaleza IS NULL) OR (sifen_receptor_naturaleza = ANY (ARRAY['contribuyente_paraguayo'::text, 'no_contribuyente'::text, 'extranjero'::text]))));
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_sifen_ti_ope_check" CHECK (((sifen_ti_ope IS NULL) OR ((sifen_ti_ope >= 1) AND (sifen_ti_ope <= 4))));
ALTER TABLE "oymcomercial"."cobros_clientes" ADD CONSTRAINT "cobros_clientes_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cobros_clientes" ADD CONSTRAINT "cc_conciliacion_estado_check" CHECK ((conciliacion_estado = ANY (ARRAY['pendiente'::text, 'aprobado'::text, 'rechazado'::text])));
ALTER TABLE "oymcomercial"."comision_ajustes" ADD CONSTRAINT "comision_ajustes_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_ajustes" ADD CONSTRAINT "chk_comision_ajustes_motivo" CHECK ((length(TRIM(BOTH FROM motivo)) > 0));
ALTER TABLE "oymcomercial"."comision_equipo_miembros" ADD CONSTRAINT "comision_equipo_miembros_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_equipo_miembros" ADD CONSTRAINT "uq_comision_equipo_miembro" UNIQUE (equipo_id, usuario_id);
ALTER TABLE "oymcomercial"."comision_equipos" ADD CONSTRAINT "comision_equipos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_equipos" ADD CONSTRAINT "chk_comision_equipos_nombre" CHECK ((length(TRIM(BOTH FROM nombre)) > 0));
ALTER TABLE "oymcomercial"."comision_escalas" ADD CONSTRAINT "comision_escalas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_lineas" ADD CONSTRAINT "comision_lineas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_periodos" ADD CONSTRAINT "comision_periodos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_periodos" ADD CONSTRAINT "comision_periodos_estado_check" CHECK ((estado = ANY (ARRAY['borrador'::text, 'cerrado'::text, 'congelado'::text, 'aprobado'::text, 'pagado'::text])));
ALTER TABLE "oymcomercial"."comision_politica_versiones" ADD CONSTRAINT "comision_politica_versiones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_politica_versiones" ADD CONSTRAINT "uq_comision_politica_version" UNIQUE (politica_id, version_no);
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "comision_politicas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "uq_comision_politicas_empresa" UNIQUE (empresa_id);
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "chk_comision_politicas_nombre" CHECK ((length(TRIM(BOTH FROM nombre)) > 0));
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "comision_politicas_base_calculo_check" CHECK ((base_calculo = ANY (ARRAY['pago_registrado'::text, 'factura_emitida'::text, 'factura_pagada'::text])));
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_estado_check" CHECK ((estado = ANY (ARRAY['registrada'::text, 'pendiente'::text, 'pagada'::text, 'anulada'::text])));
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_iva_tipo_check" CHECK ((iva_tipo = ANY (ARRAY['exenta'::text, '5'::text, '10'::text])));
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_metodo_pago_check" CHECK (((metodo_pago IS NULL) OR (metodo_pago = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'tarjeta'::text]))));
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_moneda_check" CHECK ((moneda = ANY (ARRAY['PYG'::text, 'USD'::text])));
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_tipo_pago_check" CHECK ((tipo_pago = ANY (ARRAY['contado'::text, 'credito'::text])));
ALTER TABLE "oymcomercial"."crm_etapas" ADD CONSTRAINT "crm_etapas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."crm_etapas" ADD CONSTRAINT "crm_etapas_empresa_id_codigo_key" UNIQUE (empresa_id, codigo);
ALTER TABLE "oymcomercial"."crm_notas" ADD CONSTRAINT "crm_notas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."crm_prospectos" ADD CONSTRAINT "crm_prospectos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cuentas_por_cobrar" ADD CONSTRAINT "cuentas_por_cobrar_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."cuentas_por_cobrar" ADD CONSTRAINT "cuentas_por_cobrar_estado_check" CHECK ((estado = ANY (ARRAY['pendiente'::text, 'parcial'::text, 'pagado'::text, 'vencido'::text, 'anulado'::text])));
ALTER TABLE "oymcomercial"."dashboard_views" ADD CONSTRAINT "dashboard_views_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."dashboard_views" ADD CONSTRAINT "dashboard_views_slug_key" UNIQUE (slug);
ALTER TABLE "oymcomercial"."empresa_autoimpresor_config" ADD CONSTRAINT "empresa_autoimpresor_config_pkey" PRIMARY KEY (empresa_id);
ALTER TABLE "oymcomercial"."empresa_autoimpresor_config" ADD CONSTRAINT "empresa_autoimpresor_config_formato_impresion_default_check" CHECK ((formato_impresion_default = ANY (ARRAY['pdf_a4'::text, 'pdf_media_hoja'::text, 'ticket_80mm'::text, 'ticket_58mm'::text])));
ALTER TABLE "oymcomercial"."empresa_autoimpresor_config" ADD CONSTRAINT "empresa_autoimpresor_config_tipo_documento_default_check" CHECK ((tipo_documento_default = ANY (ARRAY['factura'::text, 'ticket'::text, 'nota_venta'::text, 'otro'::text])));
ALTER TABLE "oymcomercial"."empresa_dashboard_views" ADD CONSTRAINT "empresa_dashboard_views_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."empresa_dashboard_views" ADD CONSTRAINT "empresa_dashboard_views_empresa_id_dashboard_view_id_key" UNIQUE (empresa_id, dashboard_view_id);
ALTER TABLE "oymcomercial"."empresa_facturacion_modo" ADD CONSTRAINT "empresa_facturacion_modo_pkey" PRIMARY KEY (empresa_id);
ALTER TABLE "oymcomercial"."empresa_facturacion_modo" ADD CONSTRAINT "empresa_facturacion_modo_impresion_tipo_default_check" CHECK ((impresion_tipo_default = ANY (ARRAY['pdf_a4'::text, 'pdf_media_hoja'::text, 'ticket_80mm'::text, 'ticket_58mm'::text])));
ALTER TABLE "oymcomercial"."empresa_facturacion_modo" ADD CONSTRAINT "empresa_facturacion_modo_modo_check" CHECK ((modo = ANY (ARRAY['sin_factura_fiscal'::text, 'sifen'::text, 'autoimpresor'::text])));
ALTER TABLE "oymcomercial"."empresa_modulos" ADD CONSTRAINT "empresa_modulos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_empresa_id_key" UNIQUE (empresa_id);
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_ambiente_check" CHECK ((ambiente = ANY (ARRAY['test'::text, 'produccion'::text])));
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_kude_color_primario_fill_fmt_chk" CHECK (((kude_color_primario_fill IS NULL) OR (kude_color_primario_fill ~ '^#[0-9A-Fa-f]{6}$'::text)));
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_kude_color_primario_fmt_chk" CHECK (((kude_color_primario IS NULL) OR (kude_color_primario ~ '^#[0-9A-Fa-f]{6}$'::text)));
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_sifen_plazo_cancelacion_horas_check" CHECK (((sifen_plazo_cancelacion_horas >= 1) AND (sifen_plazo_cancelacion_horas <= 8760)));
ALTER TABLE "oymcomercial"."empresas" ADD CONSTRAINT "empresas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."entidades_bancarias" ADD CONSTRAINT "entidades_bancarias_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."factura_correlativos" ADD CONSTRAINT "factura_correlativos_pkey" PRIMARY KEY (empresa_id);
ALTER TABLE "oymcomercial"."factura_correlativos" ADD CONSTRAINT "factura_correlativos_ultimo_numero_check" CHECK ((ultimo_numero >= 0));
ALTER TABLE "oymcomercial"."factura_electronica" ADD CONSTRAINT "factura_electronica_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."factura_electronica" ADD CONSTRAINT "factura_electronica_factura_id_key" UNIQUE (factura_id);
ALTER TABLE "oymcomercial"."factura_electronica" ADD CONSTRAINT "factura_electronica_estado_sifen_check" CHECK ((estado_sifen = ANY (ARRAY['borrador'::text, 'generado'::text, 'firmado'::text, 'enviado'::text, 'aprobado'::text, 'rechazado'::text, 'error_envio'::text, 'cancelado'::text])));
ALTER TABLE "oymcomercial"."factura_electronica_evento" ADD CONSTRAINT "factura_electronica_evento_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."factura_electronica_evento" ADD CONSTRAINT "factura_electronica_evento_tipo_check" CHECK ((tipo = ANY (ARRAY['generacion'::text, 'envio'::text, 'respuesta'::text, 'error'::text, 'firma'::text, 'cancelacion'::text])));
ALTER TABLE "oymcomercial"."factura_items" ADD CONSTRAINT "factura_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."factura_items" ADD CONSTRAINT "factura_items_tipo_iva_check" CHECK ((tipo_iva = ANY (ARRAY['EXENTA'::text, '5%'::text, '10%'::text])));
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_estado_check" CHECK ((estado = ANY (ARRAY['Pagado'::text, 'Pendiente'::text, 'Vencido'::text, 'Anulado'::text, 'Corregida NC'::text])));
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_moneda_check" CHECK ((moneda = ANY (ARRAY['GS'::text, 'USD'::text])));
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_tipo_check" CHECK ((tipo = ANY (ARRAY['contado'::text, 'credito'::text, 'suscripcion'::text])));
ALTER TABLE "oymcomercial"."gastos" ADD CONSTRAINT "gastos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."gastos" ADD CONSTRAINT "gastos_metodo_pago_check" CHECK (((metodo_pago IS NULL) OR (metodo_pago = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'tarjeta'::text]))));
ALTER TABLE "oymcomercial"."gastos" ADD CONSTRAINT "gastos_tipo_check" CHECK ((tipo = ANY (ARRAY['fijo'::text, 'variable'::text])));
ALTER TABLE "oymcomercial"."imports_audit" ADD CONSTRAINT "imports_audit_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."inventario_stock_ubicacion" ADD CONSTRAINT "inventario_stock_ubicacion_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."inventario_ubicaciones" ADD CONSTRAINT "inventario_ubicaciones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."inventario_ubicaciones" ADD CONSTRAINT "inventario_ubicaciones_tipo_check" CHECK ((tipo = ANY (ARRAY['deposito'::text, 'salon'::text, 'pasillo'::text, 'gondola'::text, 'estante'::text, 'zona'::text, 'otro'::text])));
ALTER TABLE "oymcomercial"."marketing_calendarios" ADD CONSTRAINT "marketing_calendarios_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."marketing_comentarios" ADD CONSTRAINT "marketing_comentarios_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."marketing_comentarios" ADD CONSTRAINT "chk_marketing_comentarios_texto_non_empty" CHECK ((length(TRIM(BOTH FROM comentario)) > 0));
ALTER TABLE "oymcomercial"."marketing_historial_estados" ADD CONSTRAINT "marketing_historial_estados_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."marketing_historial_estados" ADD CONSTRAINT "chk_marketing_historial_campo_non_empty" CHECK ((length(TRIM(BOTH FROM campo)) > 0));
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "chk_marketing_piezas_titulo_non_empty" CHECK ((length(TRIM(BOTH FROM titulo)) > 0));
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_estado_cliente_check" CHECK ((estado_cliente = ANY (ARRAY['no_enviado'::text, 'enviado'::text, 'aprobado'::text, 'con_correcciones'::text, 'sin_respuesta'::text])));
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_estado_produccion_check" CHECK ((estado_produccion = ANY (ARRAY['por_hacer'::text, 'en_produccion'::text, 'revision_interna'::text, 'correccion_interna'::text, 'listo_para_enviar'::text])));
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_estado_publicacion_check" CHECK ((estado_publicacion = ANY (ARRAY['pendiente'::text, 'programado'::text, 'publicado'::text, 'cancelado'::text])));
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_prioridad_check" CHECK ((prioridad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text, 'urgente'::text])));
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_estado_check" CHECK ((estado = ANY (ARRAY['pendiente'::text, 'en_proceso'::text, 'en_revision'::text, 'aprobado'::text, 'publicado'::text])));
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_prioridad_check" CHECK (((prioridad IS NULL) OR (prioridad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text, 'urgente'::text]))));
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_tipo_contenido_check" CHECK ((tipo_contenido = ANY (ARRAY['post'::text, 'reel'::text, 'historia'::text, 'anuncio'::text, 'otro'::text])));
ALTER TABLE "oymcomercial"."modulos" ADD CONSTRAINT "modulos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_origen_check" CHECK ((origen = ANY (ARRAY['compra'::text, 'venta'::text, 'ajuste_manual'::text, 'inventario_inicial'::text, 'anulacion_venta'::text, 'anulacion_compra'::text, 'produccion'::text, 'transferencia_salida'::text, 'transferencia_entrada'::text])));
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_tipo_check" CHECK ((tipo = ANY (ARRAY['ENTRADA'::text, 'SALIDA'::text, 'AJUSTE'::text])));
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_estado_erp_check" CHECK ((estado_erp = ANY (ARRAY['borrador'::text, 'pendiente_envio_sifen'::text, 'aprobada'::text, 'rechazada'::text, 'error'::text, 'anulada_borrador'::text, 'cancelada'::text])));
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_moneda_snapshot_check" CHECK ((moneda_snapshot = ANY (ARRAY['GS'::text, 'USD'::text])));
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_monto_check" CHECK ((monto > (0)::numeric));
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_motivo_len_check" CHECK (((length(TRIM(BOTH FROM motivo)) >= 5) AND (length(motivo) <= 2000)));
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_tipo_nc_check" CHECK ((tipo_nc = ANY (ARRAY['total'::text, 'parcial'::text])));
ALTER TABLE "oymcomercial"."nota_credito_electronica" ADD CONSTRAINT "nota_credito_electronica_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."nota_credito_electronica" ADD CONSTRAINT "nota_credito_electronica_nota_credito_id_key" UNIQUE (nota_credito_id);
ALTER TABLE "oymcomercial"."nota_credito_electronica" ADD CONSTRAINT "nota_credito_electronica_estado_sifen_check" CHECK ((estado_sifen = ANY (ARRAY['sin_envio'::text, 'generado'::text, 'firmado'::text, 'enviado'::text, 'en_proceso'::text, 'aprobado'::text, 'rechazado'::text, 'error_envio'::text, 'cancelado'::text])));
ALTER TABLE "oymcomercial"."nota_credito_evento" ADD CONSTRAINT "nota_credito_evento_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."nota_credito_evento" ADD CONSTRAINT "nota_credito_evento_tipo_check" CHECK ((tipo_evento = ANY (ARRAY['creacion'::text, 'validacion'::text, 'rechazo_negocio'::text, 'cambio_estado_erp'::text, 'preparacion_sifen'::text, 'error'::text, 'observacion_operativa'::text, 'anulacion_borrador'::text, 'xml_generado'::text, 'xml_firmado'::text, 'enviado_set'::text, 'respuesta_set'::text, 'aprobado'::text, 'rechazado'::text, 'impacto_saldo_aplicado'::text, 'error_envio'::text])));
ALTER TABLE "oymcomercial"."nota_credito_items" ADD CONSTRAINT "nota_credito_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."nota_credito_items" ADD CONSTRAINT "nota_credito_items_cantidad_check" CHECK ((cantidad > (0)::numeric));
ALTER TABLE "oymcomercial"."nota_credito_items" ADD CONSTRAINT "nota_credito_items_modo_check" CHECK ((modo = ANY (ARRAY['unidades'::text, 'monto'::text])));
ALTER TABLE "oymcomercial"."nota_credito_items" ADD CONSTRAINT "nota_credito_items_precio_unitario_check" CHECK ((precio_unitario >= (0)::numeric));
ALTER TABLE "oymcomercial"."nota_credito_items" ADD CONSTRAINT "nota_credito_items_tipo_iva_check" CHECK ((tipo_iva = ANY (ARRAY['EXENTA'::text, '5%'::text, '10%'::text])));
ALTER TABLE "oymcomercial"."obligaciones_tributarias_catalogo" ADD CONSTRAINT "obligaciones_tributarias_catalogo_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."obligaciones_tributarias_catalogo" ADD CONSTRAINT "obligaciones_tributarias_catalogo_slug_key" UNIQUE (slug);
ALTER TABLE "oymcomercial"."omnichannel_routes" ADD CONSTRAINT "omnichannel_routes_pkey" PRIMARY KEY (meta_phone_number_id);
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_metodo_pago_check" CHECK ((metodo_pago = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'cheque'::text, 'tarjeta'::text, 'otro'::text])));
ALTER TABLE "oymcomercial"."planes" ADD CONSTRAINT "planes_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."planes" ADD CONSTRAINT "planes_estado_check" CHECK ((estado = ANY (ARRAY['activo'::text, 'inactivo'::text])));
ALTER TABLE "oymcomercial"."planes" ADD CONSTRAINT "planes_moneda_check" CHECK ((moneda = ANY (ARRAY['GS'::text, 'USD'::text])));
ALTER TABLE "oymcomercial"."planes" ADD CONSTRAINT "planes_periodicidad_check" CHECK ((periodicidad = ANY (ARRAY['mensual'::text, 'anual'::text, 'unico'::text])));
ALTER TABLE "oymcomercial"."presupuesto_items" ADD CONSTRAINT "presupuesto_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."presupuestos" ADD CONSTRAINT "presupuestos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."presupuestos" ADD CONSTRAINT "presupuestos_estado_check" CHECK ((estado = ANY (ARRAY['creado'::text, 'enviado'::text, 'aprobado'::text, 'rechazado'::text, 'convertido'::text])));
ALTER TABLE "oymcomercial"."produccion_items" ADD CONSTRAINT "produccion_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."producciones" ADD CONSTRAINT "producciones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."producto_categorias" ADD CONSTRAINT "producto_categorias_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_factor_compra_receta_check" CHECK ((factor_compra_receta > (0)::numeric));
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_metodo_valuacion_check" CHECK ((metodo_valuacion = ANY (ARRAY['CPP'::text, 'FIFO'::text, 'LIFO'::text])));
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_modo_receta_check" CHECK ((modo_receta = ANY (ARRAY['preparado_al_vender'::text, 'produccion_previa'::text])));
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_tiempo_prep_minutos_check" CHECK ((tiempo_prep_minutos >= 0));
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_tipo_iva_check" CHECK ((tipo_iva = ANY (ARRAY['EXENTA'::text, '5%'::text, '10%'::text])));
ALTER TABLE "oymcomercial"."productos_codigo_secuencia" ADD CONSTRAINT "productos_codigo_secuencia_pkey" PRIMARY KEY (empresa_id);
ALTER TABLE "oymcomercial"."proveedor_categoria_rel" ADD CONSTRAINT "proveedor_categoria_rel_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proveedor_categoria_rel" ADD CONSTRAINT "proveedor_categoria_rel_uniq" UNIQUE (proveedor_id, categoria_id);
ALTER TABLE "oymcomercial"."proveedor_categorias" ADD CONSTRAINT "proveedor_categorias_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proveedor_productos" ADD CONSTRAINT "proveedor_productos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proveedor_productos" ADD CONSTRAINT "proveedor_productos_empresa_producto_proveedor_uniq" UNIQUE (empresa_id, producto_id, proveedor_id);
ALTER TABLE "oymcomercial"."proveedores" ADD CONSTRAINT "proveedores_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proveedores" ADD CONSTRAINT "proveedores_condicion_pago_check" CHECK (((condicion_pago IS NULL) OR (condicion_pago = ANY (ARRAY['contado'::text, 'credito'::text, 'mixto'::text]))));
ALTER TABLE "oymcomercial"."proveedores" ADD CONSTRAINT "proveedores_estado_check" CHECK ((estado = ANY (ARRAY['activo'::text, 'inactivo'::text])));
ALTER TABLE "oymcomercial"."proveedores" ADD CONSTRAINT "proveedores_moneda_preferida_check" CHECK (((moneda_preferida IS NULL) OR (moneda_preferida = ANY (ARRAY['GS'::text, 'USD'::text]))));
ALTER TABLE "oymcomercial"."proyecto_archivos" ADD CONSTRAINT "proyecto_archivos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_archivos" ADD CONSTRAINT "uq_proyecto_archivos_storage_natural" UNIQUE (empresa_id, storage_bucket, storage_path);
ALTER TABLE "oymcomercial"."proyecto_archivos" ADD CONSTRAINT "chk_proyecto_archivos_nombre_non_empty" CHECK ((length(TRIM(BOTH FROM nombre)) > 0));
ALTER TABLE "oymcomercial"."proyecto_comentarios" ADD CONSTRAINT "proyecto_comentarios_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_comentarios" ADD CONSTRAINT "chk_proyecto_comentarios_texto_non_empty" CHECK ((length(TRIM(BOTH FROM comentario)) > 0));
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ADD CONSTRAINT "proyecto_estado_historial_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_estados" ADD CONSTRAINT "proyecto_estados_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_estados" ADD CONSTRAINT "uq_proyecto_estados_empresa_codigo" UNIQUE (empresa_id, codigo);
ALTER TABLE "oymcomercial"."proyecto_estados" ADD CONSTRAINT "chk_proyecto_estados_codigo_non_empty" CHECK ((length(TRIM(BOTH FROM codigo)) > 0));
ALTER TABLE "oymcomercial"."proyecto_estados" ADD CONSTRAINT "proyecto_estados_tipo_sla_check" CHECK ((tipo_sla = ANY (ARRAY['interno'::text, 'cliente'::text, 'pausado'::text, 'final'::text])));
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "proyecto_prioridades_config_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "uq_proyecto_prioridades_empresa_codigo" UNIQUE (empresa_id, codigo);
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "chk_proyecto_prioridades_bg_color" CHECK (((bg_color IS NULL) OR (bg_color ~ '^#[0-9A-Fa-f]{6}$'::text)));
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "chk_proyecto_prioridades_border_color" CHECK (((border_color IS NULL) OR (border_color ~ '^#[0-9A-Fa-f]{6}$'::text)));
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "chk_proyecto_prioridades_codigo" CHECK ((codigo = ANY (ARRAY['baja'::text, 'normal'::text, 'alta'::text, 'urgente'::text])));
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "chk_proyecto_prioridades_color" CHECK (((color IS NULL) OR (color ~ '^#[0-9A-Fa-f]{6}$'::text)));
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "chk_proyecto_prioridades_nombre_non_empty" CHECK ((length(TRIM(BOTH FROM nombre)) > 0));
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "chk_proyecto_prioridades_text_color" CHECK (((text_color IS NULL) OR (text_color ~ '^#[0-9A-Fa-f]{6}$'::text)));
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "proyecto_tareas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "chk_proyecto_tareas_titulo_non_empty" CHECK ((length(TRIM(BOTH FROM titulo)) > 0));
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "proyecto_tareas_estado_check" CHECK ((estado = ANY (ARRAY['pendiente'::text, 'en_proceso'::text, 'completada'::text, 'bloqueada'::text])));
ALTER TABLE "oymcomercial"."proyecto_tipos" ADD CONSTRAINT "proyecto_tipos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyecto_tipos" ADD CONSTRAINT "uq_proyecto_tipos_empresa_codigo" UNIQUE (empresa_id, codigo);
ALTER TABLE "oymcomercial"."proyecto_tipos" ADD CONSTRAINT "chk_proyecto_tipos_codigo_non_empty" CHECK ((length(TRIM(BOTH FROM codigo)) > 0));
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "chk_proyectos_titulo_non_empty" CHECK ((length(TRIM(BOTH FROM titulo)) > 0));
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_prioridad_check" CHECK ((prioridad = ANY (ARRAY['baja'::text, 'normal'::text, 'alta'::text, 'urgente'::text])));
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_unicos" UNIQUE (receta_id, insumo_producto_id);
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_cantidad_check" CHECK ((cantidad > (0)::numeric));
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_merma_pct_check" CHECK (((merma_pct >= (0)::numeric) AND (merma_pct < (1)::numeric)));
ALTER TABLE "oymcomercial"."recetas" ADD CONSTRAINT "recetas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."recetas" ADD CONSTRAINT "recetas_empresa_producto_uq" UNIQUE (empresa_id, producto_id);
ALTER TABLE "oymcomercial"."recetas" ADD CONSTRAINT "recetas_rendimiento_cantidad_check" CHECK ((rendimiento_cantidad > (0)::numeric));
ALTER TABLE "oymcomercial"."recibos_dinero" ADD CONSTRAINT "recibos_dinero_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."recibos_dinero" ADD CONSTRAINT "recibos_dinero_origen_check" CHECK ((origen = ANY (ARRAY['venta_contado'::text, 'cobro_cxc'::text, 'manual'::text])));
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibos_dinero_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibo_item_importe_pos" CHECK ((importe_aplicado > (0)::numeric));
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_estado_check" CHECK ((estado = ANY (ARRAY['pendiente'::text, 'procesando'::text, 'aprobado'::text, 'rechazado'::text, 'error'::text])));
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_etapa_check" CHECK (((etapa IS NULL) OR (etapa = ANY (ARRAY['xml'::text, 'firmar'::text, 'enviar'::text, 'consulta_lote'::text]))));
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_origen_check" CHECK ((origen = ANY (ARRAY['auto_venta'::text, 'reintento_manual'::text, 'manual_admin'::text])));
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_tipo_error_check" CHECK (((tipo_error IS NULL) OR (tipo_error = ANY (ARRAY['set_rechazo'::text, 'fiscal'::text, 'firma'::text, 'config'::text, 'red'::text, 'http_5xx'::text, 'storage'::text, 'inesperado'::text, 'set_timeout'::text]))));
ALTER TABLE "oymcomercial"."sorteo_conversaciones" ADD CONSTRAINT "sorteo_conversaciones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteo_conversaciones" ADD CONSTRAINT "sorteo_conversaciones_estado_check" CHECK ((estado = ANY (ARRAY['new_lead'::text, 'awaiting_ticket_selection'::text, 'awaiting_customer_data'::text, 'awaiting_payment'::text, 'awaiting_receipt'::text, 'receipt_under_review'::text, 'paid_confirmed'::text, 'human_handoff'::text, 'cancelled'::text, 'closed_no_response'::text])));
ALTER TABLE "oymcomercial"."sorteo_cupones" ADD CONSTRAINT "sorteo_cupones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteo_cupones" ADD CONSTRAINT "sorteo_cupones_sorteo_id_numero_cupon_key" UNIQUE (sorteo_id, numero_cupon);
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_estado_pago_check" CHECK ((estado_pago = ANY (ARRAY['pendiente'::text, 'pendiente_revision'::text, 'confirmado'::text, 'rechazado'::text])));
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_moneda_check" CHECK ((moneda = 'PYG'::text));
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_pago_metodo_check" CHECK (((pago_metodo IS NULL) OR (pago_metodo = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'tarjeta'::text, 'otro'::text]))));
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_precio_fuente_check" CHECK (((precio_fuente IS NULL) OR (precio_fuente = ANY (ARRAY['lista'::text, 'promo'::text]))));
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_venta_canal_check" CHECK (((venta_canal IS NULL) OR (venta_canal = ANY (ARRAY['remote'::text, 'local'::text]))));
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_venta_origen_check" CHECK (((venta_origen IS NULL) OR (venta_origen = ANY (ARRAY['whatsapp_flow'::text, 'erp_manual'::text]))));
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ADD CONSTRAINT "sorteo_revendedor_clicks_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteo_revendedores" ADD CONSTRAINT "sorteo_revendedores_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_delivery_mode_check" CHECK ((delivery_mode = ANY (ARRAY['text_only'::text, 'text_and_image'::text, 'image_only'::text])));
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'generated'::text, 'sent'::text, 'error'::text])));
ALTER TABLE "oymcomercial"."sorteos" ADD CONSTRAINT "sorteos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sorteos" ADD CONSTRAINT "sorteos_coupon_number_mode_check" CHECK (((coupon_number_mode IS NULL) OR (coupon_number_mode = ANY (ARRAY['correlative'::text, 'random'::text]))));
ALTER TABLE "oymcomercial"."sorteos" ADD CONSTRAINT "sorteos_estado_check" CHECK ((estado = ANY (ARRAY['activo'::text, 'pausado'::text, 'cerrado'::text, 'finalizado'::text])));
ALTER TABLE "oymcomercial"."sorteos" ADD CONSTRAINT "sorteos_ticket_delivery_mode_check" CHECK ((ticket_delivery_mode = ANY (ARRAY['text_only'::text, 'text_and_image'::text, 'image_only'::text])));
ALTER TABLE "oymcomercial"."sucursales" ADD CONSTRAINT "sucursales_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."sucursales" ADD CONSTRAINT "sucursales_codigo_uq" UNIQUE (empresa_id, codigo);
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_dia_facturacion_check" CHECK (((dia_facturacion >= 1) AND (dia_facturacion <= 28)));
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_dia_vencimiento_check" CHECK (((dia_vencimiento >= 1) AND (dia_vencimiento <= 31)));
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_estado_check" CHECK ((estado = ANY (ARRAY['activa'::text, 'pausada'::text, 'cancelada'::text])));
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_moneda_check" CHECK ((moneda = ANY (ARRAY['GS'::text, 'USD'::text])));
ALTER TABLE "oymcomercial"."tipificaciones" ADD CONSTRAINT "tipificaciones_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."tipificaciones" ADD CONSTRAINT "tipificaciones_resultado_check" CHECK ((resultado = ANY (ARRAY['Pendiente'::text, 'Resuelto'::text, 'Escalar'::text])));
ALTER TABLE "oymcomercial"."tipificaciones" ADD CONSTRAINT "tipificaciones_tipo_gestion_check" CHECK ((tipo_gestion = ANY (ARRAY['Consulta'::text, 'Reclamo'::text, 'Seguimiento'::text, 'Promesa de pago'::text, 'Soporte técnico'::text, 'Cambio plan'::text])));
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_numero_empresa_uq" UNIQUE (empresa_id, numero);
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_estado_check" CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aprobada'::text, 'rechazada'::text, 'despachada'::text, 'recibida'::text, 'cancelada'::text])));
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_origen_distinto_destino" CHECK ((sucursal_origen_id <> sucursal_destino_id));
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transferencias_inventario_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_producto_uq" UNIQUE (transferencia_id, producto_destino_id);
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_aprobada_le_solicitada" CHECK ((cantidad_aprobada <= cantidad_solicitada));
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_cant_aprobada_nonneg" CHECK ((cantidad_aprobada >= (0)::numeric));
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_cant_despachada_nonneg" CHECK ((cantidad_despachada >= (0)::numeric));
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_cant_recibida_nonneg" CHECK ((cantidad_recibida >= (0)::numeric));
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_cant_solicitada_pos" CHECK ((cantidad_solicitada > (0)::numeric));
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transf_item_costo_nonneg" CHECK ((costo_unitario_transferencia >= (0)::numeric));
ALTER TABLE "oymcomercial"."usuario_dashboard_views" ADD CONSTRAINT "usuario_dashboard_views_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."usuario_dashboard_views" ADD CONSTRAINT "usuario_dashboard_views_usuario_id_dashboard_view_id_key" UNIQUE (usuario_id, dashboard_view_id);
ALTER TABLE "oymcomercial"."usuario_modulos" ADD CONSTRAINT "usuario_modulos_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."usuario_modulos" ADD CONSTRAINT "usuario_modulos_usuario_id_modulo_id_key" UNIQUE (usuario_id, modulo_id);
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_email_key" UNIQUE (email);
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_area_check" CHECK (((area IS NULL) OR (area = ANY (ARRAY['ventas'::text, 'soporte'::text, 'finanzas'::text, 'operaciones'::text, 'administracion'::text]))));
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_estado_check" CHECK ((estado = ANY (ARRAY['activo'::text, 'inactivo'::text])));
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_porcentaje_comision_check" CHECK (((porcentaje_comision IS NULL) OR ((porcentaje_comision >= (0)::numeric) AND (porcentaje_comision <= (100)::numeric))));
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_tipo_contrato_check" CHECK (((tipo_contrato IS NULL) OR (tipo_contrato = ANY (ARRAY['salario'::text, 'comision'::text, 'mixto'::text, 'prestador_servicio'::text]))));
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_estado_check" CHECK ((estado = ANY (ARRAY['pendiente'::text, 'completada'::text, 'anulada'::text])));
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_metodo_pago_chk" CHECK (((metodo_pago IS NULL) OR (metodo_pago = ANY (ARRAY['efectivo'::text, 'tarjeta'::text, 'transferencia'::text]))));
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_moneda_check" CHECK ((moneda = ANY (ARRAY['GS'::text, 'USD'::text])));
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_tipo_venta_check" CHECK ((tipo_venta = ANY (ARRAY['CONTADO'::text, 'CREDITO'::text])));
ALTER TABLE "oymcomercial"."ventas_items" ADD CONSTRAINT "ventas_items_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."ventas_items" ADD CONSTRAINT "ventas_items_tipo_iva_check" CHECK ((tipo_iva = ANY (ARRAY['EXENTA'::text, '5%'::text, '10%'::text])));
ALTER TABLE "oymcomercial"."ventas_items" ADD CONSTRAINT "ventas_items_tipo_precio_check" CHECK ((tipo_precio = ANY (ARRAY['minorista'::text, 'mayorista'::text, 'distribuidor'::text, 'costo'::text])));
ALTER TABLE "oymcomercial"."ventas_pagos_detalle" ADD CONSTRAINT "ventas_pagos_detalle_pkey" PRIMARY KEY (id);
ALTER TABLE "oymcomercial"."ventas_pagos_detalle" ADD CONSTRAINT "ventas_pagos_detalle_metodo_pago_check" CHECK ((metodo_pago = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'tarjeta'::text, 'qr'::text, 'billetera'::text, 'otro'::text])));
ALTER TABLE "oymcomercial"."ventas_pagos_detalle" ADD CONSTRAINT "vpd_conciliacion_estado_check" CHECK ((conciliacion_estado = ANY (ARRAY['pendiente'::text, 'aprobado'::text, 'rechazado'::text])));

-- ---------- FOREIGN KEYS ----------
ALTER TABLE "oymcomercial"."categorias_productos" ADD CONSTRAINT "categorias_productos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."categorias_productos" ADD CONSTRAINT "categorias_productos_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES oymcomercial.categorias_productos(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."categorias_productos" ADD CONSTRAINT "categorias_productos_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_agents" ADD CONSTRAINT "chat_agents_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_campaign_events" ADD CONSTRAINT "chat_campaign_events_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES oymcomercial.chat_campaigns(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_campaign_events" ADD CONSTRAINT "chat_campaign_events_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES oymcomercial.chat_campaign_recipients(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_campaign_jobs" ADD CONSTRAINT "chat_campaign_jobs_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES oymcomercial.chat_campaigns(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_campaign_recipients" ADD CONSTRAINT "chat_campaign_recipients_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES oymcomercial.chat_campaigns(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_campaign_templates" ADD CONSTRAINT "chat_campaign_templates_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES oymcomercial.chat_channels(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES oymcomercial.chat_channels(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_campaigns" ADD CONSTRAINT "chat_campaigns_template_id_fkey" FOREIGN KEY (template_id) REFERENCES oymcomercial.chat_campaign_templates(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_channel_quick_replies" ADD CONSTRAINT "chat_channel_quick_replies_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES oymcomercial.chat_channels(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_channels" ADD CONSTRAINT "chat_channels_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES oymcomercial.chat_channels(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_flow_session_id_fkey" FOREIGN KEY (flow_session_id) REFERENCES oymcomercial.chat_flow_sessions(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ADD CONSTRAINT "chat_comprobante_validaciones_sorteo_entrada_id_fkey" FOREIGN KEY (sorteo_entrada_id) REFERENCES oymcomercial.sorteo_entradas(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_contacts" ADD CONSTRAINT "chat_contacts_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_contacts" ADD CONSTRAINT "chat_contacts_crm_prospecto_id_fkey" FOREIGN KEY (crm_prospecto_id) REFERENCES oymcomercial.crm_prospectos(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_contacts" ADD CONSTRAINT "chat_contacts_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_conversation_closures" ADD CONSTRAINT "chat_conversation_closures_closure_state_id_fkey" FOREIGN KEY (closure_state_id) REFERENCES oymcomercial.chat_queue_closure_states(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_conversation_closures" ADD CONSTRAINT "chat_conversation_closures_closure_substate_id_fkey" FOREIGN KEY (closure_substate_id) REFERENCES oymcomercial.chat_queue_closure_substates(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_conversation_closures" ADD CONSTRAINT "chat_conversation_closures_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_conversation_closures" ADD CONSTRAINT "chat_conversation_closures_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_active_flow_session_id_fkey" FOREIGN KEY (active_flow_session_id) REFERENCES oymcomercial.chat_flow_sessions(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_assigned_agent_id_fkey" FOREIGN KEY (assigned_agent_id) REFERENCES oymcomercial.chat_agents(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES oymcomercial.chat_channels(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES oymcomercial.chat_contacts(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_first_revendedor_id_fkey" FOREIGN KEY (first_revendedor_id) REFERENCES oymcomercial.sorteo_revendedores(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_conversations" ADD CONSTRAINT "chat_conversations_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_empresa_operator_roles" ADD CONSTRAINT "chat_empresa_operator_roles_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_data" ADD CONSTRAINT "chat_flow_data_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_data" ADD CONSTRAINT "chat_flow_data_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_data" ADD CONSTRAINT "chat_flow_data_flow_session_id_fkey" FOREIGN KEY (flow_session_id) REFERENCES oymcomercial.chat_flow_sessions(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_events" ADD CONSTRAINT "chat_flow_events_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_events" ADD CONSTRAINT "chat_flow_events_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_events" ADD CONSTRAINT "chat_flow_events_flow_session_id_fkey" FOREIGN KEY (flow_session_id) REFERENCES oymcomercial.chat_flow_sessions(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_flow_events" ADD CONSTRAINT "chat_flow_events_selected_option_id_fkey" FOREIGN KEY (selected_option_id) REFERENCES oymcomercial.chat_flow_options(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_flow_node_blocks" ADD CONSTRAINT "chat_flow_node_blocks_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_node_blocks" ADD CONSTRAINT "chat_flow_node_blocks_node_id_fkey" FOREIGN KEY (node_id) REFERENCES oymcomercial.chat_flow_nodes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_nodes" ADD CONSTRAINT "chat_flow_nodes_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_options" ADD CONSTRAINT "chat_flow_options_node_id_fkey" FOREIGN KEY (node_id) REFERENCES oymcomercial.chat_flow_nodes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_recontact_rules" ADD CONSTRAINT "cfr_rules_flow_fk" FOREIGN KEY (empresa_id, flow_code) REFERENCES oymcomercial.chat_flows(empresa_id, flow_code) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_recontact_runs" ADD CONSTRAINT "chat_flow_recontact_runs_rule_id_fkey" FOREIGN KEY (rule_id) REFERENCES oymcomercial.chat_flow_recontact_rules(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_sessions" ADD CONSTRAINT "chat_flow_sessions_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_sessions" ADD CONSTRAINT "chat_flow_sessions_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flow_sessions" ADD CONSTRAINT "chat_flow_sessions_revendedor_id_fkey" FOREIGN KEY (revendedor_id) REFERENCES oymcomercial.sorteo_revendedores(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_flows" ADD CONSTRAINT "chat_flows_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_flows" ADD CONSTRAINT "chat_flows_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_messages" ADD CONSTRAINT "chat_messages_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_messages" ADD CONSTRAINT "chat_messages_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_channels" ADD CONSTRAINT "chat_queue_channels_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES oymcomercial.chat_channels(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_channels" ADD CONSTRAINT "chat_queue_channels_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_channels" ADD CONSTRAINT "chat_queue_channels_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_closure_states" ADD CONSTRAINT "chat_queue_closure_states_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_closure_substates" ADD CONSTRAINT "chat_queue_closure_substates_closure_state_id_fkey" FOREIGN KEY (closure_state_id) REFERENCES oymcomercial.chat_queue_closure_states(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_supervisors" ADD CONSTRAINT "chat_queue_supervisors_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queue_supervisors" ADD CONSTRAINT "chat_queue_supervisors_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_queues" ADD CONSTRAINT "chat_queues_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_routing_events" ADD CONSTRAINT "chat_routing_events_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_routing_events" ADD CONSTRAINT "chat_routing_events_queue_id_fkey" FOREIGN KEY (queue_id) REFERENCES oymcomercial.chat_queues(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."chat_supervisor_agents" ADD CONSTRAINT "chat_supervisor_agents_agent_usuario_id_fkey" FOREIGN KEY (agent_usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_supervisor_agents" ADD CONSTRAINT "chat_supervisor_agents_supervisor_usuario_id_fkey" FOREIGN KEY (supervisor_usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_usuario_omnicanal" ADD CONSTRAINT "chat_usuario_omnicanal_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."chat_usuario_omnicanal" ADD CONSTRAINT "chat_usuario_omnicanal_work_schedule_id_fkey" FOREIGN KEY (work_schedule_id) REFERENCES oymcomercial.chat_omnicanal_work_schedules(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."cliente_historial" ADD CONSTRAINT "cliente_historial_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_historial" ADD CONSTRAINT "cliente_historial_creado_por_auth_user_id_fkey" FOREIGN KEY (creado_por_auth_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."cliente_historial" ADD CONSTRAINT "cliente_historial_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_obligaciones_tributarias" ADD CONSTRAINT "cliente_obligaciones_tributarias_cliente_perfil_id_fkey" FOREIGN KEY (cliente_perfil_id) REFERENCES oymcomercial.cliente_perfil_tributario(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_obligaciones_tributarias" ADD CONSTRAINT "cliente_obligaciones_tributarias_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_obligaciones_tributarias" ADD CONSTRAINT "cliente_obligaciones_tributarias_obligacion_catalogo_id_fkey" FOREIGN KEY (obligacion_catalogo_id) REFERENCES oymcomercial.obligaciones_tributarias_catalogo(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_perfil_tributario" ADD CONSTRAINT "cliente_perfil_tributario_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_perfil_tributario" ADD CONSTRAINT "cliente_perfil_tributario_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cliente_tipos_servicio_catalogo" ADD CONSTRAINT "cliente_tipos_servicio_catalogo_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_baja_operativa_by_user_id_fkey" FOREIGN KEY (baja_operativa_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_deleted_by_user_id_fkey" FOREIGN KEY (deleted_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_plan_comercial_id_fkey" FOREIGN KEY (plan_comercial_id) REFERENCES oymcomercial.planes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."clientes" ADD CONSTRAINT "clientes_vendedor_usuario_id_fkey" FOREIGN KEY (vendedor_usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."cobros_clientes" ADD CONSTRAINT "cobros_clientes_cuenta_por_cobrar_id_fkey" FOREIGN KEY (cuenta_por_cobrar_id) REFERENCES oymcomercial.cuentas_por_cobrar(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cobros_clientes" ADD CONSTRAINT "cobros_clientes_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."comision_ajustes" ADD CONSTRAINT "comision_ajustes_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."comision_ajustes" ADD CONSTRAINT "comision_ajustes_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_ajustes" ADD CONSTRAINT "comision_ajustes_linea_id_fkey" FOREIGN KEY (linea_id) REFERENCES oymcomercial.comision_lineas(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."comision_ajustes" ADD CONSTRAINT "comision_ajustes_periodo_id_fkey" FOREIGN KEY (periodo_id) REFERENCES oymcomercial.comision_periodos(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."comision_equipo_miembros" ADD CONSTRAINT "comision_equipo_miembros_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_equipo_miembros" ADD CONSTRAINT "comision_equipo_miembros_equipo_id_fkey" FOREIGN KEY (equipo_id) REFERENCES oymcomercial.comision_equipos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_equipo_miembros" ADD CONSTRAINT "comision_equipo_miembros_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_equipos" ADD CONSTRAINT "comision_equipos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_equipos" ADD CONSTRAINT "comision_equipos_supervisor_usuario_id_fkey" FOREIGN KEY (supervisor_usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_escalas" ADD CONSTRAINT "comision_escalas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_escalas" ADD CONSTRAINT "comision_escalas_politica_id_fkey" FOREIGN KEY (politica_id) REFERENCES oymcomercial.comision_politicas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_lineas" ADD CONSTRAINT "comision_lineas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_lineas" ADD CONSTRAINT "comision_lineas_periodo_id_fkey" FOREIGN KEY (periodo_id) REFERENCES oymcomercial.comision_periodos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_lineas" ADD CONSTRAINT "comision_lineas_usuario_vendedor_id_fkey" FOREIGN KEY (usuario_vendedor_id) REFERENCES oymcomercial.usuarios(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."comision_periodos" ADD CONSTRAINT "comision_periodos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_periodos" ADD CONSTRAINT "comision_periodos_politica_id_fkey" FOREIGN KEY (politica_id) REFERENCES oymcomercial.comision_politicas(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."comision_politica_versiones" ADD CONSTRAINT "comision_politica_versiones_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."comision_politica_versiones" ADD CONSTRAINT "comision_politica_versiones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_politica_versiones" ADD CONSTRAINT "comision_politica_versiones_politica_id_fkey" FOREIGN KEY (politica_id) REFERENCES oymcomercial.comision_politicas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "comision_politicas_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "comision_politicas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."comision_politicas" ADD CONSTRAINT "comision_politicas_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_proveedor_id_fkey" FOREIGN KEY (proveedor_id) REFERENCES oymcomercial.proveedores(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."compras" ADD CONSTRAINT "compras_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."crm_etapas" ADD CONSTRAINT "crm_etapas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."crm_notas" ADD CONSTRAINT "crm_notas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."crm_notas" ADD CONSTRAINT "crm_notas_prospecto_id_fkey" FOREIGN KEY (prospecto_id) REFERENCES oymcomercial.crm_prospectos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."crm_prospectos" ADD CONSTRAINT "crm_prospectos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."cuentas_por_cobrar" ADD CONSTRAINT "cuentas_por_cobrar_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."empresa_autoimpresor_config" ADD CONSTRAINT "empresa_autoimpresor_config_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."empresa_dashboard_views" ADD CONSTRAINT "empresa_dashboard_views_dashboard_view_id_fkey" FOREIGN KEY (dashboard_view_id) REFERENCES oymcomercial.dashboard_views(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."empresa_dashboard_views" ADD CONSTRAINT "empresa_dashboard_views_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."empresa_facturacion_modo" ADD CONSTRAINT "empresa_facturacion_modo_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."empresa_modulos" ADD CONSTRAINT "empresa_modulos_modulo_id_fkey" FOREIGN KEY (modulo_id) REFERENCES oymcomercial.modulos(id);
ALTER TABLE "oymcomercial"."empresa_sifen_config" ADD CONSTRAINT "empresa_sifen_config_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."factura_electronica" ADD CONSTRAINT "factura_electronica_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."factura_electronica" ADD CONSTRAINT "factura_electronica_factura_id_fkey" FOREIGN KEY (factura_id) REFERENCES oymcomercial.facturas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."factura_electronica" ADD CONSTRAINT "factura_electronica_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."factura_electronica_evento" ADD CONSTRAINT "factura_electronica_evento_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."factura_electronica_evento" ADD CONSTRAINT "factura_electronica_evento_factura_electronica_id_fkey" FOREIGN KEY (factura_electronica_id) REFERENCES oymcomercial.factura_electronica(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."factura_items" ADD CONSTRAINT "factura_items_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."factura_items" ADD CONSTRAINT "factura_items_factura_id_fkey" FOREIGN KEY (factura_id) REFERENCES oymcomercial.facturas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."facturas" ADD CONSTRAINT "facturas_suscripcion_id_fkey" FOREIGN KEY (suscripcion_id) REFERENCES oymcomercial.suscripciones(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."gastos" ADD CONSTRAINT "gastos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."gastos" ADD CONSTRAINT "gastos_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."imports_audit" ADD CONSTRAINT "imports_audit_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."inventario_stock_ubicacion" ADD CONSTRAINT "inventario_stock_ubicacion_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."inventario_stock_ubicacion" ADD CONSTRAINT "inventario_stock_ubicacion_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."inventario_stock_ubicacion" ADD CONSTRAINT "inventario_stock_ubicacion_ubicacion_id_fkey" FOREIGN KEY (ubicacion_id) REFERENCES oymcomercial.inventario_ubicaciones(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."inventario_ubicaciones" ADD CONSTRAINT "inventario_ubicaciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."inventario_ubicaciones" ADD CONSTRAINT "inventario_ubicaciones_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES oymcomercial.inventario_ubicaciones(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_calendarios" ADD CONSTRAINT "marketing_calendarios_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_calendarios" ADD CONSTRAINT "marketing_calendarios_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_calendarios" ADD CONSTRAINT "marketing_calendarios_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_calendarios" ADD CONSTRAINT "marketing_calendarios_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_comentarios" ADD CONSTRAINT "marketing_comentarios_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_comentarios" ADD CONSTRAINT "marketing_comentarios_pieza_id_fkey" FOREIGN KEY (pieza_id) REFERENCES oymcomercial.marketing_piezas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_comentarios" ADD CONSTRAINT "marketing_comentarios_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_historial_estados" ADD CONSTRAINT "marketing_historial_estados_changed_by_fkey" FOREIGN KEY (changed_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_historial_estados" ADD CONSTRAINT "marketing_historial_estados_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_historial_estados" ADD CONSTRAINT "marketing_historial_estados_pieza_id_fkey" FOREIGN KEY (pieza_id) REFERENCES oymcomercial.marketing_piezas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_calendario_id_fkey" FOREIGN KEY (calendario_id) REFERENCES oymcomercial.marketing_calendarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_responsable_id_fkey" FOREIGN KEY (responsable_id) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_piezas" ADD CONSTRAINT "marketing_piezas_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_plan_id_fkey" FOREIGN KEY (plan_id) REFERENCES oymcomercial.planes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_responsable_user_id_fkey" FOREIGN KEY (responsable_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."marketing_tasks" ADD CONSTRAINT "marketing_tasks_suscripcion_id_fkey" FOREIGN KEY (suscripcion_id) REFERENCES oymcomercial.suscripciones(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."movimientos_inventario" ADD CONSTRAINT "movimientos_inventario_venta_id_fkey" FOREIGN KEY (venta_id) REFERENCES oymcomercial.ventas(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_factura_electronica_origen_id_fkey" FOREIGN KEY (factura_electronica_origen_id) REFERENCES oymcomercial.factura_electronica(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_factura_id_fkey" FOREIGN KEY (factura_id) REFERENCES oymcomercial.facturas(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."nota_credito" ADD CONSTRAINT "nota_credito_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."nota_credito_electronica" ADD CONSTRAINT "nota_credito_electronica_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."nota_credito_electronica" ADD CONSTRAINT "nota_credito_electronica_nota_credito_id_fkey" FOREIGN KEY (nota_credito_id) REFERENCES oymcomercial.nota_credito(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."nota_credito_evento" ADD CONSTRAINT "nota_credito_evento_actor_user_id_fkey" FOREIGN KEY (actor_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."nota_credito_evento" ADD CONSTRAINT "nota_credito_evento_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."nota_credito_evento" ADD CONSTRAINT "nota_credito_evento_nota_credito_id_fkey" FOREIGN KEY (nota_credito_id) REFERENCES oymcomercial.nota_credito(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."nota_credito_items" ADD CONSTRAINT "nota_credito_items_nota_credito_id_fkey" FOREIGN KEY (nota_credito_id) REFERENCES oymcomercial.nota_credito(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."omnichannel_routes" ADD CONSTRAINT "omnichannel_routes_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_factura_id_fkey" FOREIGN KEY (factura_id) REFERENCES oymcomercial.facturas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."pagos" ADD CONSTRAINT "pagos_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."planes" ADD CONSTRAINT "planes_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."presupuesto_items" ADD CONSTRAINT "presupuesto_items_presupuesto_id_fkey" FOREIGN KEY (presupuesto_id) REFERENCES oymcomercial.presupuestos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."presupuestos" ADD CONSTRAINT "presupuestos_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."produccion_items" ADD CONSTRAINT "produccion_items_produccion_id_fkey" FOREIGN KEY (produccion_id) REFERENCES oymcomercial.producciones(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."producciones" ADD CONSTRAINT "producciones_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."producto_categorias" ADD CONSTRAINT "producto_categorias_categoria_id_fkey" FOREIGN KEY (categoria_id) REFERENCES oymcomercial.categorias_productos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."producto_categorias" ADD CONSTRAINT "producto_categorias_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."producto_categorias" ADD CONSTRAINT "producto_categorias_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."producto_categorias" ADD CONSTRAINT "producto_categorias_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_categoria_principal_id_fkey" FOREIGN KEY (categoria_principal_id) REFERENCES oymcomercial.categorias_productos(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_proveedor_principal_id_fkey" FOREIGN KEY (proveedor_principal_id) REFERENCES oymcomercial.proveedores(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."productos" ADD CONSTRAINT "productos_ubicacion_principal_id_fkey" FOREIGN KEY (ubicacion_principal_id) REFERENCES oymcomercial.inventario_ubicaciones(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proveedor_categoria_rel" ADD CONSTRAINT "proveedor_categoria_rel_categoria_id_fkey" FOREIGN KEY (categoria_id) REFERENCES oymcomercial.proveedor_categorias(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedor_categoria_rel" ADD CONSTRAINT "proveedor_categoria_rel_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedor_categoria_rel" ADD CONSTRAINT "proveedor_categoria_rel_proveedor_id_fkey" FOREIGN KEY (proveedor_id) REFERENCES oymcomercial.proveedores(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedor_categorias" ADD CONSTRAINT "proveedor_categorias_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedor_productos" ADD CONSTRAINT "proveedor_productos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedor_productos" ADD CONSTRAINT "proveedor_productos_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedor_productos" ADD CONSTRAINT "proveedor_productos_proveedor_id_fkey" FOREIGN KEY (proveedor_id) REFERENCES oymcomercial.proveedores(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proveedores" ADD CONSTRAINT "proveedores_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_archivos" ADD CONSTRAINT "proyecto_archivos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_archivos" ADD CONSTRAINT "proyecto_archivos_proyecto_id_fkey" FOREIGN KEY (proyecto_id) REFERENCES oymcomercial.proyectos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_archivos" ADD CONSTRAINT "proyecto_archivos_uploaded_by_fkey" FOREIGN KEY (uploaded_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyecto_comentarios" ADD CONSTRAINT "proyecto_comentarios_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_comentarios" ADD CONSTRAINT "proyecto_comentarios_proyecto_id_fkey" FOREIGN KEY (proyecto_id) REFERENCES oymcomercial.proyectos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_comentarios" ADD CONSTRAINT "proyecto_comentarios_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ADD CONSTRAINT "proyecto_estado_historial_changed_by_fkey" FOREIGN KEY (changed_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ADD CONSTRAINT "proyecto_estado_historial_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ADD CONSTRAINT "proyecto_estado_historial_estado_anterior_id_fkey" FOREIGN KEY (estado_anterior_id) REFERENCES oymcomercial.proyecto_estados(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ADD CONSTRAINT "proyecto_estado_historial_estado_nuevo_id_fkey" FOREIGN KEY (estado_nuevo_id) REFERENCES oymcomercial.proyecto_estados(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ADD CONSTRAINT "proyecto_estado_historial_proyecto_id_fkey" FOREIGN KEY (proyecto_id) REFERENCES oymcomercial.proyectos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_estados" ADD CONSTRAINT "proyecto_estados_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ADD CONSTRAINT "proyecto_prioridades_config_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "proyecto_tareas_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "proyecto_tareas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "proyecto_tareas_proyecto_id_fkey" FOREIGN KEY (proyecto_id) REFERENCES oymcomercial.proyectos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyecto_tareas" ADD CONSTRAINT "proyecto_tareas_responsable_id_fkey" FOREIGN KEY (responsable_id) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyecto_tipos" ADD CONSTRAINT "proyecto_tipos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_created_by_fkey" FOREIGN KEY (created_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_estado_id_fkey" FOREIGN KEY (estado_id) REFERENCES oymcomercial.proyecto_estados(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_responsable_comercial_id_fkey" FOREIGN KEY (responsable_comercial_id) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_responsable_tecnico_id_fkey" FOREIGN KEY (responsable_tecnico_id) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_tipo_id_fkey" FOREIGN KEY (tipo_id) REFERENCES oymcomercial.proyecto_tipos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."proyectos" ADD CONSTRAINT "proyectos_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_insumo_producto_id_fkey" FOREIGN KEY (insumo_producto_id) REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."receta_items" ADD CONSTRAINT "receta_items_receta_id_fkey" FOREIGN KEY (receta_id) REFERENCES oymcomercial.recetas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."recetas" ADD CONSTRAINT "recetas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."recetas" ADD CONSTRAINT "recetas_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."recetas" ADD CONSTRAINT "recetas_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."recibos_dinero" ADD CONSTRAINT "recibos_dinero_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibos_dinero_items_cobro_cliente_id_fkey" FOREIGN KEY (cobro_cliente_id) REFERENCES oymcomercial.cobros_clientes(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibos_dinero_items_cuenta_por_cobrar_id_fkey" FOREIGN KEY (cuenta_por_cobrar_id) REFERENCES oymcomercial.cuentas_por_cobrar(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibos_dinero_items_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibos_dinero_items_factura_id_fkey" FOREIGN KEY (factura_id) REFERENCES oymcomercial.facturas(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."recibos_dinero_items" ADD CONSTRAINT "recibos_dinero_items_recibo_id_fkey" FOREIGN KEY (recibo_id) REFERENCES oymcomercial.recibos_dinero(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_factura_electronica_id_fkey" FOREIGN KEY (factura_electronica_id) REFERENCES oymcomercial.factura_electronica(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sifen_jobs" ADD CONSTRAINT "sifen_jobs_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."sorteo_conversaciones" ADD CONSTRAINT "sorteo_conversaciones_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_conversaciones" ADD CONSTRAINT "sorteo_conversaciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_conversaciones" ADD CONSTRAINT "sorteo_conversaciones_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_cupones" ADD CONSTRAINT "sorteo_cupones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_cupones" ADD CONSTRAINT "sorteo_cupones_entrada_id_fkey" FOREIGN KEY (entrada_id) REFERENCES oymcomercial.sorteo_entradas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_cupones" ADD CONSTRAINT "sorteo_cupones_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_chat_conversation_id_fkey" FOREIGN KEY (chat_conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_comprobante_validacion_id_fkey" FOREIGN KEY (comprobante_validacion_id) REFERENCES oymcomercial.chat_comprobante_validaciones(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_conversacion_id_fkey" FOREIGN KEY (conversacion_id) REFERENCES oymcomercial.sorteo_conversaciones(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_revendedor_id_fkey" FOREIGN KEY (revendedor_id) REFERENCES oymcomercial.sorteo_revendedores(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_entradas" ADD CONSTRAINT "sorteo_entradas_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ADD CONSTRAINT "sorteo_revendedor_clicks_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ADD CONSTRAINT "sorteo_revendedor_clicks_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ADD CONSTRAINT "sorteo_revendedor_clicks_flow_session_id_fkey" FOREIGN KEY (flow_session_id) REFERENCES oymcomercial.chat_flow_sessions(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ADD CONSTRAINT "sorteo_revendedor_clicks_revendedor_id_fkey" FOREIGN KEY (revendedor_id) REFERENCES oymcomercial.sorteo_revendedores(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ADD CONSTRAINT "sorteo_revendedor_clicks_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_revendedores" ADD CONSTRAINT "sorteo_revendedores_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_revendedores" ADD CONSTRAINT "sorteo_revendedores_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES oymcomercial.chat_conversations(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_entrada_id_fkey" FOREIGN KEY (entrada_id) REFERENCES oymcomercial.sorteo_entradas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ADD CONSTRAINT "sorteo_ticket_deliveries_sorteo_id_fkey" FOREIGN KEY (sorteo_id) REFERENCES oymcomercial.sorteos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sorteos" ADD CONSTRAINT "sorteos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."sucursales" ADD CONSTRAINT "sucursales_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."suscripciones" ADD CONSTRAINT "suscripciones_plan_id_fkey" FOREIGN KEY (plan_id) REFERENCES oymcomercial.planes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."tipificaciones" ADD CONSTRAINT "tipificaciones_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."tipificaciones" ADD CONSTRAINT "tipificaciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_aprobada_por_fkey" FOREIGN KEY (aprobada_por) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_despachada_por_fkey" FOREIGN KEY (despachada_por) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_recibida_por_fkey" FOREIGN KEY (recibida_por) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_solicitada_por_fkey" FOREIGN KEY (solicitada_por) REFERENCES oymcomercial.usuarios(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_sucursal_destino_id_fkey" FOREIGN KEY (sucursal_destino_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."transferencias_inventario" ADD CONSTRAINT "transferencias_inventario_sucursal_origen_id_fkey" FOREIGN KEY (sucursal_origen_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transferencias_inventario_items_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transferencias_inventario_items_producto_destino_id_fkey" FOREIGN KEY (producto_destino_id) REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transferencias_inventario_items_producto_origen_id_fkey" FOREIGN KEY (producto_origen_id) REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ADD CONSTRAINT "transferencias_inventario_items_transferencia_id_fkey" FOREIGN KEY (transferencia_id) REFERENCES oymcomercial.transferencias_inventario(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."usuario_dashboard_views" ADD CONSTRAINT "usuario_dashboard_views_dashboard_view_id_fkey" FOREIGN KEY (dashboard_view_id) REFERENCES oymcomercial.dashboard_views(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."usuario_dashboard_views" ADD CONSTRAINT "usuario_dashboard_views_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."usuario_modulos" ADD CONSTRAINT "usuario_modulos_modulo_id_fkey" FOREIGN KEY (modulo_id) REFERENCES oymcomercial.modulos(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."usuario_modulos" ADD CONSTRAINT "usuario_modulos_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES oymcomercial.usuarios(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_auth_user_id_fkey" FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."usuarios" ADD CONSTRAINT "usuarios_sucursal_predeterminada_id_fkey" FOREIGN KEY (sucursal_predeterminada_id) REFERENCES oymcomercial.sucursales(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES oymcomercial.clientes(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_factura_id_fkey" FOREIGN KEY (factura_id) REFERENCES oymcomercial.facturas(id) ON DELETE SET NULL;
ALTER TABLE "oymcomercial"."ventas" ADD CONSTRAINT "ventas_sucursal_id_fkey" FOREIGN KEY (sucursal_id) REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."ventas_items" ADD CONSTRAINT "ventas_items_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES oymcomercial.empresas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."ventas_items" ADD CONSTRAINT "ventas_items_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT;
ALTER TABLE "oymcomercial"."ventas_items" ADD CONSTRAINT "ventas_items_venta_id_fkey" FOREIGN KEY (venta_id) REFERENCES oymcomercial.ventas(id) ON DELETE CASCADE;
ALTER TABLE "oymcomercial"."ventas_pagos_detalle" ADD CONSTRAINT "ventas_pagos_detalle_entidad_bancaria_id_fkey" FOREIGN KEY (entidad_bancaria_id) REFERENCES oymcomercial.entidades_bancarias(id) ON DELETE SET NULL;

-- ---------- INDEXES ----------
CREATE INDEX idx_categorias_productos_activo ON oymcomercial.categorias_productos USING btree (activo);
CREATE INDEX idx_categorias_productos_empresa ON oymcomercial.categorias_productos USING btree (empresa_id);
CREATE INDEX idx_categorias_productos_nombre ON oymcomercial.categorias_productos USING btree (nombre);
CREATE INDEX idx_categorias_productos_parent ON oymcomercial.categorias_productos USING btree (parent_id);
CREATE INDEX idx_categorias_productos_sucursal ON oymcomercial.categorias_productos USING btree (sucursal_id);
CREATE UNIQUE INDEX uq_categorias_productos_empresa_sucursal_nombre ON oymcomercial.categorias_productos USING btree (empresa_id, sucursal_id, lower(btrim(nombre)));
CREATE INDEX idx_chat_agents_empresa ON oymcomercial.chat_agents USING btree (empresa_id);
CREATE INDEX idx_chat_agents_online ON oymcomercial.chat_agents USING btree (queue_id, is_online) WHERE (is_online = true);
CREATE INDEX idx_chat_agents_queue ON oymcomercial.chat_agents USING btree (queue_id);
CREATE INDEX idx_chat_campaign_events_e_c_cr ON oymcomercial.chat_campaign_events USING btree (empresa_id, campaign_id, created_at DESC);
CREATE INDEX idx_chat_campaign_events_rec ON oymcomercial.chat_campaign_events USING btree (recipient_id);
CREATE INDEX idx_chat_campaign_jobs_c ON oymcomercial.chat_campaign_jobs USING btree (campaign_id);
CREATE INDEX idx_chat_campaign_jobs_e_st ON oymcomercial.chat_campaign_jobs USING btree (empresa_id, status, created_at);
CREATE INDEX idx_chat_campaign_recipients_conv ON oymcomercial.chat_campaign_recipients USING btree (conversation_id);
CREATE INDEX idx_chat_campaign_recipients_e_c_st ON oymcomercial.chat_campaign_recipients USING btree (empresa_id, campaign_id, status);
CREATE INDEX idx_chat_campaign_recipients_wamid ON oymcomercial.chat_campaign_recipients USING btree (provider_message_id);
CREATE UNIQUE INDEX uq_chat_campaign_recipients_phone ON oymcomercial.chat_campaign_recipients USING btree (campaign_id, phone_e164);
CREATE INDEX idx_chat_campaign_templates_ch_st ON oymcomercial.chat_campaign_templates USING btree (empresa_id, channel_id, status);
CREATE UNIQUE INDEX uq_chat_campaign_templates_natural ON oymcomercial.chat_campaign_templates USING btree (empresa_id, channel_id, provider, name, language);
CREATE INDEX idx_chat_campaigns_e_ch ON oymcomercial.chat_campaigns USING btree (empresa_id, channel_id);
CREATE INDEX idx_chat_campaigns_e_q ON oymcomercial.chat_campaigns USING btree (empresa_id, queue_id);
CREATE INDEX idx_chat_campaigns_e_st_cr ON oymcomercial.chat_campaigns USING btree (empresa_id, status, created_at DESC);
CREATE INDEX idx_chat_channel_quick_replies_ch ON oymcomercial.chat_channel_quick_replies USING btree (channel_id, sort_order);
CREATE INDEX idx_chat_channel_quick_replies_e ON oymcomercial.chat_channel_quick_replies USING btree (empresa_id);
CREATE UNIQUE INDEX chat_channels_meta_phone_number_id_uidx ON oymcomercial.chat_channels USING btree (meta_phone_number_id) WHERE ((meta_phone_number_id IS NOT NULL) AND (btrim(meta_phone_number_id) <> ''::text));
CREATE INDEX idx_chat_channels_empresa ON oymcomercial.chat_channels USING btree (empresa_id);
CREATE INDEX idx_chat_channels_empresa_activo ON oymcomercial.chat_channels USING btree (empresa_id, activo) WHERE (activo = true);
CREATE INDEX idx_chat_comp_val_conversation ON oymcomercial.chat_comprobante_validaciones USING btree (conversation_id, created_at DESC);
CREATE INDEX idx_chat_comp_val_empresa_hash ON oymcomercial.chat_comprobante_validaciones USING btree (empresa_id, comprobante_hash);
CREATE INDEX idx_chat_comp_val_empresa_ocr_fp ON oymcomercial.chat_comprobante_validaciones USING btree (empresa_id, ocr_fingerprint) WHERE ((ocr_fingerprint IS NOT NULL) AND (length(TRIM(BOTH FROM ocr_fingerprint)) > 0));
CREATE INDEX idx_chat_comp_val_entrada ON oymcomercial.chat_comprobante_validaciones USING btree (sorteo_entrada_id) WHERE (sorteo_entrada_id IS NOT NULL);
CREATE INDEX idx_chat_comp_val_flow_session ON oymcomercial.chat_comprobante_validaciones USING btree (flow_session_id);
CREATE INDEX idx_chat_contacts_cliente ON oymcomercial.chat_contacts USING btree (cliente_id);
CREATE INDEX idx_chat_contacts_empresa ON oymcomercial.chat_contacts USING btree (empresa_id);
CREATE INDEX idx_chat_contacts_empresa_name_lower ON oymcomercial.chat_contacts USING btree (empresa_id, lower(name));
CREATE INDEX idx_chat_contacts_empresa_phone_normalized ON oymcomercial.chat_contacts USING btree (empresa_id, phone_normalized);
CREATE INDEX idx_chat_contacts_prospecto ON oymcomercial.chat_contacts USING btree (crm_prospecto_id);
CREATE INDEX idx_chat_conversation_closures_agent ON oymcomercial.chat_conversation_closures USING btree (empresa_id, closed_by_usuario_id, closed_at DESC);
CREATE INDEX idx_chat_conversation_closures_conv ON oymcomercial.chat_conversation_closures USING btree (conversation_id);
CREATE INDEX idx_chat_conversation_closures_empresa_closed ON oymcomercial.chat_conversation_closures USING btree (empresa_id, closed_at DESC);
CREATE INDEX idx_chat_conversation_closures_labels ON oymcomercial.chat_conversation_closures USING btree (empresa_id, closure_state_label, closure_substate_label);
CREATE INDEX idx_chat_conversation_closures_queue ON oymcomercial.chat_conversation_closures USING btree (empresa_id, queue_id, closed_at DESC);
CREATE INDEX idx_chat_conv_emp_unassigned_recent ON oymcomercial.chat_conversations USING btree (empresa_id, last_message_at DESC NULLS LAST) WHERE ((assigned_agent_id IS NULL) AND (status = ANY (ARRAY['open'::text, 'pending'::text])));
CREATE INDEX idx_chat_conv_empresa_last ON oymcomercial.chat_conversations USING btree (empresa_id, last_message_at DESC NULLS LAST);
CREATE INDEX idx_chat_conversations_active_flow_session ON oymcomercial.chat_conversations USING btree (active_flow_session_id);
CREATE INDEX idx_chat_conversations_assigned_agent ON oymcomercial.chat_conversations USING btree (assigned_agent_id) WHERE (assigned_agent_id IS NOT NULL);
CREATE INDEX idx_chat_conversations_first_revendedor ON oymcomercial.chat_conversations USING btree (first_revendedor_id) WHERE (first_revendedor_id IS NOT NULL);
CREATE INDEX idx_chat_conversations_queue ON oymcomercial.chat_conversations USING btree (queue_id) WHERE (queue_id IS NOT NULL);
CREATE INDEX idx_chat_empresa_operator_roles_empresa ON oymcomercial.chat_empresa_operator_roles USING btree (empresa_id);
CREATE INDEX idx_chat_flow_data_empresa_conversation ON oymcomercial.chat_flow_data USING btree (empresa_id, conversation_id);
CREATE INDEX idx_chat_flow_data_flow_session ON oymcomercial.chat_flow_data USING btree (flow_session_id);
CREATE UNIQUE INDEX uq_chat_flow_data_conversation_field ON oymcomercial.chat_flow_data USING btree (conversation_id, field_name);
CREATE UNIQUE INDEX uq_chat_flow_data_session_field ON oymcomercial.chat_flow_data USING btree (flow_session_id, field_name);
CREATE INDEX idx_chat_flow_events_conv_created_desc ON oymcomercial.chat_flow_events USING btree (conversation_id, created_at DESC);
CREATE INDEX idx_chat_flow_events_session_created ON oymcomercial.chat_flow_events USING btree (flow_session_id, created_at);
CREATE INDEX idx_chat_flow_node_blocks_empresa ON oymcomercial.chat_flow_node_blocks USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_chat_flow_node_blocks_node_order ON oymcomercial.chat_flow_node_blocks USING btree (node_id, sort_order, created_at);
CREATE INDEX idx_chat_flow_nodes_empresa_flow ON oymcomercial.chat_flow_nodes USING btree (empresa_id, flow_code);
CREATE INDEX idx_chat_flow_nodes_empresa_flow_sort ON oymcomercial.chat_flow_nodes USING btree (empresa_id, flow_code, sort_order);
CREATE INDEX idx_chat_flow_options_node_sort ON oymcomercial.chat_flow_options USING btree (node_id, sort_order);
CREATE INDEX idx_cfr_rules_empresa_flow ON oymcomercial.chat_flow_recontact_rules USING btree (empresa_id, flow_code);
CREATE INDEX idx_cfr_rules_flow_prio ON oymcomercial.chat_flow_recontact_rules USING btree (flow_code, prioridad);
CREATE INDEX idx_cfr_runs_empresa_created ON oymcomercial.chat_flow_recontact_runs USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_cfr_runs_rule_created ON oymcomercial.chat_flow_recontact_runs USING btree (rule_id, created_at DESC);
CREATE INDEX idx_chat_flow_sessions_conversation ON oymcomercial.chat_flow_sessions USING btree (conversation_id, flow_code, status);
CREATE INDEX idx_chat_flow_sessions_empresa ON oymcomercial.chat_flow_sessions USING btree (empresa_id);
CREATE INDEX idx_chat_flow_sessions_revendedor ON oymcomercial.chat_flow_sessions USING btree (revendedor_id) WHERE (revendedor_id IS NOT NULL);
CREATE UNIQUE INDEX uq_chat_flow_sessions_one_active_per_conversation ON oymcomercial.chat_flow_sessions USING btree (conversation_id) WHERE (status = 'active'::text);
CREATE INDEX idx_chat_flows_empresa ON oymcomercial.chat_flows USING btree (empresa_id);
CREATE INDEX idx_chat_flows_sorteo ON oymcomercial.chat_flows USING btree (sorteo_id) WHERE (sorteo_id IS NOT NULL);
CREATE INDEX idx_chat_messages_empresa_created_at ON oymcomercial.chat_messages USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_chat_messages_sender_type ON oymcomercial.chat_messages USING btree (sender_type);
CREATE INDEX idx_chat_msg_conv ON oymcomercial.chat_messages USING btree (conversation_id, created_at);
CREATE INDEX idx_chat_msg_empresa ON oymcomercial.chat_messages USING btree (empresa_id);
CREATE UNIQUE INDEX uq_chat_msg_wa_id ON oymcomercial.chat_messages USING btree (wa_message_id) WHERE (wa_message_id IS NOT NULL);
CREATE INDEX idx_chat_omn_sched_activo ON oymcomercial.chat_omnicanal_work_schedules USING btree (empresa_id, is_active);
CREATE INDEX idx_chat_omn_sched_empresa ON oymcomercial.chat_omnicanal_work_schedules USING btree (empresa_id);
CREATE INDEX idx_chat_queue_channels_channel ON oymcomercial.chat_queue_channels USING btree (channel_id);
CREATE INDEX idx_chat_queue_channels_empresa ON oymcomercial.chat_queue_channels USING btree (empresa_id);
CREATE INDEX idx_chat_queue_channels_queue ON oymcomercial.chat_queue_channels USING btree (queue_id);
CREATE INDEX idx_chat_closure_states_empresa ON oymcomercial.chat_queue_closure_states USING btree (empresa_id);
CREATE INDEX idx_chat_closure_states_queue ON oymcomercial.chat_queue_closure_states USING btree (queue_id, sort_order);
CREATE INDEX idx_chat_closure_substates_state ON oymcomercial.chat_queue_closure_substates USING btree (closure_state_id, sort_order);
CREATE INDEX idx_chat_queue_supervisors_empresa_usuario ON oymcomercial.chat_queue_supervisors USING btree (empresa_id, usuario_id);
CREATE INDEX idx_chat_queues_empresa_active ON oymcomercial.chat_queues USING btree (empresa_id, is_active) WHERE (is_active = true);
CREATE INDEX idx_cre_conv ON oymcomercial.chat_routing_events USING btree (conversation_id, created_at DESC);
CREATE INDEX idx_cre_emp ON oymcomercial.chat_routing_events USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_chat_supervisor_agents_supervisor ON oymcomercial.chat_supervisor_agents USING btree (empresa_id, supervisor_usuario_id);
CREATE INDEX idx_chat_usuario_omnicanal_empresa ON oymcomercial.chat_usuario_omnicanal USING btree (empresa_id);
CREATE INDEX idx_chat_usuario_omnicanal_usuario ON oymcomercial.chat_usuario_omnicanal USING btree (usuario_id);
CREATE INDEX idx_cliente_historial_cliente_at ON oymcomercial.cliente_historial USING btree (cliente_id, created_at DESC);
CREATE INDEX idx_cliente_historial_empresa_at ON oymcomercial.cliente_historial USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_cliente_obligaciones_empresa ON oymcomercial.cliente_obligaciones_tributarias USING btree (empresa_id);
CREATE INDEX idx_cliente_obligaciones_perfil ON oymcomercial.cliente_obligaciones_tributarias USING btree (cliente_perfil_id);
CREATE INDEX idx_cliente_perfil_tributario_cliente ON oymcomercial.cliente_perfil_tributario USING btree (cliente_id);
CREATE INDEX idx_cliente_perfil_tributario_empresa ON oymcomercial.cliente_perfil_tributario USING btree (empresa_id);
CREATE INDEX ixctsc_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.cliente_tipos_servicio_catalogo USING btree (empresa_id, activo, orden);
CREATE INDEX idx_clientes_baja_operativa_at ON oymcomercial.clientes USING btree (baja_operativa_at) WHERE (baja_operativa_at IS NOT NULL);
CREATE INDEX idx_clientes_created_by ON oymcomercial.clientes USING btree (created_by_user_id);
CREATE INDEX idx_clientes_deleted_at ON oymcomercial.clientes USING btree (deleted_at) WHERE (deleted_at IS NOT NULL);
CREATE INDEX idx_clientes_tipo_servicio ON oymcomercial.clientes USING btree (tipo_servicio_cliente) WHERE (tipo_servicio_cliente IS NOT NULL);
CREATE INDEX ix_cli_vend_93405e10933cb8b99a0af6286dc9466b ON oymcomercial.clientes USING btree (empresa_id, vendedor_usuario_id);
CREATE INDEX ix_cli_vend_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.clientes USING btree (empresa_id, vendedor_usuario_id);
CREATE INDEX idx_cobros_cliente ON oymcomercial.cobros_clientes USING btree (empresa_id, cliente_id);
CREATE INDEX idx_cobros_clientes_sucursal ON oymcomercial.cobros_clientes USING btree (sucursal_id);
CREATE INDEX idx_cobros_cuenta ON oymcomercial.cobros_clientes USING btree (cuenta_por_cobrar_id);
CREATE INDEX idx_cobros_empresa_fecha ON oymcomercial.cobros_clientes USING btree (empresa_id, fecha_pago DESC);
CREATE INDEX ix_caj_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_ajustes USING btree (empresa_id, periodo_id);
CREATE INDEX ix_ceqm_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_equipo_miembros USING btree (empresa_id, equipo_id);
CREATE INDEX ix_ceq_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_equipos USING btree (empresa_id, activo);
CREATE INDEX ix_ce_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_escalas USING btree (empresa_id, politica_id, orden);
CREATE INDEX ix_clin_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_lineas USING btree (empresa_id, periodo_id, usuario_vendedor_id);
CREATE INDEX ix_cper_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_periodos USING btree (empresa_id, fecha_inicio, fecha_fin);
CREATE INDEX ix_cpv_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_politica_versiones USING btree (empresa_id, politica_id);
CREATE INDEX ix_cp_act_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.comision_politicas USING btree (empresa_id, activo);
CREATE INDEX idx_compras_created_by ON oymcomercial.compras USING btree (created_by);
CREATE INDEX idx_compras_empresa ON oymcomercial.compras USING btree (empresa_id);
CREATE INDEX idx_compras_empresa_fecha ON oymcomercial.compras USING btree (empresa_id, fecha DESC);
CREATE INDEX idx_compras_empresa_numero ON oymcomercial.compras USING btree (empresa_id, numero_control);
CREATE INDEX idx_compras_estado_anulada ON oymcomercial.compras USING btree (empresa_id, estado) WHERE (estado = 'anulada'::text);
CREATE INDEX idx_compras_fecha ON oymcomercial.compras USING btree (fecha);
CREATE INDEX idx_compras_producto ON oymcomercial.compras USING btree (producto_id);
CREATE INDEX idx_compras_proveedor ON oymcomercial.compras USING btree (proveedor_id);
CREATE INDEX idx_compras_sucursal ON oymcomercial.compras USING btree (sucursal_id);
CREATE INDEX idx_crm_etapas_empresa ON oymcomercial.crm_etapas USING btree (empresa_id);
CREATE INDEX idx_crm_etapas_empresa_orden ON oymcomercial.crm_etapas USING btree (empresa_id, orden);
CREATE INDEX idx_crm_notas_empresa ON oymcomercial.crm_notas USING btree (empresa_id);
CREATE INDEX idx_crm_notas_prospecto ON oymcomercial.crm_notas USING btree (prospecto_id);
CREATE INDEX idx_crm_prospectos_empresa ON oymcomercial.crm_prospectos USING btree (empresa_id);
CREATE INDEX idx_crm_prospectos_empresa_origen ON oymcomercial.crm_prospectos USING btree (empresa_id, origen_creacion);
CREATE INDEX idx_crm_prospectos_etapa ON oymcomercial.crm_prospectos USING btree (etapa);
CREATE INDEX idx_cuentas_por_cobrar_sucursal ON oymcomercial.cuentas_por_cobrar USING btree (sucursal_id);
CREATE INDEX idx_cxc_cliente ON oymcomercial.cuentas_por_cobrar USING btree (empresa_id, cliente_id);
CREATE INDEX idx_cxc_empresa_estado ON oymcomercial.cuentas_por_cobrar USING btree (empresa_id, estado);
CREATE INDEX idx_cxc_vencimiento ON oymcomercial.cuentas_por_cobrar USING btree (empresa_id, fecha_vencimiento);
CREATE UNIQUE INDEX uq_cxc_venta ON oymcomercial.cuentas_por_cobrar USING btree (venta_id);
CREATE INDEX idx_dashboard_views_activo ON oymcomercial.dashboard_views USING btree (activo);
CREATE INDEX idx_edv_empresa ON oymcomercial.empresa_dashboard_views USING btree (empresa_id);
CREATE INDEX idx_edv_view ON oymcomercial.empresa_dashboard_views USING btree (dashboard_view_id);
CREATE UNIQUE INDEX empresas_data_schema_unique ON oymcomercial.empresas USING btree (data_schema) WHERE (data_schema IS NOT NULL);
CREATE INDEX ix_entidades_bancarias_empresa_activo ON oymcomercial.entidades_bancarias USING btree (empresa_id, activo);
CREATE UNIQUE INDEX uq_entidades_bancarias_codigo ON oymcomercial.entidades_bancarias USING btree (empresa_id, lower(codigo)) WHERE ((codigo IS NOT NULL) AND (codigo <> ''::text));
CREATE UNIQUE INDEX uq_entidades_bancarias_empresa_nombre ON oymcomercial.entidades_bancarias USING btree (empresa_id, lower(nombre));
CREATE INDEX idx_factura_electronica_empresa ON oymcomercial.factura_electronica USING btree (empresa_id);
CREATE INDEX idx_factura_electronica_empresa_estado ON oymcomercial.factura_electronica USING btree (empresa_id, estado_sifen);
CREATE INDEX idx_factura_electronica_factura ON oymcomercial.factura_electronica USING btree (factura_id);
CREATE INDEX idx_factura_electronica_sucursal ON oymcomercial.factura_electronica USING btree (sucursal_id);
CREATE INDEX idx_factura_electronica_evento_de ON oymcomercial.factura_electronica_evento USING btree (factura_electronica_id);
CREATE INDEX idx_factura_electronica_evento_empresa ON oymcomercial.factura_electronica_evento USING btree (empresa_id);
CREATE INDEX idx_factura_electronica_evento_empresa_created ON oymcomercial.factura_electronica_evento USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_factura_items_empresa ON oymcomercial.factura_items USING btree (empresa_id);
CREATE INDEX idx_factura_items_factura ON oymcomercial.factura_items USING btree (factura_id);
CREATE INDEX idx_facturas_cliente ON oymcomercial.facturas USING btree (cliente_id);
CREATE INDEX idx_facturas_empresa ON oymcomercial.facturas USING btree (empresa_id);
CREATE INDEX idx_facturas_fecha ON oymcomercial.facturas USING btree (fecha);
CREATE INDEX idx_facturas_origen_venta ON oymcomercial.facturas USING btree (origen_venta_id);
CREATE INDEX idx_facturas_sucursal ON oymcomercial.facturas USING btree (sucursal_id);
CREATE INDEX idx_facturas_suscripcion ON oymcomercial.facturas USING btree (suscripcion_id);
CREATE UNIQUE INDEX uq_facturas_empresa_sucursal_numero ON oymcomercial.facturas USING btree (empresa_id, sucursal_id, numero_factura);
CREATE INDEX gastos_empresa_fecha_idx ON oymcomercial.gastos USING btree (empresa_id, fecha);
CREATE INDEX idx_gastos_sucursal ON oymcomercial.gastos USING btree (sucursal_id);
CREATE INDEX idx_imports_audit_empresa_fecha ON oymcomercial.imports_audit USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_imports_audit_entidad ON oymcomercial.imports_audit USING btree (entidad);
CREATE INDEX idx_stock_ubic_producto ON oymcomercial.inventario_stock_ubicacion USING btree (producto_id);
CREATE INDEX idx_stock_ubic_ubicacion ON oymcomercial.inventario_stock_ubicacion USING btree (ubicacion_id);
CREATE UNIQUE INDEX uq_stock_ubicacion_principal_unica ON oymcomercial.inventario_stock_ubicacion USING btree (empresa_id, producto_id) WHERE (es_principal = true);
CREATE UNIQUE INDEX uq_stock_ubicacion_triple ON oymcomercial.inventario_stock_ubicacion USING btree (empresa_id, producto_id, ubicacion_id);
CREATE INDEX idx_ubicaciones_empresa ON oymcomercial.inventario_ubicaciones USING btree (empresa_id);
CREATE INDEX idx_ubicaciones_parent ON oymcomercial.inventario_ubicaciones USING btree (parent_id);
CREATE INDEX idx_ubicaciones_tipo ON oymcomercial.inventario_ubicaciones USING btree (tipo);
CREATE UNIQUE INDEX uq_ubicaciones_empresa_codigo ON oymcomercial.inventario_ubicaciones USING btree (empresa_id, lower(TRIM(BOTH FROM codigo))) WHERE ((codigo IS NOT NULL) AND (TRIM(BOTH FROM codigo) <> ''::text));
CREATE INDEX ix_mk_cal_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_calendarios USING btree (empresa_id, cliente_id, mes);
CREATE INDEX ix_mk_com_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_comentarios USING btree (empresa_id, pieza_id, created_at DESC);
CREATE INDEX ix_mk_hist_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_historial_estados USING btree (empresa_id, pieza_id, changed_at DESC);
CREATE INDEX ix_mk_pz_cli_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_piezas USING btree (empresa_id, cliente_id);
CREATE INDEX ix_mk_pz_lim_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_piezas USING btree (empresa_id, fecha_limite);
CREATE INDEX ix_mk_pz_prod_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_piezas USING btree (empresa_id, estado_produccion);
CREATE INDEX ix_mk_pz_resp_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.marketing_piezas USING btree (empresa_id, responsable_id);
CREATE INDEX idx_marketing_tasks_cliente ON oymcomercial.marketing_tasks USING btree (cliente_id);
CREATE INDEX idx_marketing_tasks_empresa ON oymcomercial.marketing_tasks USING btree (empresa_id);
CREATE INDEX idx_marketing_tasks_estado ON oymcomercial.marketing_tasks USING btree (estado);
CREATE INDEX idx_marketing_tasks_fecha ON oymcomercial.marketing_tasks USING btree (fecha_entrega);
CREATE INDEX idx_marketing_tasks_plan ON oymcomercial.marketing_tasks USING btree (plan_id);
CREATE INDEX idx_marketing_tasks_suscripcion ON oymcomercial.marketing_tasks USING btree (suscripcion_id);
CREATE INDEX idx_mov_produccion_id ON oymcomercial.movimientos_inventario USING btree (produccion_id);
CREATE INDEX idx_movimientos_empresa ON oymcomercial.movimientos_inventario USING btree (empresa_id);
CREATE INDEX idx_movimientos_fecha ON oymcomercial.movimientos_inventario USING btree (fecha);
CREATE INDEX idx_movimientos_inventario_created_by ON oymcomercial.movimientos_inventario USING btree (created_by);
CREATE INDEX idx_movimientos_inventario_sucursal ON oymcomercial.movimientos_inventario USING btree (sucursal_id);
CREATE INDEX idx_movimientos_producto ON oymcomercial.movimientos_inventario USING btree (producto_id);
CREATE INDEX idx_movimientos_venta ON oymcomercial.movimientos_inventario USING btree (venta_id);
CREATE INDEX idx_nota_credito_empresa ON oymcomercial.nota_credito USING btree (empresa_id);
CREATE INDEX idx_nota_credito_empresa_created ON oymcomercial.nota_credito USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_nota_credito_factura ON oymcomercial.nota_credito USING btree (factura_id);
CREATE INDEX idx_nota_credito_sucursal ON oymcomercial.nota_credito USING btree (sucursal_id);
CREATE UNIQUE INDEX nota_credito_numero_empresa_sucursal_uq ON oymcomercial.nota_credito USING btree (empresa_id, sucursal_id, numero) WHERE (numero IS NOT NULL);
CREATE INDEX idx_nota_credito_electronica_empresa ON oymcomercial.nota_credito_electronica USING btree (empresa_id);
CREATE INDEX idx_nota_credito_evento_empresa ON oymcomercial.nota_credito_evento USING btree (empresa_id);
CREATE INDEX idx_nota_credito_evento_nc ON oymcomercial.nota_credito_evento USING btree (nota_credito_id, created_at DESC);
CREATE INDEX idx_nota_credito_items_nc ON oymcomercial.nota_credito_items USING btree (empresa_id, nota_credito_id);
CREATE INDEX idx_nota_credito_items_producto ON oymcomercial.nota_credito_items USING btree (empresa_id, producto_id);
CREATE INDEX idx_omnichannel_routes_empresa ON oymcomercial.omnichannel_routes USING btree (empresa_id);
CREATE INDEX idx_pagos_cliente ON oymcomercial.pagos USING btree (cliente_id);
CREATE INDEX idx_pagos_empresa ON oymcomercial.pagos USING btree (empresa_id);
CREATE INDEX idx_pagos_factura ON oymcomercial.pagos USING btree (factura_id);
CREATE INDEX idx_pagos_fecha ON oymcomercial.pagos USING btree (fecha_pago);
CREATE INDEX idx_pagos_sucursal ON oymcomercial.pagos USING btree (sucursal_id);
CREATE INDEX idx_pagos_usuario ON oymcomercial.pagos USING btree (usuario_id);
CREATE INDEX idx_planes_empresa ON oymcomercial.planes USING btree (empresa_id);
CREATE INDEX idx_presupuesto_items_presupuesto ON oymcomercial.presupuesto_items USING btree (presupuesto_id);
CREATE INDEX idx_presupuestos_empresa_fecha ON oymcomercial.presupuestos USING btree (empresa_id, fecha DESC);
CREATE INDEX idx_presupuestos_estado ON oymcomercial.presupuestos USING btree (empresa_id, estado);
CREATE INDEX idx_presupuestos_sucursal ON oymcomercial.presupuestos USING btree (sucursal_id);
CREATE INDEX idx_produccion_items_produccion ON oymcomercial.produccion_items USING btree (produccion_id);
CREATE INDEX idx_producciones_empresa_fecha ON oymcomercial.producciones USING btree (empresa_id, fecha DESC);
CREATE INDEX idx_producciones_sucursal ON oymcomercial.producciones USING btree (sucursal_id);
CREATE INDEX idx_producto_categorias_categoria ON oymcomercial.producto_categorias USING btree (categoria_id);
CREATE INDEX idx_producto_categorias_producto ON oymcomercial.producto_categorias USING btree (producto_id);
CREATE INDEX idx_producto_categorias_sucursal ON oymcomercial.producto_categorias USING btree (sucursal_id);
CREATE UNIQUE INDEX uq_producto_categoria_principal_unica ON oymcomercial.producto_categorias USING btree (empresa_id, producto_id) WHERE (es_principal = true);
CREATE UNIQUE INDEX uq_producto_categorias_triple ON oymcomercial.producto_categorias USING btree (empresa_id, producto_id, categoria_id);
CREATE INDEX idx_productos_empresa ON oymcomercial.productos USING btree (empresa_id);
CREATE UNIQUE INDEX idx_productos_empresa_sucursal_sku ON oymcomercial.productos USING btree (empresa_id, sucursal_id, sku);
CREATE INDEX idx_productos_es_insumo ON oymcomercial.productos USING btree (empresa_id) WHERE (es_insumo = true);
CREATE INDEX idx_productos_es_vendible ON oymcomercial.productos USING btree (empresa_id) WHERE (es_vendible = true);
CREATE INDEX idx_productos_sucursal ON oymcomercial.productos USING btree (sucursal_id);
CREATE UNIQUE INDEX uq_productos_codigo_barras ON oymcomercial.productos USING btree (empresa_id, sucursal_id, codigo_barras) WHERE (codigo_barras IS NOT NULL);
CREATE INDEX idx_prov_cat_rel_categoria ON oymcomercial.proveedor_categoria_rel USING btree (categoria_id);
CREATE INDEX idx_prov_cat_rel_empresa ON oymcomercial.proveedor_categoria_rel USING btree (empresa_id);
CREATE INDEX idx_prov_cat_rel_proveedor ON oymcomercial.proveedor_categoria_rel USING btree (proveedor_id);
CREATE INDEX idx_proveedor_categorias_empresa ON oymcomercial.proveedor_categorias USING btree (empresa_id);
CREATE UNIQUE INDEX proveedor_categorias_empresa_nombre_lower ON oymcomercial.proveedor_categorias USING btree (empresa_id, lower(TRIM(BOTH FROM nombre)));
CREATE INDEX idx_proveedor_productos_empresa ON oymcomercial.proveedor_productos USING btree (empresa_id);
CREATE INDEX idx_proveedor_productos_producto ON oymcomercial.proveedor_productos USING btree (producto_id);
CREATE INDEX idx_proveedor_productos_proveedor ON oymcomercial.proveedor_productos USING btree (proveedor_id);
CREATE UNIQUE INDEX proveedor_productos_un_principal ON oymcomercial.proveedor_productos USING btree (empresa_id, producto_id) WHERE es_principal;
CREATE INDEX idx_proveedores_empresa ON oymcomercial.proveedores USING btree (empresa_id);
CREATE INDEX ix_paf_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_archivos USING btree (empresa_id, proyecto_id);
CREATE INDEX ix_pc_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_comentarios USING btree (empresa_id, proyecto_id, created_at DESC);
CREATE INDEX ix_peh_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_estado_historial USING btree (empresa_id, proyecto_id, entered_at);
CREATE INDEX ix_pe_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_estados USING btree (empresa_id, activo, sort_order);
CREATE INDEX ix_ppc_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_prioridades_config USING btree (empresa_id, activo, sort_order);
CREATE INDEX ix_ptar_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_tareas USING btree (empresa_id, proyecto_id);
CREATE INDEX ix_pt_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyecto_tipos USING btree (empresa_id, activo);
CREATE INDEX idx_proyectos_sucursal ON oymcomercial.proyectos USING btree (sucursal_id);
CREATE INDEX ix_pr_cli_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyectos USING btree (empresa_id, cliente_id);
CREATE INDEX ix_pr_est_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyectos USING btree (empresa_id, estado_id, archivado);
CREATE INDEX ix_pr_fp_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyectos USING btree (empresa_id, fecha_prometida);
CREATE INDEX ix_pr_rc_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyectos USING btree (empresa_id, responsable_comercial_id);
CREATE INDEX ix_pr_rt_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyectos USING btree (empresa_id, responsable_tecnico_id);
CREATE INDEX ix_pr_tip_c9ff055d5178c1e5686eb62017e3c4ff ON oymcomercial.proyectos USING btree (empresa_id, tipo_id);
CREATE INDEX idx_receta_items_empresa ON oymcomercial.receta_items USING btree (empresa_id);
CREATE INDEX idx_receta_items_insumo ON oymcomercial.receta_items USING btree (insumo_producto_id);
CREATE INDEX idx_receta_items_receta ON oymcomercial.receta_items USING btree (receta_id);
CREATE INDEX idx_recetas_empresa ON oymcomercial.recetas USING btree (empresa_id);
CREATE INDEX idx_recetas_producto ON oymcomercial.recetas USING btree (producto_id);
CREATE INDEX idx_recetas_sucursal ON oymcomercial.recetas USING btree (sucursal_id);
CREATE INDEX idx_recibos_dinero_sucursal ON oymcomercial.recibos_dinero USING btree (sucursal_id);
CREATE INDEX idx_recibos_empresa_fecha ON oymcomercial.recibos_dinero USING btree (empresa_id, fecha DESC);
CREATE UNIQUE INDEX uq_recibos_cobro ON oymcomercial.recibos_dinero USING btree (cobro_cliente_id) WHERE (cobro_cliente_id IS NOT NULL);
CREATE UNIQUE INDEX uq_recibos_empresa_sucursal_numero ON oymcomercial.recibos_dinero USING btree (empresa_id, sucursal_id, numero_recibo);
CREATE UNIQUE INDEX uq_recibos_venta_contado ON oymcomercial.recibos_dinero USING btree (venta_id) WHERE ((origen = 'venta_contado'::text) AND (venta_id IS NOT NULL));
CREATE INDEX idx_recibo_item_cxc ON oymcomercial.recibos_dinero_items USING btree (cuenta_por_cobrar_id);
CREATE INDEX idx_recibo_item_recibo ON oymcomercial.recibos_dinero_items USING btree (recibo_id);
CREATE UNIQUE INDEX uq_recibo_item_cobro ON oymcomercial.recibos_dinero_items USING btree (cobro_cliente_id) WHERE (cobro_cliente_id IS NOT NULL);
CREATE INDEX idx_sifen_jobs_empresa_created ON oymcomercial.sifen_jobs USING btree (empresa_id, created_at DESC);
CREATE INDEX idx_sifen_jobs_fe_created ON oymcomercial.sifen_jobs USING btree (factura_electronica_id, created_at DESC);
CREATE INDEX idx_sifen_jobs_pendientes ON oymcomercial.sifen_jobs USING btree (proximo_reintento_at NULLS FIRST, created_at) WHERE (estado = 'pendiente'::text);
CREATE INDEX idx_sifen_jobs_procesando ON oymcomercial.sifen_jobs USING btree (procesando_desde) WHERE (estado = 'procesando'::text);
CREATE INDEX idx_sifen_jobs_sucursal ON oymcomercial.sifen_jobs USING btree (sucursal_id);
CREATE UNIQUE INDEX uq_sifen_jobs_fe_activo ON oymcomercial.sifen_jobs USING btree (factura_electronica_id) WHERE (estado = ANY (ARRAY['pendiente'::text, 'procesando'::text]));
CREATE INDEX idx_sorteo_conv_empresa ON oymcomercial.sorteo_conversaciones USING btree (empresa_id);
CREATE INDEX idx_sorteo_conv_estado ON oymcomercial.sorteo_conversaciones USING btree (estado);
CREATE INDEX idx_sorteo_conv_sorteo ON oymcomercial.sorteo_conversaciones USING btree (sorteo_id);
CREATE INDEX idx_sorteo_conv_wa ON oymcomercial.sorteo_conversaciones USING btree (whatsapp_numero);
CREATE UNIQUE INDEX uq_sorteo_conv_activa ON oymcomercial.sorteo_conversaciones USING btree (sorteo_id, whatsapp_numero) WHERE (activa = true);
CREATE INDEX idx_sorteo_cup_empresa ON oymcomercial.sorteo_cupones USING btree (empresa_id);
CREATE INDEX idx_sorteo_cup_entrada ON oymcomercial.sorteo_cupones USING btree (entrada_id);
CREATE INDEX idx_sorteo_cup_sorteo ON oymcomercial.sorteo_cupones USING btree (sorteo_id);
CREATE UNIQUE INDEX uq_sorteo_cupones_sorteo_coupon_value ON oymcomercial.sorteo_cupones USING btree (sorteo_id, coupon_number_value) WHERE (coupon_number_value IS NOT NULL);
CREATE INDEX idx_sorteo_ent_cliente ON oymcomercial.sorteo_entradas USING btree (cliente_id);
CREATE INDEX idx_sorteo_ent_comp_val ON oymcomercial.sorteo_entradas USING btree (comprobante_validacion_id) WHERE (comprobante_validacion_id IS NOT NULL);
CREATE INDEX idx_sorteo_ent_conv ON oymcomercial.sorteo_entradas USING btree (conversacion_id);
CREATE INDEX idx_sorteo_ent_empresa ON oymcomercial.sorteo_entradas USING btree (empresa_id);
CREATE INDEX idx_sorteo_ent_sorteo ON oymcomercial.sorteo_entradas USING btree (sorteo_id);
CREATE INDEX idx_sorteo_entradas_chat_conversation ON oymcomercial.sorteo_entradas USING btree (chat_conversation_id) WHERE (chat_conversation_id IS NOT NULL);
CREATE INDEX idx_sorteo_entradas_revendedor ON oymcomercial.sorteo_entradas USING btree (revendedor_id) WHERE (revendedor_id IS NOT NULL);
CREATE UNIQUE INDEX uq_sorteo_entradas_idempotency_key ON oymcomercial.sorteo_entradas USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);
CREATE INDEX idx_sorteo_rev_clicks_revendedor ON oymcomercial.sorteo_revendedor_clicks USING btree (revendedor_id, created_at DESC);
CREATE INDEX idx_sorteo_rev_clicks_sorteo ON oymcomercial.sorteo_revendedor_clicks USING btree (sorteo_id, created_at DESC);
CREATE UNIQUE INDEX uq_sorteo_rev_clicks_token ON oymcomercial.sorteo_revendedor_clicks USING btree (attribution_token);
CREATE INDEX idx_sorteo_revendedores_empresa ON oymcomercial.sorteo_revendedores USING btree (empresa_id);
CREATE INDEX idx_sorteo_revendedores_sorteo ON oymcomercial.sorteo_revendedores USING btree (sorteo_id);
CREATE UNIQUE INDEX uq_sorteo_revendedores_sorteo_codigo_lower ON oymcomercial.sorteo_revendedores USING btree (sorteo_id, lower(TRIM(BOTH FROM codigo_referido)));
CREATE INDEX idx_sorteo_ticket_empresa_sorteo ON oymcomercial.sorteo_ticket_deliveries USING btree (empresa_id, sorteo_id);
CREATE INDEX idx_sorteo_ticket_status ON oymcomercial.sorteo_ticket_deliveries USING btree (empresa_id, status);
CREATE UNIQUE INDEX uq_sorteo_ticket_entrada_current ON oymcomercial.sorteo_ticket_deliveries USING btree (entrada_id) WHERE is_current;
CREATE UNIQUE INDEX uq_sorteo_ticket_entrada_revision ON oymcomercial.sorteo_ticket_deliveries USING btree (entrada_id, template_revision);
CREATE INDEX idx_sorteos_empresa ON oymcomercial.sorteos USING btree (empresa_id);
CREATE UNIQUE INDEX sucursales_una_principal_uq ON oymcomercial.sucursales USING btree (empresa_id) WHERE es_principal;
CREATE INDEX idx_suscripciones_cliente ON oymcomercial.suscripciones USING btree (cliente_id);
CREATE INDEX idx_suscripciones_empresa ON oymcomercial.suscripciones USING btree (empresa_id);
CREATE INDEX idx_suscripciones_plan ON oymcomercial.suscripciones USING btree (plan_id);
CREATE INDEX idx_tipificaciones_cliente ON oymcomercial.tipificaciones USING btree (cliente_id);
CREATE INDEX idx_tipificaciones_empresa ON oymcomercial.tipificaciones USING btree (empresa_id);
CREATE INDEX idx_transf_destino ON oymcomercial.transferencias_inventario USING btree (sucursal_destino_id);
CREATE INDEX idx_transf_empresa ON oymcomercial.transferencias_inventario USING btree (empresa_id);
CREATE INDEX idx_transf_estado ON oymcomercial.transferencias_inventario USING btree (empresa_id, estado);
CREATE INDEX idx_transf_origen ON oymcomercial.transferencias_inventario USING btree (sucursal_origen_id);
CREATE INDEX idx_transf_item_prod_dst ON oymcomercial.transferencias_inventario_items USING btree (producto_destino_id);
CREATE INDEX idx_transf_item_prod_org ON oymcomercial.transferencias_inventario_items USING btree (producto_origen_id);
CREATE INDEX idx_transf_item_transf ON oymcomercial.transferencias_inventario_items USING btree (transferencia_id);
CREATE INDEX idx_udv_usuario ON oymcomercial.usuario_dashboard_views USING btree (usuario_id);
CREATE UNIQUE INDEX uq_udv_one_default_per_user ON oymcomercial.usuario_dashboard_views USING btree (usuario_id) WHERE (es_default IS TRUE);
CREATE INDEX idx_usuario_modulos_usuario ON oymcomercial.usuario_modulos USING btree (usuario_id);
CREATE INDEX idx_usuarios_auth_user_id ON oymcomercial.usuarios USING btree (auth_user_id);
CREATE INDEX idx_ventas_cliente ON oymcomercial.ventas USING btree (cliente_id);
CREATE INDEX idx_ventas_empresa ON oymcomercial.ventas USING btree (empresa_id);
CREATE INDEX idx_ventas_estado_anulada ON oymcomercial.ventas USING btree (empresa_id, estado) WHERE (estado = 'anulada'::text);
CREATE INDEX idx_ventas_factura ON oymcomercial.ventas USING btree (factura_id);
CREATE INDEX idx_ventas_fecha ON oymcomercial.ventas USING btree (fecha);
CREATE INDEX idx_ventas_sucursal ON oymcomercial.ventas USING btree (sucursal_id);
CREATE INDEX idx_ventas_items_empresa ON oymcomercial.ventas_items USING btree (empresa_id);
CREATE INDEX idx_ventas_items_producto ON oymcomercial.ventas_items USING btree (producto_id);
CREATE INDEX idx_ventas_items_venta ON oymcomercial.ventas_items USING btree (venta_id);
CREATE INDEX ix_ventas_pagos_detalle_empresa_fecha ON oymcomercial.ventas_pagos_detalle USING btree (empresa_id, fecha_pago);
CREATE INDEX ix_ventas_pagos_detalle_venta ON oymcomercial.ventas_pagos_detalle USING btree (venta_id);

-- ---------- ROW LEVEL SECURITY ----------
ALTER TABLE "oymcomercial"."categorias_productos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_agents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_campaign_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_campaign_jobs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_campaign_recipients" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_campaign_templates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_campaigns" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_channel_quick_replies" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_channels" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_comprobante_validaciones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_contacts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_conversation_closures" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_conversations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_empresa_operator_roles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_data" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_node_blocks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_nodes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_options" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_recontact_rules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_recontact_runs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flow_sessions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_flows" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_omnicanal_work_schedules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_queue_channels" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_queue_closure_states" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_queue_closure_substates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_queue_supervisors" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_queues" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_routing_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_supervisor_agents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."chat_usuario_omnicanal" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."cliente_historial" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."cliente_obligaciones_tributarias" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."cliente_perfil_tributario" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."cliente_tipos_servicio_catalogo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."clientes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_ajustes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_equipo_miembros" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_equipos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_escalas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_lineas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_periodos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_politica_versiones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."comision_politicas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."compras" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."crm_etapas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."crm_notas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."crm_prospectos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."dashboard_views" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."empresa_autoimpresor_config" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."empresa_dashboard_views" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."empresa_facturacion_modo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."empresa_modulos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."empresa_sifen_config" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."empresas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."entidades_bancarias" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."factura_correlativos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."factura_electronica" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."factura_electronica_evento" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."factura_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."facturas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."gastos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."imports_audit" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."inventario_stock_ubicacion" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."inventario_ubicaciones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."marketing_calendarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."marketing_comentarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."marketing_historial_estados" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."marketing_piezas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."marketing_tasks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."modulos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."movimientos_inventario" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."nota_credito" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."nota_credito_electronica" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."nota_credito_evento" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."nota_credito_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."obligaciones_tributarias_catalogo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."omnichannel_routes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."pagos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."planes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."producto_categorias" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."productos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."productos_codigo_secuencia" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proveedor_categoria_rel" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proveedor_categorias" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proveedor_productos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proveedores" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_archivos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_comentarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_estado_historial" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_estados" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_prioridades_config" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_tareas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyecto_tipos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."proyectos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."receta_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."recetas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."recibos_dinero_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteo_conversaciones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteo_cupones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteo_entradas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteo_revendedor_clicks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteo_revendedores" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteo_ticket_deliveries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."sorteos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."suscripciones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."tipificaciones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."transferencias_inventario" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."transferencias_inventario_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."usuario_dashboard_views" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."usuario_modulos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."usuarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."ventas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."ventas_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."ventas_pagos_detalle" ENABLE ROW LEVEL SECURITY;

-- ---------- POLICIES ----------
CREATE POLICY "chat_agents_delete" ON "oymcomercial"."chat_agents" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_agents_insert" ON "oymcomercial"."chat_agents" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_agents_select" ON "oymcomercial"."chat_agents" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_agents_update" ON "oymcomercial"."chat_agents" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_events_delete" ON "oymcomercial"."chat_campaign_events" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_events_insert" ON "oymcomercial"."chat_campaign_events" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_events_select" ON "oymcomercial"."chat_campaign_events" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_events_update" ON "oymcomercial"."chat_campaign_events" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_jobs_delete" ON "oymcomercial"."chat_campaign_jobs" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_jobs_insert" ON "oymcomercial"."chat_campaign_jobs" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_jobs_select" ON "oymcomercial"."chat_campaign_jobs" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_jobs_update" ON "oymcomercial"."chat_campaign_jobs" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_recipients_delete" ON "oymcomercial"."chat_campaign_recipients" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_recipients_insert" ON "oymcomercial"."chat_campaign_recipients" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_recipients_select" ON "oymcomercial"."chat_campaign_recipients" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_recipients_update" ON "oymcomercial"."chat_campaign_recipients" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_templates_delete" ON "oymcomercial"."chat_campaign_templates" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_templates_insert" ON "oymcomercial"."chat_campaign_templates" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_templates_select" ON "oymcomercial"."chat_campaign_templates" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaign_templates_update" ON "oymcomercial"."chat_campaign_templates" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaigns_delete" ON "oymcomercial"."chat_campaigns" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaigns_insert" ON "oymcomercial"."chat_campaigns" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaigns_select" ON "oymcomercial"."chat_campaigns" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_campaigns_update" ON "oymcomercial"."chat_campaigns" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channel_quick_replies_delete" ON "oymcomercial"."chat_channel_quick_replies" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channel_quick_replies_insert" ON "oymcomercial"."chat_channel_quick_replies" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channel_quick_replies_select" ON "oymcomercial"."chat_channel_quick_replies" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channel_quick_replies_update" ON "oymcomercial"."chat_channel_quick_replies" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channels_delete" ON "oymcomercial"."chat_channels" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channels_insert" ON "oymcomercial"."chat_channels" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channels_select" ON "oymcomercial"."chat_channels" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_channels_update" ON "oymcomercial"."chat_channels" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_comp_val_delete" ON "oymcomercial"."chat_comprobante_validaciones" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_comp_val_insert" ON "oymcomercial"."chat_comprobante_validaciones" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_comp_val_select" ON "oymcomercial"."chat_comprobante_validaciones" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_comp_val_update" ON "oymcomercial"."chat_comprobante_validaciones" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_contacts_delete" ON "oymcomercial"."chat_contacts" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_contacts_insert" ON "oymcomercial"."chat_contacts" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_contacts_select" ON "oymcomercial"."chat_contacts" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_contacts_update" ON "oymcomercial"."chat_contacts" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_conversation_closures_insert" ON "oymcomercial"."chat_conversation_closures" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_conversation_closures_select" ON "oymcomercial"."chat_conversation_closures" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_conversations_delete" ON "oymcomercial"."chat_conversations" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_conversations_insert" ON "oymcomercial"."chat_conversations" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_conversations_select" ON "oymcomercial"."chat_conversations" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_conversations_update" ON "oymcomercial"."chat_conversations" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_empresa_operator_roles_delete" ON "oymcomercial"."chat_empresa_operator_roles" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_empresa_operator_roles_insert" ON "oymcomercial"."chat_empresa_operator_roles" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_empresa_operator_roles_select" ON "oymcomercial"."chat_empresa_operator_roles" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_empresa_operator_roles_update" ON "oymcomercial"."chat_empresa_operator_roles" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_data_delete" ON "oymcomercial"."chat_flow_data" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_data_insert" ON "oymcomercial"."chat_flow_data" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_data_select" ON "oymcomercial"."chat_flow_data" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_data_update" ON "oymcomercial"."chat_flow_data" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_events_delete" ON "oymcomercial"."chat_flow_events" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_events_insert" ON "oymcomercial"."chat_flow_events" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_events_select" ON "oymcomercial"."chat_flow_events" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_events_update" ON "oymcomercial"."chat_flow_events" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_node_blocks_delete_empresa" ON "oymcomercial"."chat_flow_node_blocks" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_node_blocks_insert_empresa" ON "oymcomercial"."chat_flow_node_blocks" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_node_blocks_select_empresa" ON "oymcomercial"."chat_flow_node_blocks" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_node_blocks_update_empresa" ON "oymcomercial"."chat_flow_node_blocks" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_nodes_delete" ON "oymcomercial"."chat_flow_nodes" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_nodes_insert" ON "oymcomercial"."chat_flow_nodes" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_nodes_select" ON "oymcomercial"."chat_flow_nodes" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_nodes_update" ON "oymcomercial"."chat_flow_nodes" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_options_delete" ON "oymcomercial"."chat_flow_options" AS PERMISSIVE FOR DELETE TO public USING ((EXISTS ( SELECT 1
   FROM oymcomercial.chat_flow_nodes n
  WHERE ((n.id = chat_flow_options.node_id) AND oymcomercial.puede_acceder_empresa(n.empresa_id)))));
CREATE POLICY "chat_flow_options_insert" ON "oymcomercial"."chat_flow_options" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((EXISTS ( SELECT 1
   FROM oymcomercial.chat_flow_nodes n
  WHERE ((n.id = chat_flow_options.node_id) AND oymcomercial.puede_acceder_empresa(n.empresa_id)))));
CREATE POLICY "chat_flow_options_select" ON "oymcomercial"."chat_flow_options" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM oymcomercial.chat_flow_nodes n
  WHERE ((n.id = chat_flow_options.node_id) AND oymcomercial.puede_acceder_empresa(n.empresa_id)))));
CREATE POLICY "chat_flow_options_update" ON "oymcomercial"."chat_flow_options" AS PERMISSIVE FOR UPDATE TO public USING ((EXISTS ( SELECT 1
   FROM oymcomercial.chat_flow_nodes n
  WHERE ((n.id = chat_flow_options.node_id) AND oymcomercial.puede_acceder_empresa(n.empresa_id))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM oymcomercial.chat_flow_nodes n
  WHERE ((n.id = chat_flow_options.node_id) AND oymcomercial.puede_acceder_empresa(n.empresa_id)))));
CREATE POLICY "chat_flow_recontact_rules_delete" ON "oymcomercial"."chat_flow_recontact_rules" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_rules_insert" ON "oymcomercial"."chat_flow_recontact_rules" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_rules_select" ON "oymcomercial"."chat_flow_recontact_rules" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_rules_update" ON "oymcomercial"."chat_flow_recontact_rules" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_runs_delete" ON "oymcomercial"."chat_flow_recontact_runs" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_runs_insert" ON "oymcomercial"."chat_flow_recontact_runs" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_runs_select" ON "oymcomercial"."chat_flow_recontact_runs" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_recontact_runs_update" ON "oymcomercial"."chat_flow_recontact_runs" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_sessions_delete" ON "oymcomercial"."chat_flow_sessions" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_sessions_insert" ON "oymcomercial"."chat_flow_sessions" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_sessions_select" ON "oymcomercial"."chat_flow_sessions" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flow_sessions_update" ON "oymcomercial"."chat_flow_sessions" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flows_delete" ON "oymcomercial"."chat_flows" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flows_insert" ON "oymcomercial"."chat_flows" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flows_select" ON "oymcomercial"."chat_flows" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_flows_update" ON "oymcomercial"."chat_flows" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_messages_delete" ON "oymcomercial"."chat_messages" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_messages_insert" ON "oymcomercial"."chat_messages" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_messages_select" ON "oymcomercial"."chat_messages" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_messages_update" ON "oymcomercial"."chat_messages" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_omn_sched_delete" ON "oymcomercial"."chat_omnicanal_work_schedules" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_omn_sched_insert" ON "oymcomercial"."chat_omnicanal_work_schedules" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_omn_sched_select" ON "oymcomercial"."chat_omnicanal_work_schedules" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_omn_sched_update" ON "oymcomercial"."chat_omnicanal_work_schedules" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_channels_delete" ON "oymcomercial"."chat_queue_channels" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_channels_insert" ON "oymcomercial"."chat_queue_channels" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_channels_select" ON "oymcomercial"."chat_queue_channels" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_channels_update" ON "oymcomercial"."chat_queue_channels" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_states_delete" ON "oymcomercial"."chat_queue_closure_states" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_states_insert" ON "oymcomercial"."chat_queue_closure_states" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_states_select" ON "oymcomercial"."chat_queue_closure_states" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_states_update" ON "oymcomercial"."chat_queue_closure_states" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_substates_delete" ON "oymcomercial"."chat_queue_closure_substates" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_substates_insert" ON "oymcomercial"."chat_queue_closure_substates" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_substates_select" ON "oymcomercial"."chat_queue_closure_substates" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_closure_substates_update" ON "oymcomercial"."chat_queue_closure_substates" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_supervisors_delete" ON "oymcomercial"."chat_queue_supervisors" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_supervisors_insert" ON "oymcomercial"."chat_queue_supervisors" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_supervisors_select" ON "oymcomercial"."chat_queue_supervisors" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queue_supervisors_update" ON "oymcomercial"."chat_queue_supervisors" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queues_delete" ON "oymcomercial"."chat_queues" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queues_insert" ON "oymcomercial"."chat_queues" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queues_select" ON "oymcomercial"."chat_queues" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_queues_update" ON "oymcomercial"."chat_queues" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_routing_events_insert" ON "oymcomercial"."chat_routing_events" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_routing_events_select" ON "oymcomercial"."chat_routing_events" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_supervisor_agents_delete" ON "oymcomercial"."chat_supervisor_agents" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_supervisor_agents_insert" ON "oymcomercial"."chat_supervisor_agents" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_supervisor_agents_select" ON "oymcomercial"."chat_supervisor_agents" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_supervisor_agents_update" ON "oymcomercial"."chat_supervisor_agents" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_usuario_omnicanal_delete" ON "oymcomercial"."chat_usuario_omnicanal" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_usuario_omnicanal_insert" ON "oymcomercial"."chat_usuario_omnicanal" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_usuario_omnicanal_select" ON "oymcomercial"."chat_usuario_omnicanal" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "chat_usuario_omnicanal_update" ON "oymcomercial"."chat_usuario_omnicanal" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_historial_insert" ON "oymcomercial"."cliente_historial" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_historial_select" ON "oymcomercial"."cliente_historial" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_obligaciones_tributarias_delete" ON "oymcomercial"."cliente_obligaciones_tributarias" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_obligaciones_tributarias_insert" ON "oymcomercial"."cliente_obligaciones_tributarias" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_obligaciones_tributarias_select" ON "oymcomercial"."cliente_obligaciones_tributarias" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_obligaciones_tributarias_update" ON "oymcomercial"."cliente_obligaciones_tributarias" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_perfil_tributario_delete" ON "oymcomercial"."cliente_perfil_tributario" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_perfil_tributario_insert" ON "oymcomercial"."cliente_perfil_tributario" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_perfil_tributario_select" ON "oymcomercial"."cliente_perfil_tributario" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_perfil_tributario_update" ON "oymcomercial"."cliente_perfil_tributario" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_tipos_servicio_catalogo_delete" ON "oymcomercial"."cliente_tipos_servicio_catalogo" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_tipos_servicio_catalogo_insert" ON "oymcomercial"."cliente_tipos_servicio_catalogo" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_tipos_servicio_catalogo_select" ON "oymcomercial"."cliente_tipos_servicio_catalogo" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "cliente_tipos_servicio_catalogo_update" ON "oymcomercial"."cliente_tipos_servicio_catalogo" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "clientes_delete" ON "oymcomercial"."clientes" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "clientes_insert" ON "oymcomercial"."clientes" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "clientes_select" ON "oymcomercial"."clientes" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "clientes_update" ON "oymcomercial"."clientes" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_ajustes_delete" ON "oymcomercial"."comision_ajustes" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_ajustes_insert" ON "oymcomercial"."comision_ajustes" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_ajustes_select" ON "oymcomercial"."comision_ajustes" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_ajustes_update" ON "oymcomercial"."comision_ajustes" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipo_miembros_delete" ON "oymcomercial"."comision_equipo_miembros" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipo_miembros_insert" ON "oymcomercial"."comision_equipo_miembros" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipo_miembros_select" ON "oymcomercial"."comision_equipo_miembros" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipo_miembros_update" ON "oymcomercial"."comision_equipo_miembros" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipos_delete" ON "oymcomercial"."comision_equipos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipos_insert" ON "oymcomercial"."comision_equipos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipos_select" ON "oymcomercial"."comision_equipos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_equipos_update" ON "oymcomercial"."comision_equipos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_escalas_delete" ON "oymcomercial"."comision_escalas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_escalas_insert" ON "oymcomercial"."comision_escalas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_escalas_select" ON "oymcomercial"."comision_escalas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_escalas_update" ON "oymcomercial"."comision_escalas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_lineas_delete" ON "oymcomercial"."comision_lineas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_lineas_insert" ON "oymcomercial"."comision_lineas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_lineas_select" ON "oymcomercial"."comision_lineas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_lineas_update" ON "oymcomercial"."comision_lineas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_periodos_delete" ON "oymcomercial"."comision_periodos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_periodos_insert" ON "oymcomercial"."comision_periodos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_periodos_select" ON "oymcomercial"."comision_periodos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_periodos_update" ON "oymcomercial"."comision_periodos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politica_versiones_delete" ON "oymcomercial"."comision_politica_versiones" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politica_versiones_insert" ON "oymcomercial"."comision_politica_versiones" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politica_versiones_select" ON "oymcomercial"."comision_politica_versiones" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politica_versiones_update" ON "oymcomercial"."comision_politica_versiones" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politicas_delete" ON "oymcomercial"."comision_politicas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politicas_insert" ON "oymcomercial"."comision_politicas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politicas_select" ON "oymcomercial"."comision_politicas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "comision_politicas_update" ON "oymcomercial"."comision_politicas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "compras_delete" ON "oymcomercial"."compras" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "compras_insert" ON "oymcomercial"."compras" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "compras_select" ON "oymcomercial"."compras" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "compras_update" ON "oymcomercial"."compras" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_etapas_delete" ON "oymcomercial"."crm_etapas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_etapas_insert" ON "oymcomercial"."crm_etapas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_etapas_select" ON "oymcomercial"."crm_etapas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_etapas_update" ON "oymcomercial"."crm_etapas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_notas_delete" ON "oymcomercial"."crm_notas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_notas_insert" ON "oymcomercial"."crm_notas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_notas_select" ON "oymcomercial"."crm_notas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_notas_update" ON "oymcomercial"."crm_notas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_prospectos_delete" ON "oymcomercial"."crm_prospectos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_prospectos_insert" ON "oymcomercial"."crm_prospectos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_prospectos_select" ON "oymcomercial"."crm_prospectos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "crm_prospectos_update" ON "oymcomercial"."crm_prospectos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "dashboard_views_all_super" ON "oymcomercial"."dashboard_views" AS PERMISSIVE FOR ALL TO public USING (oymcomercial.es_super_admin()) WITH CHECK (oymcomercial.es_super_admin());
CREATE POLICY "dashboard_views_select_auth" ON "oymcomercial"."dashboard_views" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "edv_delete" ON "oymcomercial"."empresa_dashboard_views" AS PERMISSIVE FOR DELETE TO public USING ((oymcomercial.es_super_admin() OR oymcomercial.puede_acceder_empresa(empresa_id)));
CREATE POLICY "edv_mutate" ON "oymcomercial"."empresa_dashboard_views" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((oymcomercial.es_super_admin() OR oymcomercial.puede_acceder_empresa(empresa_id)));
CREATE POLICY "edv_select" ON "oymcomercial"."empresa_dashboard_views" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "edv_update" ON "oymcomercial"."empresa_dashboard_views" AS PERMISSIVE FOR UPDATE TO public USING ((oymcomercial.es_super_admin() OR oymcomercial.puede_acceder_empresa(empresa_id))) WITH CHECK ((oymcomercial.es_super_admin() OR oymcomercial.puede_acceder_empresa(empresa_id)));
CREATE POLICY "empresa_modulos_delete" ON "oymcomercial"."empresa_modulos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_modulos_insert" ON "oymcomercial"."empresa_modulos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_modulos_select" ON "oymcomercial"."empresa_modulos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_modulos_update" ON "oymcomercial"."empresa_modulos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_sifen_config_delete" ON "oymcomercial"."empresa_sifen_config" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_sifen_config_insert" ON "oymcomercial"."empresa_sifen_config" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_sifen_config_select" ON "oymcomercial"."empresa_sifen_config" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresa_sifen_config_update" ON "oymcomercial"."empresa_sifen_config" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "empresas_delete" ON "oymcomercial"."empresas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.es_super_admin());
CREATE POLICY "empresas_insert" ON "oymcomercial"."empresas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.es_super_admin());
CREATE POLICY "empresas_select" ON "oymcomercial"."empresas" AS PERMISSIVE FOR SELECT TO public USING ((oymcomercial.es_super_admin() OR (id = oymcomercial.empresa_id_actual())));
CREATE POLICY "empresas_update" ON "oymcomercial"."empresas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(id)) WITH CHECK (oymcomercial.puede_acceder_empresa(id));
CREATE POLICY "entidades_bancarias_delete" ON "oymcomercial"."entidades_bancarias" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "entidades_bancarias_insert" ON "oymcomercial"."entidades_bancarias" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "entidades_bancarias_select" ON "oymcomercial"."entidades_bancarias" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "entidades_bancarias_update" ON "oymcomercial"."entidades_bancarias" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_delete" ON "oymcomercial"."factura_electronica" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_insert" ON "oymcomercial"."factura_electronica" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_select" ON "oymcomercial"."factura_electronica" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_update" ON "oymcomercial"."factura_electronica" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_evento_delete" ON "oymcomercial"."factura_electronica_evento" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_evento_insert" ON "oymcomercial"."factura_electronica_evento" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_evento_select" ON "oymcomercial"."factura_electronica_evento" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_electronica_evento_update" ON "oymcomercial"."factura_electronica_evento" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_items_delete" ON "oymcomercial"."factura_items" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_items_insert" ON "oymcomercial"."factura_items" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_items_select" ON "oymcomercial"."factura_items" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "factura_items_update" ON "oymcomercial"."factura_items" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "facturas_delete" ON "oymcomercial"."facturas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "facturas_insert" ON "oymcomercial"."facturas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "facturas_select" ON "oymcomercial"."facturas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "facturas_update" ON "oymcomercial"."facturas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "gastos_delete" ON "oymcomercial"."gastos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "gastos_insert" ON "oymcomercial"."gastos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "gastos_select" ON "oymcomercial"."gastos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "gastos_update" ON "oymcomercial"."gastos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_calendarios_delete" ON "oymcomercial"."marketing_calendarios" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_calendarios_insert" ON "oymcomercial"."marketing_calendarios" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_calendarios_select" ON "oymcomercial"."marketing_calendarios" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_calendarios_update" ON "oymcomercial"."marketing_calendarios" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_comentarios_delete" ON "oymcomercial"."marketing_comentarios" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_comentarios_insert" ON "oymcomercial"."marketing_comentarios" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_comentarios_select" ON "oymcomercial"."marketing_comentarios" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_comentarios_update" ON "oymcomercial"."marketing_comentarios" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_historial_estados_delete" ON "oymcomercial"."marketing_historial_estados" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_historial_estados_insert" ON "oymcomercial"."marketing_historial_estados" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_historial_estados_select" ON "oymcomercial"."marketing_historial_estados" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_historial_estados_update" ON "oymcomercial"."marketing_historial_estados" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_piezas_delete" ON "oymcomercial"."marketing_piezas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_piezas_insert" ON "oymcomercial"."marketing_piezas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_piezas_select" ON "oymcomercial"."marketing_piezas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_piezas_update" ON "oymcomercial"."marketing_piezas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_tasks_delete" ON "oymcomercial"."marketing_tasks" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_tasks_insert" ON "oymcomercial"."marketing_tasks" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_tasks_select" ON "oymcomercial"."marketing_tasks" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "marketing_tasks_update" ON "oymcomercial"."marketing_tasks" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "modulos_delete" ON "oymcomercial"."modulos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.es_super_admin());
CREATE POLICY "modulos_insert" ON "oymcomercial"."modulos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.es_super_admin());
CREATE POLICY "modulos_select" ON "oymcomercial"."modulos" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "modulos_update" ON "oymcomercial"."modulos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.es_super_admin()) WITH CHECK (oymcomercial.es_super_admin());
CREATE POLICY "movimientos_delete" ON "oymcomercial"."movimientos_inventario" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "movimientos_insert" ON "oymcomercial"."movimientos_inventario" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "movimientos_select" ON "oymcomercial"."movimientos_inventario" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "movimientos_update" ON "oymcomercial"."movimientos_inventario" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_delete" ON "oymcomercial"."nota_credito" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_insert" ON "oymcomercial"."nota_credito" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_select" ON "oymcomercial"."nota_credito" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_update" ON "oymcomercial"."nota_credito" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_electronica_delete" ON "oymcomercial"."nota_credito_electronica" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_electronica_insert" ON "oymcomercial"."nota_credito_electronica" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_electronica_select" ON "oymcomercial"."nota_credito_electronica" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_electronica_update" ON "oymcomercial"."nota_credito_electronica" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_evento_delete" ON "oymcomercial"."nota_credito_evento" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_evento_insert" ON "oymcomercial"."nota_credito_evento" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_evento_select" ON "oymcomercial"."nota_credito_evento" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "nota_credito_evento_update" ON "oymcomercial"."nota_credito_evento" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "obligaciones_tributarias_catalogo_select" ON "oymcomercial"."obligaciones_tributarias_catalogo" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "obligaciones_tributarias_catalogo_select_sr" ON "oymcomercial"."obligaciones_tributarias_catalogo" AS PERMISSIVE FOR SELECT TO "service_role" USING (true);
CREATE POLICY "pagos_delete" ON "oymcomercial"."pagos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "pagos_insert" ON "oymcomercial"."pagos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "pagos_select" ON "oymcomercial"."pagos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "pagos_update" ON "oymcomercial"."pagos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "planes_delete" ON "oymcomercial"."planes" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "planes_insert" ON "oymcomercial"."planes" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "planes_select" ON "oymcomercial"."planes" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "planes_update" ON "oymcomercial"."planes" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "productos_delete" ON "oymcomercial"."productos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "productos_insert" ON "oymcomercial"."productos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "productos_select" ON "oymcomercial"."productos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "productos_update" ON "oymcomercial"."productos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categoria_rel_delete" ON "oymcomercial"."proveedor_categoria_rel" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categoria_rel_insert" ON "oymcomercial"."proveedor_categoria_rel" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categoria_rel_select" ON "oymcomercial"."proveedor_categoria_rel" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categoria_rel_update" ON "oymcomercial"."proveedor_categoria_rel" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categorias_delete" ON "oymcomercial"."proveedor_categorias" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categorias_insert" ON "oymcomercial"."proveedor_categorias" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categorias_select" ON "oymcomercial"."proveedor_categorias" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_categorias_update" ON "oymcomercial"."proveedor_categorias" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_productos_delete" ON "oymcomercial"."proveedor_productos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_productos_insert" ON "oymcomercial"."proveedor_productos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_productos_select" ON "oymcomercial"."proveedor_productos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedor_productos_update" ON "oymcomercial"."proveedor_productos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedores_delete" ON "oymcomercial"."proveedores" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedores_insert" ON "oymcomercial"."proveedores" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedores_select" ON "oymcomercial"."proveedores" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proveedores_update" ON "oymcomercial"."proveedores" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_archivos_delete" ON "oymcomercial"."proyecto_archivos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_archivos_insert" ON "oymcomercial"."proyecto_archivos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_archivos_select" ON "oymcomercial"."proyecto_archivos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_archivos_update" ON "oymcomercial"."proyecto_archivos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_comentarios_delete" ON "oymcomercial"."proyecto_comentarios" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_comentarios_insert" ON "oymcomercial"."proyecto_comentarios" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_comentarios_select" ON "oymcomercial"."proyecto_comentarios" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_comentarios_update" ON "oymcomercial"."proyecto_comentarios" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estado_historial_delete" ON "oymcomercial"."proyecto_estado_historial" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estado_historial_insert" ON "oymcomercial"."proyecto_estado_historial" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estado_historial_select" ON "oymcomercial"."proyecto_estado_historial" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estado_historial_update" ON "oymcomercial"."proyecto_estado_historial" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estados_delete" ON "oymcomercial"."proyecto_estados" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estados_insert" ON "oymcomercial"."proyecto_estados" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estados_select" ON "oymcomercial"."proyecto_estados" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_estados_update" ON "oymcomercial"."proyecto_estados" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_prioridades_config_delete" ON "oymcomercial"."proyecto_prioridades_config" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_prioridades_config_insert" ON "oymcomercial"."proyecto_prioridades_config" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_prioridades_config_select" ON "oymcomercial"."proyecto_prioridades_config" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_prioridades_config_update" ON "oymcomercial"."proyecto_prioridades_config" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tareas_delete" ON "oymcomercial"."proyecto_tareas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tareas_insert" ON "oymcomercial"."proyecto_tareas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tareas_select" ON "oymcomercial"."proyecto_tareas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tareas_update" ON "oymcomercial"."proyecto_tareas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tipos_delete" ON "oymcomercial"."proyecto_tipos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tipos_insert" ON "oymcomercial"."proyecto_tipos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tipos_select" ON "oymcomercial"."proyecto_tipos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyecto_tipos_update" ON "oymcomercial"."proyecto_tipos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyectos_delete" ON "oymcomercial"."proyectos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyectos_insert" ON "oymcomercial"."proyectos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyectos_select" ON "oymcomercial"."proyectos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "proyectos_update" ON "oymcomercial"."proyectos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "receta_items_delete" ON "oymcomercial"."receta_items" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "receta_items_insert" ON "oymcomercial"."receta_items" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "receta_items_select" ON "oymcomercial"."receta_items" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "receta_items_update" ON "oymcomercial"."receta_items" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "recetas_delete" ON "oymcomercial"."recetas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "recetas_insert" ON "oymcomercial"."recetas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "recetas_select" ON "oymcomercial"."recetas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "recetas_update" ON "oymcomercial"."recetas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "recibo_items_empresa_isolation" ON "oymcomercial"."recibos_dinero_items" AS PERMISSIVE FOR ALL TO public USING ((empresa_id = oymcomercial.empresa_id_actual())) WITH CHECK ((empresa_id = oymcomercial.empresa_id_actual()));
CREATE POLICY "sorteo_conv_delete" ON "oymcomercial"."sorteo_conversaciones" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_conv_insert" ON "oymcomercial"."sorteo_conversaciones" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_conv_select" ON "oymcomercial"."sorteo_conversaciones" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_conv_update" ON "oymcomercial"."sorteo_conversaciones" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_cup_delete" ON "oymcomercial"."sorteo_cupones" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_cup_insert" ON "oymcomercial"."sorteo_cupones" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_cup_select" ON "oymcomercial"."sorteo_cupones" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_cup_update" ON "oymcomercial"."sorteo_cupones" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ent_delete" ON "oymcomercial"."sorteo_entradas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ent_insert" ON "oymcomercial"."sorteo_entradas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ent_select" ON "oymcomercial"."sorteo_entradas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ent_update" ON "oymcomercial"."sorteo_entradas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_clicks_delete" ON "oymcomercial"."sorteo_revendedor_clicks" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_clicks_insert" ON "oymcomercial"."sorteo_revendedor_clicks" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_clicks_select" ON "oymcomercial"."sorteo_revendedor_clicks" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_clicks_update" ON "oymcomercial"."sorteo_revendedor_clicks" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_delete" ON "oymcomercial"."sorteo_revendedores" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_insert" ON "oymcomercial"."sorteo_revendedores" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_select" ON "oymcomercial"."sorteo_revendedores" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_rev_update" ON "oymcomercial"."sorteo_revendedores" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ticket_deliveries_delete" ON "oymcomercial"."sorteo_ticket_deliveries" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ticket_deliveries_insert" ON "oymcomercial"."sorteo_ticket_deliveries" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ticket_deliveries_select" ON "oymcomercial"."sorteo_ticket_deliveries" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteo_ticket_deliveries_update" ON "oymcomercial"."sorteo_ticket_deliveries" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteos_delete" ON "oymcomercial"."sorteos" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteos_insert" ON "oymcomercial"."sorteos" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteos_select" ON "oymcomercial"."sorteos" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "sorteos_update" ON "oymcomercial"."sorteos" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "suscripciones_delete" ON "oymcomercial"."suscripciones" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "suscripciones_insert" ON "oymcomercial"."suscripciones" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "suscripciones_select" ON "oymcomercial"."suscripciones" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "suscripciones_update" ON "oymcomercial"."suscripciones" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "tipificaciones_delete" ON "oymcomercial"."tipificaciones" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "tipificaciones_insert" ON "oymcomercial"."tipificaciones" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "tipificaciones_select" ON "oymcomercial"."tipificaciones" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "tipificaciones_update" ON "oymcomercial"."tipificaciones" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "transf_empresa_isolation" ON "oymcomercial"."transferencias_inventario" AS PERMISSIVE FOR ALL TO public USING ((empresa_id = oymcomercial.empresa_id_actual())) WITH CHECK ((empresa_id = oymcomercial.empresa_id_actual()));
CREATE POLICY "transf_items_empresa_isolation" ON "oymcomercial"."transferencias_inventario_items" AS PERMISSIVE FOR ALL TO public USING ((empresa_id = oymcomercial.empresa_id_actual())) WITH CHECK ((empresa_id = oymcomercial.empresa_id_actual()));
CREATE POLICY "udv_delete" ON "oymcomercial"."usuario_dashboard_views" AS PERMISSIVE FOR DELETE TO public USING ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_dashboard_views.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = lower(TRIM(BOTH FROM COALESCE((auth.jwt() ->> 'email'::text), ''::text)))) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text])))))));
CREATE POLICY "udv_insert" ON "oymcomercial"."usuario_dashboard_views" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_dashboard_views.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = lower(TRIM(BOTH FROM COALESCE((auth.jwt() ->> 'email'::text), ''::text)))) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text])))))));
CREATE POLICY "udv_select" ON "oymcomercial"."usuario_dashboard_views" AS PERMISSIVE FOR SELECT TO public USING ((oymcomercial.es_super_admin() OR (usuario_id IN ( SELECT usuarios.id
   FROM oymcomercial.usuarios
  WHERE (lower(TRIM(BOTH FROM COALESCE(usuarios.email, ''::text))) = lower(TRIM(BOTH FROM COALESCE((auth.jwt() ->> 'email'::text), ''::text))))))));
CREATE POLICY "udv_update" ON "oymcomercial"."usuario_dashboard_views" AS PERMISSIVE FOR UPDATE TO public USING ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_dashboard_views.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = lower(TRIM(BOTH FROM COALESCE((auth.jwt() ->> 'email'::text), ''::text)))) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text]))))))) WITH CHECK ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_dashboard_views.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = lower(TRIM(BOTH FROM COALESCE((auth.jwt() ->> 'email'::text), ''::text)))) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text])))))));
CREATE POLICY "usuario_modulos_delete" ON "oymcomercial"."usuario_modulos" AS PERMISSIVE FOR DELETE TO public USING ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_modulos.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = oymcomercial.jwt_email_normalized()) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text])))))));
CREATE POLICY "usuario_modulos_insert" ON "oymcomercial"."usuario_modulos" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_modulos.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = oymcomercial.jwt_email_normalized()) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text])))))));
CREATE POLICY "usuario_modulos_select" ON "oymcomercial"."usuario_modulos" AS PERMISSIVE FOR SELECT TO public USING ((oymcomercial.es_super_admin() OR (usuario_id IN ( SELECT usuarios.id
   FROM oymcomercial.usuarios
  WHERE (lower(TRIM(BOTH FROM COALESCE(usuarios.email, ''::text))) = oymcomercial.jwt_email_normalized())))));
CREATE POLICY "usuario_modulos_update" ON "oymcomercial"."usuario_modulos" AS PERMISSIVE FOR UPDATE TO public USING ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_modulos.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = oymcomercial.jwt_email_normalized()) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text]))))))) WITH CHECK ((oymcomercial.es_super_admin() OR (EXISTS ( SELECT 1
   FROM (oymcomercial.usuarios ua
     JOIN oymcomercial.usuarios ut ON ((ut.id = usuario_modulos.usuario_id)))
  WHERE ((lower(TRIM(BOTH FROM COALESCE(ua.email, ''::text))) = oymcomercial.jwt_email_normalized()) AND (ua.empresa_id IS NOT NULL) AND (ua.empresa_id = ut.empresa_id) AND (COALESCE(ua.rol, ''::text) = ANY (ARRAY['admin'::text, 'administrador'::text])))))));
CREATE POLICY "usuarios_delete" ON "oymcomercial"."usuarios" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.es_super_admin());
CREATE POLICY "usuarios_insert" ON "oymcomercial"."usuarios" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((oymcomercial.es_super_admin() OR ((empresa_id = oymcomercial.empresa_id_actual()) AND (empresa_id IS NOT NULL))));
CREATE POLICY "usuarios_select" ON "oymcomercial"."usuarios" AS PERMISSIVE FOR SELECT TO public USING ((oymcomercial.es_super_admin() OR (empresa_id = oymcomercial.empresa_id_actual()) OR ((empresa_id IS NULL) AND (rol = 'super_admin'::text)) OR (auth_user_id = auth.uid())));
CREATE POLICY "usuarios_update" ON "oymcomercial"."usuarios" AS PERMISSIVE FOR UPDATE TO public USING ((oymcomercial.es_super_admin() OR (empresa_id = oymcomercial.empresa_id_actual()) OR ((empresa_id IS NULL) AND (rol = 'super_admin'::text)))) WITH CHECK ((oymcomercial.es_super_admin() OR (empresa_id = oymcomercial.empresa_id_actual()) OR ((empresa_id IS NULL) AND (rol = 'super_admin'::text))));
CREATE POLICY "ventas_delete" ON "oymcomercial"."ventas" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_insert" ON "oymcomercial"."ventas" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_select" ON "oymcomercial"."ventas" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_update" ON "oymcomercial"."ventas" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_items_delete" ON "oymcomercial"."ventas_items" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_items_insert" ON "oymcomercial"."ventas_items" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_items_select" ON "oymcomercial"."ventas_items" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_items_update" ON "oymcomercial"."ventas_items" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_pagos_detalle_delete" ON "oymcomercial"."ventas_pagos_detalle" AS PERMISSIVE FOR DELETE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_pagos_detalle_insert" ON "oymcomercial"."ventas_pagos_detalle" AS PERMISSIVE FOR INSERT TO public WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_pagos_detalle_select" ON "oymcomercial"."ventas_pagos_detalle" AS PERMISSIVE FOR SELECT TO public USING (oymcomercial.puede_acceder_empresa(empresa_id));
CREATE POLICY "ventas_pagos_detalle_update" ON "oymcomercial"."ventas_pagos_detalle" AS PERMISSIVE FOR UPDATE TO public USING (oymcomercial.puede_acceder_empresa(empresa_id)) WITH CHECK (oymcomercial.puede_acceder_empresa(empresa_id));

-- ---------- TRIGGERS ----------
CREATE TRIGGER tr_chat_agents_updated BEFORE UPDATE ON oymcomercial.chat_agents FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_campaign_jobs_updated BEFORE UPDATE ON oymcomercial.chat_campaign_jobs FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_campaign_recipients_updated BEFORE UPDATE ON oymcomercial.chat_campaign_recipients FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_campaign_templates_updated BEFORE UPDATE ON oymcomercial.chat_campaign_templates FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_campaigns_updated BEFORE UPDATE ON oymcomercial.chat_campaigns FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_channel_quick_replies_updated BEFORE UPDATE ON oymcomercial.chat_channel_quick_replies FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_channels_updated BEFORE UPDATE ON oymcomercial.chat_channels FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_comp_val_updated BEFORE UPDATE ON oymcomercial.chat_comprobante_validaciones FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_contacts_phone_normalized BEFORE INSERT OR UPDATE OF phone_number ON oymcomercial.chat_contacts FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_chat_contact_phone_normalized();
CREATE TRIGGER tr_chat_contacts_updated BEFORE UPDATE ON oymcomercial.chat_contacts FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_conversations_updated BEFORE UPDATE ON oymcomercial.chat_conversations FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_empresa_operator_roles_updated BEFORE UPDATE ON oymcomercial.chat_empresa_operator_roles FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_cfr_rules_updated BEFORE UPDATE ON oymcomercial.chat_flow_recontact_rules FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_flows_updated BEFORE UPDATE ON oymcomercial.chat_flows FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_omn_sched_updated BEFORE UPDATE ON oymcomercial.chat_omnicanal_work_schedules FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_queues_updated BEFORE UPDATE ON oymcomercial.chat_queues FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_chat_usuario_omnicanal_updated BEFORE UPDATE ON oymcomercial.chat_usuario_omnicanal FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER cliente_perfil_tributario_updated_at BEFORE UPDATE ON oymcomercial.cliente_perfil_tributario FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER cliente_tipos_servicio_catalogo_updated_at BEFORE UPDATE ON oymcomercial.cliente_tipos_servicio_catalogo FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER trg_clientes_tipo_servicio_catalogo BEFORE INSERT OR UPDATE OF tipo_servicio_cliente ON oymcomercial.clientes FOR EACH ROW EXECUTE FUNCTION oymcomercial.trg_clientes_tipo_servicio_requiere_catalogo();
CREATE TRIGGER trg_heredar_sucursal BEFORE INSERT ON oymcomercial.cobros_clientes FOR EACH ROW EXECUTE FUNCTION oymcomercial.fn_heredar_sucursal_id();
CREATE TRIGGER tr_comision_equipos_updated BEFORE UPDATE ON oymcomercial.comision_equipos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_comision_escalas_updated BEFORE UPDATE ON oymcomercial.comision_escalas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_comision_periodos_updated BEFORE UPDATE ON oymcomercial.comision_periodos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_comision_politicas_updated BEFORE UPDATE ON oymcomercial.comision_politicas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER compras_updated_at BEFORE UPDATE ON oymcomercial.compras FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER crm_etapas_updated_at BEFORE UPDATE ON oymcomercial.crm_etapas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER crm_notas_updated_at BEFORE UPDATE ON oymcomercial.crm_notas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER crm_prospectos_updated_at BEFORE UPDATE ON oymcomercial.crm_prospectos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_crm_prospectos_updated();
CREATE TRIGGER empresa_sifen_config_updated_at BEFORE UPDATE ON oymcomercial.empresa_sifen_config FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER factura_electronica_updated_at BEFORE UPDATE ON oymcomercial.factura_electronica FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER trg_heredar_sucursal BEFORE INSERT ON oymcomercial.factura_electronica FOR EACH ROW EXECUTE FUNCTION oymcomercial.fn_heredar_sucursal_id();
CREATE TRIGGER facturas_updated_at BEFORE UPDATE ON oymcomercial.facturas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_marketing_calendarios_updated BEFORE UPDATE ON oymcomercial.marketing_calendarios FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_marketing_piezas_updated BEFORE UPDATE ON oymcomercial.marketing_piezas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER marketing_tasks_updated_at BEFORE UPDATE ON oymcomercial.marketing_tasks FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER movimientos_updated_at BEFORE UPDATE ON oymcomercial.movimientos_inventario FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER trg_heredar_sucursal BEFORE INSERT ON oymcomercial.movimientos_inventario FOR EACH ROW EXECUTE FUNCTION oymcomercial.fn_heredar_sucursal_id();
CREATE TRIGGER nota_credito_updated_at BEFORE UPDATE ON oymcomercial.nota_credito FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER nota_credito_electronica_updated_at BEFORE UPDATE ON oymcomercial.nota_credito_electronica FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER nota_credito_items_updated_at BEFORE UPDATE ON oymcomercial.nota_credito_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER planes_updated_at BEFORE UPDATE ON oymcomercial.planes FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER trg_heredar_sucursal BEFORE INSERT ON oymcomercial.producciones FOR EACH ROW EXECUTE FUNCTION oymcomercial.fn_heredar_sucursal_id();
CREATE TRIGGER productos_updated_at BEFORE UPDATE ON oymcomercial.productos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER proveedor_categorias_updated_at BEFORE UPDATE ON oymcomercial.proveedor_categorias FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER proveedor_productos_updated_at BEFORE UPDATE ON oymcomercial.proveedor_productos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER proveedores_updated_at BEFORE UPDATE ON oymcomercial.proveedores FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_proyecto_comentarios_updated BEFORE UPDATE ON oymcomercial.proyecto_comentarios FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_proyecto_estados_updated BEFORE UPDATE ON oymcomercial.proyecto_estados FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_proyecto_prioridades_config_updated BEFORE UPDATE ON oymcomercial.proyecto_prioridades_config FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_proyecto_tareas_updated BEFORE UPDATE ON oymcomercial.proyecto_tareas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_proyecto_tipos_updated BEFORE UPDATE ON oymcomercial.proyecto_tipos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_proyectos_updated BEFORE UPDATE ON oymcomercial.proyectos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER trg_receta_items_updated_at BEFORE UPDATE ON oymcomercial.receta_items FOR EACH ROW EXECUTE FUNCTION oymcomercial._touch_updated_at();
CREATE TRIGGER trg_recetas_updated_at BEFORE UPDATE ON oymcomercial.recetas FOR EACH ROW EXECUTE FUNCTION oymcomercial._touch_updated_at();
CREATE TRIGGER trg_heredar_sucursal BEFORE INSERT ON oymcomercial.recibos_dinero FOR EACH ROW EXECUTE FUNCTION oymcomercial.fn_heredar_sucursal_id();
CREATE TRIGGER trg_heredar_sucursal BEFORE INSERT ON oymcomercial.sifen_jobs FOR EACH ROW EXECUTE FUNCTION oymcomercial.fn_heredar_sucursal_id();
CREATE TRIGGER tr_sorteo_conv_updated BEFORE UPDATE ON oymcomercial.sorteo_conversaciones FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_sorteo_ent_updated BEFORE UPDATE ON oymcomercial.sorteo_entradas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_sorteo_revendedores_updated BEFORE UPDATE ON oymcomercial.sorteo_revendedores FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_sorteo_ticket_deliveries_updated BEFORE UPDATE ON oymcomercial.sorteo_ticket_deliveries FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_sorteos_updated BEFORE UPDATE ON oymcomercial.sorteos FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tipificaciones_updated_at BEFORE UPDATE ON oymcomercial.tipificaciones FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER transferencias_inventario_updated_at BEFORE UPDATE ON oymcomercial.transferencias_inventario FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER transferencias_items_updated_at BEFORE UPDATE ON oymcomercial.transferencias_inventario_items FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER tr_usuario_modulos_validar_empresa BEFORE INSERT OR UPDATE OF modulo_id, usuario_id ON oymcomercial.usuario_modulos FOR EACH ROW EXECUTE FUNCTION oymcomercial.trg_usuario_modulos_validar_modulo_empresa();
CREATE TRIGGER ventas_updated_at BEFORE UPDATE ON oymcomercial.ventas FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();
CREATE TRIGGER ventas_items_updated_at BEFORE UPDATE ON oymcomercial.ventas_items FOR EACH ROW EXECUTE FUNCTION oymcomercial.set_updated_at();

-- ---------- GRANTS (tablas) ----------
GRANT DELETE ON "oymcomercial"."categorias_productos" TO "anon";
GRANT INSERT ON "oymcomercial"."categorias_productos" TO "anon";
GRANT SELECT ON "oymcomercial"."categorias_productos" TO "anon";
GRANT UPDATE ON "oymcomercial"."categorias_productos" TO "anon";
GRANT DELETE ON "oymcomercial"."categorias_productos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."categorias_productos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."categorias_productos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."categorias_productos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT INSERT ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT SELECT ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."categorias_productos" TO "postgres";
GRANT DELETE ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT INSERT ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT SELECT ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."categorias_productos" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_agents" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_agents" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_agents" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_agents" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_agents" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_agents" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_agents" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_agents" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_agents" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_agents" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_agents" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_agents" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_agents" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_agents" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_agents" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_agents" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_agents" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_agents" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_agents" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_agents" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_agents" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_agents" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_campaign_events" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_campaign_events" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_campaign_events" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_campaign_events" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_campaign_events" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_campaign_events" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_campaign_events" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_campaign_events" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_campaign_events" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_campaign_events" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_campaign_jobs" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_campaign_jobs" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_campaign_jobs" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_campaign_jobs" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_campaign_jobs" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_campaign_jobs" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_campaign_jobs" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_campaign_jobs" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_campaign_jobs" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_campaign_jobs" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_campaign_recipients" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_campaign_recipients" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_campaign_recipients" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_campaign_recipients" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_campaign_recipients" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_campaign_recipients" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_campaign_recipients" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_campaign_recipients" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_campaign_recipients" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_campaign_recipients" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_campaign_templates" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_campaign_templates" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_campaign_templates" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_campaign_templates" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_campaign_templates" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_campaign_templates" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_campaign_templates" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_campaign_templates" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_campaign_templates" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_campaign_templates" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_campaigns" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_campaigns" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_campaigns" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_campaigns" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_campaigns" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_campaigns" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_campaigns" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_campaigns" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_campaigns" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_campaigns" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_channel_quick_replies" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_channel_quick_replies" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_channel_quick_replies" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_channel_quick_replies" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_channel_quick_replies" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_channel_quick_replies" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_channel_quick_replies" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_channel_quick_replies" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_channel_quick_replies" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_channel_quick_replies" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_channels" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_channels" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_channels" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_channels" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_channels" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_channels" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_channels" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_channels" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_channels" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_channels" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_channels" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_channels" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_channels" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_channels" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_channels" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_channels" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_channels" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_channels" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_channels" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_channels" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_channels" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_channels" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_comprobante_validaciones" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_comprobante_validaciones" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_comprobante_validaciones" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_comprobante_validaciones" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_comprobante_validaciones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_comprobante_validaciones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_comprobante_validaciones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_comprobante_validaciones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_comprobante_validaciones" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_comprobante_validaciones" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_contacts" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_contacts" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_contacts" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_contacts" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_contacts" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_contacts" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_contacts" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_contacts" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_contacts" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_contacts" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_conversation_closures" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_conversation_closures" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_conversation_closures" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_conversation_closures" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_conversation_closures" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_conversation_closures" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_conversation_closures" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_conversation_closures" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_conversation_closures" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_conversation_closures" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_conversations" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_conversations" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_conversations" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_conversations" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_conversations" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_conversations" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_conversations" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_conversations" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_conversations" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_conversations" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_empresa_operator_roles" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_empresa_operator_roles" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_empresa_operator_roles" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_empresa_operator_roles" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_empresa_operator_roles" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_empresa_operator_roles" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_empresa_operator_roles" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_empresa_operator_roles" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_empresa_operator_roles" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_empresa_operator_roles" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_data" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_data" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_data" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_data" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_data" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_data" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_data" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_data" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_data" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_data" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_events" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_events" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_events" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_events" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_events" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_events" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_events" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_events" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_events" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_events" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_node_blocks" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_node_blocks" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_node_blocks" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_node_blocks" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_node_blocks" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_node_blocks" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_node_blocks" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_node_blocks" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_node_blocks" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_node_blocks" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_nodes" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_nodes" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_nodes" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_nodes" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_nodes" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_nodes" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_nodes" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_nodes" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_nodes" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_nodes" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_options" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_options" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_options" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_options" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_options" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_options" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_options" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_options" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_options" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_options" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_rules" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_rules" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_rules" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_rules" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_rules" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_rules" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_rules" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_rules" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_rules" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_rules" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_runs" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_runs" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_runs" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_runs" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_runs" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_runs" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_runs" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_runs" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_runs" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_recontact_runs" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flow_sessions" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flow_sessions" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flow_sessions" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flow_sessions" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flow_sessions" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flow_sessions" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flow_sessions" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flow_sessions" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flow_sessions" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flow_sessions" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_flows" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_flows" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_flows" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_flows" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_flows" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_flows" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_flows" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_flows" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_flows" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_flows" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_flows" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_flows" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_flows" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_flows" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_flows" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_flows" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_flows" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_flows" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_flows" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_flows" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_flows" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_flows" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_messages" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_messages" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_messages" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_messages" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_messages" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_messages" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_messages" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_messages" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_messages" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_messages" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_messages" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_messages" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_messages" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_messages" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_messages" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_messages" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_messages" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_messages" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_messages" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_messages" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_messages" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_messages" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_omnicanal_work_schedules" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_queue_channels" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_queue_channels" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_queue_channels" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_queue_channels" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_queue_channels" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_queue_channels" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_queue_channels" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_queue_channels" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_queue_channels" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_queue_channels" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_states" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_states" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_states" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_states" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_states" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_states" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_states" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_states" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_states" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_states" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_substates" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_substates" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_substates" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_substates" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_substates" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_substates" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_substates" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_substates" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_substates" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_queue_closure_substates" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_queue_supervisors" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_queue_supervisors" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_queue_supervisors" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_queue_supervisors" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_queue_supervisors" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_queue_supervisors" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_queue_supervisors" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_queue_supervisors" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_queue_supervisors" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_queue_supervisors" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_queues" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_queues" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_queues" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_queues" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_queues" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_queues" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_queues" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_queues" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_queues" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_queues" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_queues" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_queues" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_queues" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_queues" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_queues" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_queues" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_queues" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_queues" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_queues" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_queues" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_queues" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_queues" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_routing_events" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_routing_events" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_routing_events" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_routing_events" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_routing_events" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_routing_events" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_routing_events" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_routing_events" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_routing_events" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_routing_events" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_supervisor_agents" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_supervisor_agents" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_supervisor_agents" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_supervisor_agents" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_supervisor_agents" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_supervisor_agents" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_supervisor_agents" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_supervisor_agents" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_supervisor_agents" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_supervisor_agents" TO "service_role";
GRANT DELETE ON "oymcomercial"."chat_usuario_omnicanal" TO "anon";
GRANT INSERT ON "oymcomercial"."chat_usuario_omnicanal" TO "anon";
GRANT SELECT ON "oymcomercial"."chat_usuario_omnicanal" TO "anon";
GRANT UPDATE ON "oymcomercial"."chat_usuario_omnicanal" TO "anon";
GRANT DELETE ON "oymcomercial"."chat_usuario_omnicanal" TO "authenticated";
GRANT INSERT ON "oymcomercial"."chat_usuario_omnicanal" TO "authenticated";
GRANT SELECT ON "oymcomercial"."chat_usuario_omnicanal" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."chat_usuario_omnicanal" TO "authenticated";
GRANT DELETE ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT INSERT ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT SELECT ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT UPDATE ON "oymcomercial"."chat_usuario_omnicanal" TO "postgres";
GRANT DELETE ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT INSERT ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT SELECT ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT UPDATE ON "oymcomercial"."chat_usuario_omnicanal" TO "service_role";
GRANT DELETE ON "oymcomercial"."cliente_historial" TO "anon";
GRANT INSERT ON "oymcomercial"."cliente_historial" TO "anon";
GRANT SELECT ON "oymcomercial"."cliente_historial" TO "anon";
GRANT UPDATE ON "oymcomercial"."cliente_historial" TO "anon";
GRANT DELETE ON "oymcomercial"."cliente_historial" TO "authenticated";
GRANT INSERT ON "oymcomercial"."cliente_historial" TO "authenticated";
GRANT SELECT ON "oymcomercial"."cliente_historial" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."cliente_historial" TO "authenticated";
GRANT DELETE ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT INSERT ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT SELECT ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT UPDATE ON "oymcomercial"."cliente_historial" TO "postgres";
GRANT DELETE ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT INSERT ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT SELECT ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT UPDATE ON "oymcomercial"."cliente_historial" TO "service_role";
GRANT DELETE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "anon";
GRANT INSERT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "anon";
GRANT SELECT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "anon";
GRANT UPDATE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "anon";
GRANT DELETE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "authenticated";
GRANT INSERT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "authenticated";
GRANT SELECT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "authenticated";
GRANT DELETE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT INSERT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT SELECT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT UPDATE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "postgres";
GRANT DELETE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT INSERT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT SELECT ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT UPDATE ON "oymcomercial"."cliente_obligaciones_tributarias" TO "service_role";
GRANT DELETE ON "oymcomercial"."cliente_perfil_tributario" TO "anon";
GRANT INSERT ON "oymcomercial"."cliente_perfil_tributario" TO "anon";
GRANT SELECT ON "oymcomercial"."cliente_perfil_tributario" TO "anon";
GRANT UPDATE ON "oymcomercial"."cliente_perfil_tributario" TO "anon";
GRANT DELETE ON "oymcomercial"."cliente_perfil_tributario" TO "authenticated";
GRANT INSERT ON "oymcomercial"."cliente_perfil_tributario" TO "authenticated";
GRANT SELECT ON "oymcomercial"."cliente_perfil_tributario" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."cliente_perfil_tributario" TO "authenticated";
GRANT DELETE ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT INSERT ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT SELECT ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT UPDATE ON "oymcomercial"."cliente_perfil_tributario" TO "postgres";
GRANT DELETE ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT INSERT ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT SELECT ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT UPDATE ON "oymcomercial"."cliente_perfil_tributario" TO "service_role";
GRANT DELETE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "anon";
GRANT INSERT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "anon";
GRANT SELECT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "anon";
GRANT UPDATE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "anon";
GRANT DELETE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "authenticated";
GRANT INSERT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "authenticated";
GRANT SELECT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "authenticated";
GRANT DELETE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT INSERT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT SELECT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT UPDATE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "postgres";
GRANT DELETE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT INSERT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT SELECT ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT UPDATE ON "oymcomercial"."cliente_tipos_servicio_catalogo" TO "service_role";
GRANT DELETE ON "oymcomercial"."clientes" TO "anon";
GRANT INSERT ON "oymcomercial"."clientes" TO "anon";
GRANT SELECT ON "oymcomercial"."clientes" TO "anon";
GRANT UPDATE ON "oymcomercial"."clientes" TO "anon";
GRANT DELETE ON "oymcomercial"."clientes" TO "authenticated";
GRANT INSERT ON "oymcomercial"."clientes" TO "authenticated";
GRANT SELECT ON "oymcomercial"."clientes" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."clientes" TO "authenticated";
GRANT DELETE ON "oymcomercial"."clientes" TO "postgres";
GRANT INSERT ON "oymcomercial"."clientes" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."clientes" TO "postgres";
GRANT SELECT ON "oymcomercial"."clientes" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."clientes" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."clientes" TO "postgres";
GRANT UPDATE ON "oymcomercial"."clientes" TO "postgres";
GRANT DELETE ON "oymcomercial"."clientes" TO "service_role";
GRANT INSERT ON "oymcomercial"."clientes" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."clientes" TO "service_role";
GRANT SELECT ON "oymcomercial"."clientes" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."clientes" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."clientes" TO "service_role";
GRANT UPDATE ON "oymcomercial"."clientes" TO "service_role";
GRANT DELETE ON "oymcomercial"."cobros_clientes" TO "anon";
GRANT INSERT ON "oymcomercial"."cobros_clientes" TO "anon";
GRANT SELECT ON "oymcomercial"."cobros_clientes" TO "anon";
GRANT UPDATE ON "oymcomercial"."cobros_clientes" TO "anon";
GRANT DELETE ON "oymcomercial"."cobros_clientes" TO "authenticated";
GRANT INSERT ON "oymcomercial"."cobros_clientes" TO "authenticated";
GRANT SELECT ON "oymcomercial"."cobros_clientes" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."cobros_clientes" TO "authenticated";
GRANT DELETE ON "oymcomercial"."cobros_clientes" TO "service_role";
GRANT INSERT ON "oymcomercial"."cobros_clientes" TO "service_role";
GRANT SELECT ON "oymcomercial"."cobros_clientes" TO "service_role";
GRANT UPDATE ON "oymcomercial"."cobros_clientes" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_ajustes" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_ajustes" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_ajustes" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_ajustes" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_ajustes" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_ajustes" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_ajustes" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_ajustes" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_ajustes" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_ajustes" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_equipo_miembros" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_equipo_miembros" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_equipo_miembros" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_equipo_miembros" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_equipo_miembros" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_equipo_miembros" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_equipo_miembros" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_equipo_miembros" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_equipo_miembros" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_equipo_miembros" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_equipos" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_equipos" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_equipos" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_equipos" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_equipos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_equipos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_equipos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_equipos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_equipos" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_equipos" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_escalas" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_escalas" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_escalas" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_escalas" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_escalas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_escalas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_escalas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_escalas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_escalas" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_escalas" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_lineas" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_lineas" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_lineas" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_lineas" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_lineas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_lineas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_lineas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_lineas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_lineas" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_lineas" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_periodos" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_periodos" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_periodos" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_periodos" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_periodos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_periodos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_periodos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_periodos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_periodos" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_periodos" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_politica_versiones" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_politica_versiones" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_politica_versiones" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_politica_versiones" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_politica_versiones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_politica_versiones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_politica_versiones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_politica_versiones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_politica_versiones" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_politica_versiones" TO "service_role";
GRANT DELETE ON "oymcomercial"."comision_politicas" TO "anon";
GRANT INSERT ON "oymcomercial"."comision_politicas" TO "anon";
GRANT SELECT ON "oymcomercial"."comision_politicas" TO "anon";
GRANT UPDATE ON "oymcomercial"."comision_politicas" TO "anon";
GRANT DELETE ON "oymcomercial"."comision_politicas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."comision_politicas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."comision_politicas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."comision_politicas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT INSERT ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT SELECT ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."comision_politicas" TO "postgres";
GRANT DELETE ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT INSERT ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT SELECT ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."comision_politicas" TO "service_role";
GRANT DELETE ON "oymcomercial"."compras" TO "anon";
GRANT INSERT ON "oymcomercial"."compras" TO "anon";
GRANT SELECT ON "oymcomercial"."compras" TO "anon";
GRANT UPDATE ON "oymcomercial"."compras" TO "anon";
GRANT DELETE ON "oymcomercial"."compras" TO "authenticated";
GRANT INSERT ON "oymcomercial"."compras" TO "authenticated";
GRANT SELECT ON "oymcomercial"."compras" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."compras" TO "authenticated";
GRANT DELETE ON "oymcomercial"."compras" TO "postgres";
GRANT INSERT ON "oymcomercial"."compras" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."compras" TO "postgres";
GRANT SELECT ON "oymcomercial"."compras" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."compras" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."compras" TO "postgres";
GRANT UPDATE ON "oymcomercial"."compras" TO "postgres";
GRANT DELETE ON "oymcomercial"."compras" TO "service_role";
GRANT INSERT ON "oymcomercial"."compras" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."compras" TO "service_role";
GRANT SELECT ON "oymcomercial"."compras" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."compras" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."compras" TO "service_role";
GRANT UPDATE ON "oymcomercial"."compras" TO "service_role";
GRANT DELETE ON "oymcomercial"."crm_etapas" TO "anon";
GRANT INSERT ON "oymcomercial"."crm_etapas" TO "anon";
GRANT SELECT ON "oymcomercial"."crm_etapas" TO "anon";
GRANT UPDATE ON "oymcomercial"."crm_etapas" TO "anon";
GRANT DELETE ON "oymcomercial"."crm_etapas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."crm_etapas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."crm_etapas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."crm_etapas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT INSERT ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT SELECT ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."crm_etapas" TO "postgres";
GRANT DELETE ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT INSERT ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT SELECT ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."crm_etapas" TO "service_role";
GRANT DELETE ON "oymcomercial"."crm_notas" TO "anon";
GRANT INSERT ON "oymcomercial"."crm_notas" TO "anon";
GRANT SELECT ON "oymcomercial"."crm_notas" TO "anon";
GRANT UPDATE ON "oymcomercial"."crm_notas" TO "anon";
GRANT DELETE ON "oymcomercial"."crm_notas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."crm_notas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."crm_notas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."crm_notas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."crm_notas" TO "postgres";
GRANT INSERT ON "oymcomercial"."crm_notas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."crm_notas" TO "postgres";
GRANT SELECT ON "oymcomercial"."crm_notas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."crm_notas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."crm_notas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."crm_notas" TO "postgres";
GRANT DELETE ON "oymcomercial"."crm_notas" TO "service_role";
GRANT INSERT ON "oymcomercial"."crm_notas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."crm_notas" TO "service_role";
GRANT SELECT ON "oymcomercial"."crm_notas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."crm_notas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."crm_notas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."crm_notas" TO "service_role";
GRANT DELETE ON "oymcomercial"."crm_prospectos" TO "anon";
GRANT INSERT ON "oymcomercial"."crm_prospectos" TO "anon";
GRANT SELECT ON "oymcomercial"."crm_prospectos" TO "anon";
GRANT UPDATE ON "oymcomercial"."crm_prospectos" TO "anon";
GRANT DELETE ON "oymcomercial"."crm_prospectos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."crm_prospectos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."crm_prospectos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."crm_prospectos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT INSERT ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT SELECT ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."crm_prospectos" TO "postgres";
GRANT DELETE ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT INSERT ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT SELECT ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."crm_prospectos" TO "service_role";
GRANT DELETE ON "oymcomercial"."cuentas_por_cobrar" TO "anon";
GRANT INSERT ON "oymcomercial"."cuentas_por_cobrar" TO "anon";
GRANT SELECT ON "oymcomercial"."cuentas_por_cobrar" TO "anon";
GRANT UPDATE ON "oymcomercial"."cuentas_por_cobrar" TO "anon";
GRANT DELETE ON "oymcomercial"."cuentas_por_cobrar" TO "authenticated";
GRANT INSERT ON "oymcomercial"."cuentas_por_cobrar" TO "authenticated";
GRANT SELECT ON "oymcomercial"."cuentas_por_cobrar" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."cuentas_por_cobrar" TO "authenticated";
GRANT DELETE ON "oymcomercial"."cuentas_por_cobrar" TO "service_role";
GRANT INSERT ON "oymcomercial"."cuentas_por_cobrar" TO "service_role";
GRANT SELECT ON "oymcomercial"."cuentas_por_cobrar" TO "service_role";
GRANT UPDATE ON "oymcomercial"."cuentas_por_cobrar" TO "service_role";
GRANT DELETE ON "oymcomercial"."dashboard_views" TO "anon";
GRANT INSERT ON "oymcomercial"."dashboard_views" TO "anon";
GRANT SELECT ON "oymcomercial"."dashboard_views" TO "anon";
GRANT UPDATE ON "oymcomercial"."dashboard_views" TO "anon";
GRANT DELETE ON "oymcomercial"."dashboard_views" TO "authenticated";
GRANT INSERT ON "oymcomercial"."dashboard_views" TO "authenticated";
GRANT SELECT ON "oymcomercial"."dashboard_views" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."dashboard_views" TO "authenticated";
GRANT DELETE ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT INSERT ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT SELECT ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT UPDATE ON "oymcomercial"."dashboard_views" TO "postgres";
GRANT DELETE ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT INSERT ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT SELECT ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT UPDATE ON "oymcomercial"."dashboard_views" TO "service_role";
GRANT DELETE ON "oymcomercial"."empresa_autoimpresor_config" TO "anon";
GRANT INSERT ON "oymcomercial"."empresa_autoimpresor_config" TO "anon";
GRANT SELECT ON "oymcomercial"."empresa_autoimpresor_config" TO "anon";
GRANT UPDATE ON "oymcomercial"."empresa_autoimpresor_config" TO "anon";
GRANT DELETE ON "oymcomercial"."empresa_autoimpresor_config" TO "authenticated";
GRANT INSERT ON "oymcomercial"."empresa_autoimpresor_config" TO "authenticated";
GRANT SELECT ON "oymcomercial"."empresa_autoimpresor_config" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."empresa_autoimpresor_config" TO "authenticated";
GRANT DELETE ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT INSERT ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT SELECT ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT UPDATE ON "oymcomercial"."empresa_autoimpresor_config" TO "postgres";
GRANT DELETE ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT INSERT ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT SELECT ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT UPDATE ON "oymcomercial"."empresa_autoimpresor_config" TO "service_role";
GRANT DELETE ON "oymcomercial"."empresa_dashboard_views" TO "anon";
GRANT INSERT ON "oymcomercial"."empresa_dashboard_views" TO "anon";
GRANT SELECT ON "oymcomercial"."empresa_dashboard_views" TO "anon";
GRANT UPDATE ON "oymcomercial"."empresa_dashboard_views" TO "anon";
GRANT DELETE ON "oymcomercial"."empresa_dashboard_views" TO "authenticated";
GRANT INSERT ON "oymcomercial"."empresa_dashboard_views" TO "authenticated";
GRANT SELECT ON "oymcomercial"."empresa_dashboard_views" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."empresa_dashboard_views" TO "authenticated";
GRANT DELETE ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT INSERT ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT SELECT ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT UPDATE ON "oymcomercial"."empresa_dashboard_views" TO "postgres";
GRANT DELETE ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT INSERT ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT SELECT ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT UPDATE ON "oymcomercial"."empresa_dashboard_views" TO "service_role";
GRANT DELETE ON "oymcomercial"."empresa_facturacion_modo" TO "anon";
GRANT INSERT ON "oymcomercial"."empresa_facturacion_modo" TO "anon";
GRANT SELECT ON "oymcomercial"."empresa_facturacion_modo" TO "anon";
GRANT UPDATE ON "oymcomercial"."empresa_facturacion_modo" TO "anon";
GRANT DELETE ON "oymcomercial"."empresa_facturacion_modo" TO "authenticated";
GRANT INSERT ON "oymcomercial"."empresa_facturacion_modo" TO "authenticated";
GRANT SELECT ON "oymcomercial"."empresa_facturacion_modo" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."empresa_facturacion_modo" TO "authenticated";
GRANT DELETE ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT INSERT ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT SELECT ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT UPDATE ON "oymcomercial"."empresa_facturacion_modo" TO "postgres";
GRANT DELETE ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT INSERT ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT SELECT ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT UPDATE ON "oymcomercial"."empresa_facturacion_modo" TO "service_role";
GRANT DELETE ON "oymcomercial"."empresa_modulos" TO "anon";
GRANT INSERT ON "oymcomercial"."empresa_modulos" TO "anon";
GRANT SELECT ON "oymcomercial"."empresa_modulos" TO "anon";
GRANT UPDATE ON "oymcomercial"."empresa_modulos" TO "anon";
GRANT DELETE ON "oymcomercial"."empresa_modulos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."empresa_modulos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."empresa_modulos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."empresa_modulos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT INSERT ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT SELECT ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."empresa_modulos" TO "postgres";
GRANT DELETE ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT INSERT ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT SELECT ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."empresa_modulos" TO "service_role";
GRANT DELETE ON "oymcomercial"."empresa_sifen_config" TO "anon";
GRANT INSERT ON "oymcomercial"."empresa_sifen_config" TO "anon";
GRANT SELECT ON "oymcomercial"."empresa_sifen_config" TO "anon";
GRANT UPDATE ON "oymcomercial"."empresa_sifen_config" TO "anon";
GRANT DELETE ON "oymcomercial"."empresa_sifen_config" TO "authenticated";
GRANT INSERT ON "oymcomercial"."empresa_sifen_config" TO "authenticated";
GRANT SELECT ON "oymcomercial"."empresa_sifen_config" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."empresa_sifen_config" TO "authenticated";
GRANT DELETE ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT INSERT ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT SELECT ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT UPDATE ON "oymcomercial"."empresa_sifen_config" TO "postgres";
GRANT DELETE ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT INSERT ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT SELECT ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT UPDATE ON "oymcomercial"."empresa_sifen_config" TO "service_role";
GRANT DELETE ON "oymcomercial"."empresas" TO "anon";
GRANT INSERT ON "oymcomercial"."empresas" TO "anon";
GRANT SELECT ON "oymcomercial"."empresas" TO "anon";
GRANT UPDATE ON "oymcomercial"."empresas" TO "anon";
GRANT DELETE ON "oymcomercial"."empresas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."empresas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."empresas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."empresas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."empresas" TO "postgres";
GRANT INSERT ON "oymcomercial"."empresas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."empresas" TO "postgres";
GRANT SELECT ON "oymcomercial"."empresas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."empresas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."empresas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."empresas" TO "postgres";
GRANT DELETE ON "oymcomercial"."empresas" TO "service_role";
GRANT INSERT ON "oymcomercial"."empresas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."empresas" TO "service_role";
GRANT SELECT ON "oymcomercial"."empresas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."empresas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."empresas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."empresas" TO "service_role";
GRANT DELETE ON "oymcomercial"."entidades_bancarias" TO "anon";
GRANT INSERT ON "oymcomercial"."entidades_bancarias" TO "anon";
GRANT SELECT ON "oymcomercial"."entidades_bancarias" TO "anon";
GRANT UPDATE ON "oymcomercial"."entidades_bancarias" TO "anon";
GRANT DELETE ON "oymcomercial"."entidades_bancarias" TO "authenticated";
GRANT INSERT ON "oymcomercial"."entidades_bancarias" TO "authenticated";
GRANT SELECT ON "oymcomercial"."entidades_bancarias" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."entidades_bancarias" TO "authenticated";
GRANT DELETE ON "oymcomercial"."entidades_bancarias" TO "service_role";
GRANT INSERT ON "oymcomercial"."entidades_bancarias" TO "service_role";
GRANT SELECT ON "oymcomercial"."entidades_bancarias" TO "service_role";
GRANT UPDATE ON "oymcomercial"."entidades_bancarias" TO "service_role";
GRANT DELETE ON "oymcomercial"."factura_correlativos" TO "anon";
GRANT INSERT ON "oymcomercial"."factura_correlativos" TO "anon";
GRANT SELECT ON "oymcomercial"."factura_correlativos" TO "anon";
GRANT UPDATE ON "oymcomercial"."factura_correlativos" TO "anon";
GRANT DELETE ON "oymcomercial"."factura_correlativos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."factura_correlativos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."factura_correlativos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."factura_correlativos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT INSERT ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT SELECT ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."factura_correlativos" TO "postgres";
GRANT DELETE ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT INSERT ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT SELECT ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."factura_correlativos" TO "service_role";
GRANT DELETE ON "oymcomercial"."factura_electronica" TO "anon";
GRANT INSERT ON "oymcomercial"."factura_electronica" TO "anon";
GRANT SELECT ON "oymcomercial"."factura_electronica" TO "anon";
GRANT UPDATE ON "oymcomercial"."factura_electronica" TO "anon";
GRANT DELETE ON "oymcomercial"."factura_electronica" TO "authenticated";
GRANT INSERT ON "oymcomercial"."factura_electronica" TO "authenticated";
GRANT SELECT ON "oymcomercial"."factura_electronica" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."factura_electronica" TO "authenticated";
GRANT DELETE ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT INSERT ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT SELECT ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT UPDATE ON "oymcomercial"."factura_electronica" TO "postgres";
GRANT DELETE ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT INSERT ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT SELECT ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT UPDATE ON "oymcomercial"."factura_electronica" TO "service_role";
GRANT DELETE ON "oymcomercial"."factura_electronica_evento" TO "anon";
GRANT INSERT ON "oymcomercial"."factura_electronica_evento" TO "anon";
GRANT SELECT ON "oymcomercial"."factura_electronica_evento" TO "anon";
GRANT UPDATE ON "oymcomercial"."factura_electronica_evento" TO "anon";
GRANT DELETE ON "oymcomercial"."factura_electronica_evento" TO "authenticated";
GRANT INSERT ON "oymcomercial"."factura_electronica_evento" TO "authenticated";
GRANT SELECT ON "oymcomercial"."factura_electronica_evento" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."factura_electronica_evento" TO "authenticated";
GRANT DELETE ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT INSERT ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT SELECT ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT UPDATE ON "oymcomercial"."factura_electronica_evento" TO "postgres";
GRANT DELETE ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT INSERT ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT SELECT ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT UPDATE ON "oymcomercial"."factura_electronica_evento" TO "service_role";
GRANT DELETE ON "oymcomercial"."factura_items" TO "anon";
GRANT INSERT ON "oymcomercial"."factura_items" TO "anon";
GRANT SELECT ON "oymcomercial"."factura_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."factura_items" TO "anon";
GRANT DELETE ON "oymcomercial"."factura_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."factura_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."factura_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."factura_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."factura_items" TO "postgres";
GRANT INSERT ON "oymcomercial"."factura_items" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."factura_items" TO "postgres";
GRANT SELECT ON "oymcomercial"."factura_items" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."factura_items" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."factura_items" TO "postgres";
GRANT UPDATE ON "oymcomercial"."factura_items" TO "postgres";
GRANT DELETE ON "oymcomercial"."factura_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."factura_items" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."factura_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."factura_items" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."factura_items" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."factura_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."factura_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."facturas" TO "anon";
GRANT INSERT ON "oymcomercial"."facturas" TO "anon";
GRANT SELECT ON "oymcomercial"."facturas" TO "anon";
GRANT UPDATE ON "oymcomercial"."facturas" TO "anon";
GRANT DELETE ON "oymcomercial"."facturas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."facturas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."facturas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."facturas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."facturas" TO "postgres";
GRANT INSERT ON "oymcomercial"."facturas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."facturas" TO "postgres";
GRANT SELECT ON "oymcomercial"."facturas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."facturas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."facturas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."facturas" TO "postgres";
GRANT DELETE ON "oymcomercial"."facturas" TO "service_role";
GRANT INSERT ON "oymcomercial"."facturas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."facturas" TO "service_role";
GRANT SELECT ON "oymcomercial"."facturas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."facturas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."facturas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."facturas" TO "service_role";
GRANT DELETE ON "oymcomercial"."gastos" TO "anon";
GRANT INSERT ON "oymcomercial"."gastos" TO "anon";
GRANT SELECT ON "oymcomercial"."gastos" TO "anon";
GRANT UPDATE ON "oymcomercial"."gastos" TO "anon";
GRANT DELETE ON "oymcomercial"."gastos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."gastos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."gastos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."gastos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."gastos" TO "postgres";
GRANT INSERT ON "oymcomercial"."gastos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."gastos" TO "postgres";
GRANT SELECT ON "oymcomercial"."gastos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."gastos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."gastos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."gastos" TO "postgres";
GRANT DELETE ON "oymcomercial"."gastos" TO "service_role";
GRANT INSERT ON "oymcomercial"."gastos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."gastos" TO "service_role";
GRANT SELECT ON "oymcomercial"."gastos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."gastos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."gastos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."gastos" TO "service_role";
GRANT DELETE ON "oymcomercial"."imports_audit" TO "anon";
GRANT INSERT ON "oymcomercial"."imports_audit" TO "anon";
GRANT SELECT ON "oymcomercial"."imports_audit" TO "anon";
GRANT UPDATE ON "oymcomercial"."imports_audit" TO "anon";
GRANT DELETE ON "oymcomercial"."imports_audit" TO "authenticated";
GRANT INSERT ON "oymcomercial"."imports_audit" TO "authenticated";
GRANT SELECT ON "oymcomercial"."imports_audit" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."imports_audit" TO "authenticated";
GRANT DELETE ON "oymcomercial"."imports_audit" TO "postgres";
GRANT INSERT ON "oymcomercial"."imports_audit" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."imports_audit" TO "postgres";
GRANT SELECT ON "oymcomercial"."imports_audit" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."imports_audit" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."imports_audit" TO "postgres";
GRANT UPDATE ON "oymcomercial"."imports_audit" TO "postgres";
GRANT DELETE ON "oymcomercial"."imports_audit" TO "service_role";
GRANT INSERT ON "oymcomercial"."imports_audit" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."imports_audit" TO "service_role";
GRANT SELECT ON "oymcomercial"."imports_audit" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."imports_audit" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."imports_audit" TO "service_role";
GRANT UPDATE ON "oymcomercial"."imports_audit" TO "service_role";
GRANT DELETE ON "oymcomercial"."inventario_stock_ubicacion" TO "anon";
GRANT INSERT ON "oymcomercial"."inventario_stock_ubicacion" TO "anon";
GRANT SELECT ON "oymcomercial"."inventario_stock_ubicacion" TO "anon";
GRANT UPDATE ON "oymcomercial"."inventario_stock_ubicacion" TO "anon";
GRANT DELETE ON "oymcomercial"."inventario_stock_ubicacion" TO "authenticated";
GRANT INSERT ON "oymcomercial"."inventario_stock_ubicacion" TO "authenticated";
GRANT SELECT ON "oymcomercial"."inventario_stock_ubicacion" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."inventario_stock_ubicacion" TO "authenticated";
GRANT DELETE ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT INSERT ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT SELECT ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT UPDATE ON "oymcomercial"."inventario_stock_ubicacion" TO "postgres";
GRANT DELETE ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT INSERT ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT SELECT ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT UPDATE ON "oymcomercial"."inventario_stock_ubicacion" TO "service_role";
GRANT DELETE ON "oymcomercial"."inventario_ubicaciones" TO "anon";
GRANT INSERT ON "oymcomercial"."inventario_ubicaciones" TO "anon";
GRANT SELECT ON "oymcomercial"."inventario_ubicaciones" TO "anon";
GRANT UPDATE ON "oymcomercial"."inventario_ubicaciones" TO "anon";
GRANT DELETE ON "oymcomercial"."inventario_ubicaciones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."inventario_ubicaciones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."inventario_ubicaciones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."inventario_ubicaciones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT INSERT ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT SELECT ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."inventario_ubicaciones" TO "postgres";
GRANT DELETE ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT INSERT ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT SELECT ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."inventario_ubicaciones" TO "service_role";
GRANT DELETE ON "oymcomercial"."marketing_calendarios" TO "anon";
GRANT INSERT ON "oymcomercial"."marketing_calendarios" TO "anon";
GRANT SELECT ON "oymcomercial"."marketing_calendarios" TO "anon";
GRANT UPDATE ON "oymcomercial"."marketing_calendarios" TO "anon";
GRANT DELETE ON "oymcomercial"."marketing_calendarios" TO "authenticated";
GRANT INSERT ON "oymcomercial"."marketing_calendarios" TO "authenticated";
GRANT SELECT ON "oymcomercial"."marketing_calendarios" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."marketing_calendarios" TO "authenticated";
GRANT DELETE ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT INSERT ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT SELECT ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT UPDATE ON "oymcomercial"."marketing_calendarios" TO "postgres";
GRANT DELETE ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT INSERT ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT SELECT ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT UPDATE ON "oymcomercial"."marketing_calendarios" TO "service_role";
GRANT DELETE ON "oymcomercial"."marketing_comentarios" TO "anon";
GRANT INSERT ON "oymcomercial"."marketing_comentarios" TO "anon";
GRANT SELECT ON "oymcomercial"."marketing_comentarios" TO "anon";
GRANT UPDATE ON "oymcomercial"."marketing_comentarios" TO "anon";
GRANT DELETE ON "oymcomercial"."marketing_comentarios" TO "authenticated";
GRANT INSERT ON "oymcomercial"."marketing_comentarios" TO "authenticated";
GRANT SELECT ON "oymcomercial"."marketing_comentarios" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."marketing_comentarios" TO "authenticated";
GRANT DELETE ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT INSERT ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT SELECT ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT UPDATE ON "oymcomercial"."marketing_comentarios" TO "postgres";
GRANT DELETE ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT INSERT ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT SELECT ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT UPDATE ON "oymcomercial"."marketing_comentarios" TO "service_role";
GRANT DELETE ON "oymcomercial"."marketing_historial_estados" TO "anon";
GRANT INSERT ON "oymcomercial"."marketing_historial_estados" TO "anon";
GRANT SELECT ON "oymcomercial"."marketing_historial_estados" TO "anon";
GRANT UPDATE ON "oymcomercial"."marketing_historial_estados" TO "anon";
GRANT DELETE ON "oymcomercial"."marketing_historial_estados" TO "authenticated";
GRANT INSERT ON "oymcomercial"."marketing_historial_estados" TO "authenticated";
GRANT SELECT ON "oymcomercial"."marketing_historial_estados" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."marketing_historial_estados" TO "authenticated";
GRANT DELETE ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT INSERT ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT SELECT ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT UPDATE ON "oymcomercial"."marketing_historial_estados" TO "postgres";
GRANT DELETE ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT INSERT ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT SELECT ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT UPDATE ON "oymcomercial"."marketing_historial_estados" TO "service_role";
GRANT DELETE ON "oymcomercial"."marketing_piezas" TO "anon";
GRANT INSERT ON "oymcomercial"."marketing_piezas" TO "anon";
GRANT SELECT ON "oymcomercial"."marketing_piezas" TO "anon";
GRANT UPDATE ON "oymcomercial"."marketing_piezas" TO "anon";
GRANT DELETE ON "oymcomercial"."marketing_piezas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."marketing_piezas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."marketing_piezas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."marketing_piezas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT INSERT ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT SELECT ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."marketing_piezas" TO "postgres";
GRANT DELETE ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT INSERT ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT SELECT ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."marketing_piezas" TO "service_role";
GRANT DELETE ON "oymcomercial"."marketing_tasks" TO "anon";
GRANT INSERT ON "oymcomercial"."marketing_tasks" TO "anon";
GRANT SELECT ON "oymcomercial"."marketing_tasks" TO "anon";
GRANT UPDATE ON "oymcomercial"."marketing_tasks" TO "anon";
GRANT DELETE ON "oymcomercial"."marketing_tasks" TO "authenticated";
GRANT INSERT ON "oymcomercial"."marketing_tasks" TO "authenticated";
GRANT SELECT ON "oymcomercial"."marketing_tasks" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."marketing_tasks" TO "authenticated";
GRANT DELETE ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT INSERT ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT SELECT ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT UPDATE ON "oymcomercial"."marketing_tasks" TO "postgres";
GRANT DELETE ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT INSERT ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT SELECT ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT UPDATE ON "oymcomercial"."marketing_tasks" TO "service_role";
GRANT DELETE ON "oymcomercial"."modulos" TO "anon";
GRANT INSERT ON "oymcomercial"."modulos" TO "anon";
GRANT SELECT ON "oymcomercial"."modulos" TO "anon";
GRANT UPDATE ON "oymcomercial"."modulos" TO "anon";
GRANT DELETE ON "oymcomercial"."modulos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."modulos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."modulos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."modulos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."modulos" TO "postgres";
GRANT INSERT ON "oymcomercial"."modulos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."modulos" TO "postgres";
GRANT SELECT ON "oymcomercial"."modulos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."modulos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."modulos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."modulos" TO "postgres";
GRANT DELETE ON "oymcomercial"."modulos" TO "service_role";
GRANT INSERT ON "oymcomercial"."modulos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."modulos" TO "service_role";
GRANT SELECT ON "oymcomercial"."modulos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."modulos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."modulos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."modulos" TO "service_role";
GRANT DELETE ON "oymcomercial"."movimientos_inventario" TO "anon";
GRANT INSERT ON "oymcomercial"."movimientos_inventario" TO "anon";
GRANT SELECT ON "oymcomercial"."movimientos_inventario" TO "anon";
GRANT UPDATE ON "oymcomercial"."movimientos_inventario" TO "anon";
GRANT DELETE ON "oymcomercial"."movimientos_inventario" TO "authenticated";
GRANT INSERT ON "oymcomercial"."movimientos_inventario" TO "authenticated";
GRANT SELECT ON "oymcomercial"."movimientos_inventario" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."movimientos_inventario" TO "authenticated";
GRANT DELETE ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT INSERT ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT SELECT ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT UPDATE ON "oymcomercial"."movimientos_inventario" TO "postgres";
GRANT DELETE ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT INSERT ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT SELECT ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT UPDATE ON "oymcomercial"."movimientos_inventario" TO "service_role";
GRANT DELETE ON "oymcomercial"."nota_credito" TO "anon";
GRANT INSERT ON "oymcomercial"."nota_credito" TO "anon";
GRANT SELECT ON "oymcomercial"."nota_credito" TO "anon";
GRANT UPDATE ON "oymcomercial"."nota_credito" TO "anon";
GRANT DELETE ON "oymcomercial"."nota_credito" TO "authenticated";
GRANT INSERT ON "oymcomercial"."nota_credito" TO "authenticated";
GRANT SELECT ON "oymcomercial"."nota_credito" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."nota_credito" TO "authenticated";
GRANT DELETE ON "oymcomercial"."nota_credito" TO "postgres";
GRANT INSERT ON "oymcomercial"."nota_credito" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."nota_credito" TO "postgres";
GRANT SELECT ON "oymcomercial"."nota_credito" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."nota_credito" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."nota_credito" TO "postgres";
GRANT UPDATE ON "oymcomercial"."nota_credito" TO "postgres";
GRANT DELETE ON "oymcomercial"."nota_credito" TO "service_role";
GRANT INSERT ON "oymcomercial"."nota_credito" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."nota_credito" TO "service_role";
GRANT SELECT ON "oymcomercial"."nota_credito" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."nota_credito" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."nota_credito" TO "service_role";
GRANT UPDATE ON "oymcomercial"."nota_credito" TO "service_role";
GRANT DELETE ON "oymcomercial"."nota_credito_electronica" TO "anon";
GRANT INSERT ON "oymcomercial"."nota_credito_electronica" TO "anon";
GRANT SELECT ON "oymcomercial"."nota_credito_electronica" TO "anon";
GRANT UPDATE ON "oymcomercial"."nota_credito_electronica" TO "anon";
GRANT DELETE ON "oymcomercial"."nota_credito_electronica" TO "authenticated";
GRANT INSERT ON "oymcomercial"."nota_credito_electronica" TO "authenticated";
GRANT SELECT ON "oymcomercial"."nota_credito_electronica" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."nota_credito_electronica" TO "authenticated";
GRANT DELETE ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT INSERT ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT SELECT ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT UPDATE ON "oymcomercial"."nota_credito_electronica" TO "postgres";
GRANT DELETE ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT INSERT ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT SELECT ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT UPDATE ON "oymcomercial"."nota_credito_electronica" TO "service_role";
GRANT DELETE ON "oymcomercial"."nota_credito_evento" TO "anon";
GRANT INSERT ON "oymcomercial"."nota_credito_evento" TO "anon";
GRANT SELECT ON "oymcomercial"."nota_credito_evento" TO "anon";
GRANT UPDATE ON "oymcomercial"."nota_credito_evento" TO "anon";
GRANT DELETE ON "oymcomercial"."nota_credito_evento" TO "authenticated";
GRANT INSERT ON "oymcomercial"."nota_credito_evento" TO "authenticated";
GRANT SELECT ON "oymcomercial"."nota_credito_evento" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."nota_credito_evento" TO "authenticated";
GRANT DELETE ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT INSERT ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT SELECT ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT UPDATE ON "oymcomercial"."nota_credito_evento" TO "postgres";
GRANT DELETE ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT INSERT ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT SELECT ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT UPDATE ON "oymcomercial"."nota_credito_evento" TO "service_role";
GRANT DELETE ON "oymcomercial"."nota_credito_items" TO "anon";
GRANT INSERT ON "oymcomercial"."nota_credito_items" TO "anon";
GRANT SELECT ON "oymcomercial"."nota_credito_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."nota_credito_items" TO "anon";
GRANT DELETE ON "oymcomercial"."nota_credito_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."nota_credito_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."nota_credito_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."nota_credito_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."nota_credito_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."nota_credito_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."nota_credito_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."nota_credito_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "anon";
GRANT INSERT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "anon";
GRANT SELECT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "anon";
GRANT UPDATE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "anon";
GRANT DELETE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "authenticated";
GRANT INSERT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "authenticated";
GRANT SELECT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "authenticated";
GRANT DELETE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT INSERT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT SELECT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT UPDATE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "postgres";
GRANT DELETE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT INSERT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT SELECT ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT UPDATE ON "oymcomercial"."obligaciones_tributarias_catalogo" TO "service_role";
GRANT DELETE ON "oymcomercial"."omnichannel_routes" TO "anon";
GRANT INSERT ON "oymcomercial"."omnichannel_routes" TO "anon";
GRANT SELECT ON "oymcomercial"."omnichannel_routes" TO "anon";
GRANT UPDATE ON "oymcomercial"."omnichannel_routes" TO "anon";
GRANT DELETE ON "oymcomercial"."omnichannel_routes" TO "authenticated";
GRANT INSERT ON "oymcomercial"."omnichannel_routes" TO "authenticated";
GRANT SELECT ON "oymcomercial"."omnichannel_routes" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."omnichannel_routes" TO "authenticated";
GRANT DELETE ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT INSERT ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT SELECT ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT UPDATE ON "oymcomercial"."omnichannel_routes" TO "postgres";
GRANT DELETE ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT INSERT ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT SELECT ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT UPDATE ON "oymcomercial"."omnichannel_routes" TO "service_role";
GRANT DELETE ON "oymcomercial"."pagos" TO "anon";
GRANT INSERT ON "oymcomercial"."pagos" TO "anon";
GRANT SELECT ON "oymcomercial"."pagos" TO "anon";
GRANT UPDATE ON "oymcomercial"."pagos" TO "anon";
GRANT DELETE ON "oymcomercial"."pagos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."pagos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."pagos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."pagos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."pagos" TO "postgres";
GRANT INSERT ON "oymcomercial"."pagos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."pagos" TO "postgres";
GRANT SELECT ON "oymcomercial"."pagos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."pagos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."pagos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."pagos" TO "postgres";
GRANT DELETE ON "oymcomercial"."pagos" TO "service_role";
GRANT INSERT ON "oymcomercial"."pagos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."pagos" TO "service_role";
GRANT SELECT ON "oymcomercial"."pagos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."pagos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."pagos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."pagos" TO "service_role";
GRANT DELETE ON "oymcomercial"."planes" TO "anon";
GRANT INSERT ON "oymcomercial"."planes" TO "anon";
GRANT SELECT ON "oymcomercial"."planes" TO "anon";
GRANT UPDATE ON "oymcomercial"."planes" TO "anon";
GRANT DELETE ON "oymcomercial"."planes" TO "authenticated";
GRANT INSERT ON "oymcomercial"."planes" TO "authenticated";
GRANT SELECT ON "oymcomercial"."planes" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."planes" TO "authenticated";
GRANT DELETE ON "oymcomercial"."planes" TO "postgres";
GRANT INSERT ON "oymcomercial"."planes" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."planes" TO "postgres";
GRANT SELECT ON "oymcomercial"."planes" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."planes" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."planes" TO "postgres";
GRANT UPDATE ON "oymcomercial"."planes" TO "postgres";
GRANT DELETE ON "oymcomercial"."planes" TO "service_role";
GRANT INSERT ON "oymcomercial"."planes" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."planes" TO "service_role";
GRANT SELECT ON "oymcomercial"."planes" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."planes" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."planes" TO "service_role";
GRANT UPDATE ON "oymcomercial"."planes" TO "service_role";
GRANT DELETE ON "oymcomercial"."presupuesto_items" TO "anon";
GRANT INSERT ON "oymcomercial"."presupuesto_items" TO "anon";
GRANT SELECT ON "oymcomercial"."presupuesto_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."presupuesto_items" TO "anon";
GRANT DELETE ON "oymcomercial"."presupuesto_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."presupuesto_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."presupuesto_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."presupuesto_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."presupuesto_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."presupuesto_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."presupuesto_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."presupuesto_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."presupuestos" TO "anon";
GRANT INSERT ON "oymcomercial"."presupuestos" TO "anon";
GRANT SELECT ON "oymcomercial"."presupuestos" TO "anon";
GRANT UPDATE ON "oymcomercial"."presupuestos" TO "anon";
GRANT DELETE ON "oymcomercial"."presupuestos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."presupuestos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."presupuestos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."presupuestos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."presupuestos" TO "service_role";
GRANT INSERT ON "oymcomercial"."presupuestos" TO "service_role";
GRANT SELECT ON "oymcomercial"."presupuestos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."presupuestos" TO "service_role";
GRANT DELETE ON "oymcomercial"."produccion_items" TO "anon";
GRANT INSERT ON "oymcomercial"."produccion_items" TO "anon";
GRANT SELECT ON "oymcomercial"."produccion_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."produccion_items" TO "anon";
GRANT DELETE ON "oymcomercial"."produccion_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."produccion_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."produccion_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."produccion_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."produccion_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."produccion_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."produccion_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."produccion_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."producciones" TO "anon";
GRANT INSERT ON "oymcomercial"."producciones" TO "anon";
GRANT SELECT ON "oymcomercial"."producciones" TO "anon";
GRANT UPDATE ON "oymcomercial"."producciones" TO "anon";
GRANT DELETE ON "oymcomercial"."producciones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."producciones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."producciones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."producciones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."producciones" TO "service_role";
GRANT INSERT ON "oymcomercial"."producciones" TO "service_role";
GRANT SELECT ON "oymcomercial"."producciones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."producciones" TO "service_role";
GRANT DELETE ON "oymcomercial"."producto_categorias" TO "anon";
GRANT INSERT ON "oymcomercial"."producto_categorias" TO "anon";
GRANT SELECT ON "oymcomercial"."producto_categorias" TO "anon";
GRANT UPDATE ON "oymcomercial"."producto_categorias" TO "anon";
GRANT DELETE ON "oymcomercial"."producto_categorias" TO "authenticated";
GRANT INSERT ON "oymcomercial"."producto_categorias" TO "authenticated";
GRANT SELECT ON "oymcomercial"."producto_categorias" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."producto_categorias" TO "authenticated";
GRANT DELETE ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT INSERT ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT SELECT ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT UPDATE ON "oymcomercial"."producto_categorias" TO "postgres";
GRANT DELETE ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT INSERT ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT SELECT ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT UPDATE ON "oymcomercial"."producto_categorias" TO "service_role";
GRANT DELETE ON "oymcomercial"."productos" TO "anon";
GRANT INSERT ON "oymcomercial"."productos" TO "anon";
GRANT SELECT ON "oymcomercial"."productos" TO "anon";
GRANT UPDATE ON "oymcomercial"."productos" TO "anon";
GRANT DELETE ON "oymcomercial"."productos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."productos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."productos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."productos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."productos" TO "postgres";
GRANT INSERT ON "oymcomercial"."productos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."productos" TO "postgres";
GRANT SELECT ON "oymcomercial"."productos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."productos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."productos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."productos" TO "postgres";
GRANT DELETE ON "oymcomercial"."productos" TO "service_role";
GRANT INSERT ON "oymcomercial"."productos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."productos" TO "service_role";
GRANT SELECT ON "oymcomercial"."productos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."productos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."productos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."productos" TO "service_role";
GRANT DELETE ON "oymcomercial"."productos_codigo_secuencia" TO "anon";
GRANT INSERT ON "oymcomercial"."productos_codigo_secuencia" TO "anon";
GRANT SELECT ON "oymcomercial"."productos_codigo_secuencia" TO "anon";
GRANT UPDATE ON "oymcomercial"."productos_codigo_secuencia" TO "anon";
GRANT DELETE ON "oymcomercial"."productos_codigo_secuencia" TO "authenticated";
GRANT INSERT ON "oymcomercial"."productos_codigo_secuencia" TO "authenticated";
GRANT SELECT ON "oymcomercial"."productos_codigo_secuencia" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."productos_codigo_secuencia" TO "authenticated";
GRANT DELETE ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT INSERT ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT SELECT ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT UPDATE ON "oymcomercial"."productos_codigo_secuencia" TO "postgres";
GRANT DELETE ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT INSERT ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT SELECT ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT UPDATE ON "oymcomercial"."productos_codigo_secuencia" TO "service_role";
GRANT DELETE ON "oymcomercial"."proveedor_categoria_rel" TO "anon";
GRANT INSERT ON "oymcomercial"."proveedor_categoria_rel" TO "anon";
GRANT SELECT ON "oymcomercial"."proveedor_categoria_rel" TO "anon";
GRANT UPDATE ON "oymcomercial"."proveedor_categoria_rel" TO "anon";
GRANT DELETE ON "oymcomercial"."proveedor_categoria_rel" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proveedor_categoria_rel" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proveedor_categoria_rel" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proveedor_categoria_rel" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT INSERT ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT SELECT ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proveedor_categoria_rel" TO "postgres";
GRANT DELETE ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT INSERT ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT SELECT ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proveedor_categoria_rel" TO "service_role";
GRANT DELETE ON "oymcomercial"."proveedor_categorias" TO "anon";
GRANT INSERT ON "oymcomercial"."proveedor_categorias" TO "anon";
GRANT SELECT ON "oymcomercial"."proveedor_categorias" TO "anon";
GRANT UPDATE ON "oymcomercial"."proveedor_categorias" TO "anon";
GRANT DELETE ON "oymcomercial"."proveedor_categorias" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proveedor_categorias" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proveedor_categorias" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proveedor_categorias" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT INSERT ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT SELECT ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proveedor_categorias" TO "postgres";
GRANT DELETE ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT INSERT ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT SELECT ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proveedor_categorias" TO "service_role";
GRANT DELETE ON "oymcomercial"."proveedor_productos" TO "anon";
GRANT INSERT ON "oymcomercial"."proveedor_productos" TO "anon";
GRANT SELECT ON "oymcomercial"."proveedor_productos" TO "anon";
GRANT UPDATE ON "oymcomercial"."proveedor_productos" TO "anon";
GRANT DELETE ON "oymcomercial"."proveedor_productos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proveedor_productos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proveedor_productos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proveedor_productos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT INSERT ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT SELECT ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proveedor_productos" TO "postgres";
GRANT DELETE ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT INSERT ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT SELECT ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proveedor_productos" TO "service_role";
GRANT DELETE ON "oymcomercial"."proveedores" TO "anon";
GRANT INSERT ON "oymcomercial"."proveedores" TO "anon";
GRANT SELECT ON "oymcomercial"."proveedores" TO "anon";
GRANT UPDATE ON "oymcomercial"."proveedores" TO "anon";
GRANT DELETE ON "oymcomercial"."proveedores" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proveedores" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proveedores" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proveedores" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proveedores" TO "postgres";
GRANT INSERT ON "oymcomercial"."proveedores" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proveedores" TO "postgres";
GRANT SELECT ON "oymcomercial"."proveedores" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proveedores" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proveedores" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proveedores" TO "postgres";
GRANT DELETE ON "oymcomercial"."proveedores" TO "service_role";
GRANT INSERT ON "oymcomercial"."proveedores" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proveedores" TO "service_role";
GRANT SELECT ON "oymcomercial"."proveedores" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proveedores" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proveedores" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proveedores" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_archivos" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_archivos" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_archivos" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_archivos" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_archivos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_archivos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_archivos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_archivos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_archivos" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_archivos" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_comentarios" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_comentarios" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_comentarios" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_comentarios" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_comentarios" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_comentarios" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_comentarios" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_comentarios" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_comentarios" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_comentarios" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_estado_historial" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_estado_historial" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_estado_historial" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_estado_historial" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_estado_historial" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_estado_historial" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_estado_historial" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_estado_historial" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_estado_historial" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_estado_historial" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_estados" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_estados" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_estados" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_estados" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_estados" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_estados" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_estados" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_estados" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_estados" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_estados" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_prioridades_config" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_prioridades_config" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_prioridades_config" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_prioridades_config" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_prioridades_config" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_prioridades_config" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_prioridades_config" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_prioridades_config" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_prioridades_config" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_prioridades_config" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_tareas" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_tareas" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_tareas" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_tareas" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_tareas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_tareas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_tareas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_tareas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_tareas" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_tareas" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyecto_tipos" TO "anon";
GRANT INSERT ON "oymcomercial"."proyecto_tipos" TO "anon";
GRANT SELECT ON "oymcomercial"."proyecto_tipos" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyecto_tipos" TO "anon";
GRANT DELETE ON "oymcomercial"."proyecto_tipos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyecto_tipos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyecto_tipos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyecto_tipos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyecto_tipos" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyecto_tipos" TO "service_role";
GRANT DELETE ON "oymcomercial"."proyectos" TO "anon";
GRANT INSERT ON "oymcomercial"."proyectos" TO "anon";
GRANT SELECT ON "oymcomercial"."proyectos" TO "anon";
GRANT UPDATE ON "oymcomercial"."proyectos" TO "anon";
GRANT DELETE ON "oymcomercial"."proyectos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."proyectos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."proyectos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."proyectos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."proyectos" TO "postgres";
GRANT INSERT ON "oymcomercial"."proyectos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."proyectos" TO "postgres";
GRANT SELECT ON "oymcomercial"."proyectos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."proyectos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."proyectos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."proyectos" TO "postgres";
GRANT DELETE ON "oymcomercial"."proyectos" TO "service_role";
GRANT INSERT ON "oymcomercial"."proyectos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."proyectos" TO "service_role";
GRANT SELECT ON "oymcomercial"."proyectos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."proyectos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."proyectos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."proyectos" TO "service_role";
GRANT DELETE ON "oymcomercial"."receta_items" TO "anon";
GRANT INSERT ON "oymcomercial"."receta_items" TO "anon";
GRANT SELECT ON "oymcomercial"."receta_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."receta_items" TO "anon";
GRANT DELETE ON "oymcomercial"."receta_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."receta_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."receta_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."receta_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."receta_items" TO "postgres";
GRANT INSERT ON "oymcomercial"."receta_items" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."receta_items" TO "postgres";
GRANT SELECT ON "oymcomercial"."receta_items" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."receta_items" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."receta_items" TO "postgres";
GRANT UPDATE ON "oymcomercial"."receta_items" TO "postgres";
GRANT DELETE ON "oymcomercial"."receta_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."receta_items" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."receta_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."receta_items" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."receta_items" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."receta_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."receta_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."recetas" TO "anon";
GRANT INSERT ON "oymcomercial"."recetas" TO "anon";
GRANT SELECT ON "oymcomercial"."recetas" TO "anon";
GRANT UPDATE ON "oymcomercial"."recetas" TO "anon";
GRANT DELETE ON "oymcomercial"."recetas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."recetas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."recetas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."recetas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."recetas" TO "postgres";
GRANT INSERT ON "oymcomercial"."recetas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."recetas" TO "postgres";
GRANT SELECT ON "oymcomercial"."recetas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."recetas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."recetas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."recetas" TO "postgres";
GRANT DELETE ON "oymcomercial"."recetas" TO "service_role";
GRANT INSERT ON "oymcomercial"."recetas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."recetas" TO "service_role";
GRANT SELECT ON "oymcomercial"."recetas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."recetas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."recetas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."recetas" TO "service_role";
GRANT DELETE ON "oymcomercial"."recibos_dinero" TO "anon";
GRANT INSERT ON "oymcomercial"."recibos_dinero" TO "anon";
GRANT SELECT ON "oymcomercial"."recibos_dinero" TO "anon";
GRANT UPDATE ON "oymcomercial"."recibos_dinero" TO "anon";
GRANT DELETE ON "oymcomercial"."recibos_dinero" TO "authenticated";
GRANT INSERT ON "oymcomercial"."recibos_dinero" TO "authenticated";
GRANT SELECT ON "oymcomercial"."recibos_dinero" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."recibos_dinero" TO "authenticated";
GRANT DELETE ON "oymcomercial"."recibos_dinero" TO "service_role";
GRANT INSERT ON "oymcomercial"."recibos_dinero" TO "service_role";
GRANT SELECT ON "oymcomercial"."recibos_dinero" TO "service_role";
GRANT UPDATE ON "oymcomercial"."recibos_dinero" TO "service_role";
GRANT DELETE ON "oymcomercial"."recibos_dinero_items" TO "anon";
GRANT INSERT ON "oymcomercial"."recibos_dinero_items" TO "anon";
GRANT SELECT ON "oymcomercial"."recibos_dinero_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."recibos_dinero_items" TO "anon";
GRANT DELETE ON "oymcomercial"."recibos_dinero_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."recibos_dinero_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."recibos_dinero_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."recibos_dinero_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."recibos_dinero_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."recibos_dinero_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."recibos_dinero_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."recibos_dinero_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."sifen_jobs" TO "anon";
GRANT INSERT ON "oymcomercial"."sifen_jobs" TO "anon";
GRANT SELECT ON "oymcomercial"."sifen_jobs" TO "anon";
GRANT UPDATE ON "oymcomercial"."sifen_jobs" TO "anon";
GRANT DELETE ON "oymcomercial"."sifen_jobs" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sifen_jobs" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sifen_jobs" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sifen_jobs" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sifen_jobs" TO "service_role";
GRANT INSERT ON "oymcomercial"."sifen_jobs" TO "service_role";
GRANT SELECT ON "oymcomercial"."sifen_jobs" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sifen_jobs" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteo_conversaciones" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteo_conversaciones" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteo_conversaciones" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteo_conversaciones" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteo_conversaciones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteo_conversaciones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteo_conversaciones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteo_conversaciones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteo_conversaciones" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteo_conversaciones" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteo_cupones" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteo_cupones" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteo_cupones" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteo_cupones" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteo_cupones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteo_cupones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteo_cupones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteo_cupones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteo_cupones" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteo_cupones" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteo_entradas" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteo_entradas" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteo_entradas" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteo_entradas" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteo_entradas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteo_entradas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteo_entradas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteo_entradas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteo_entradas" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteo_entradas" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteo_revendedor_clicks" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteo_revendedor_clicks" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteo_revendedor_clicks" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedor_clicks" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteo_revendedor_clicks" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteo_revendedor_clicks" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteo_revendedor_clicks" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedor_clicks" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedor_clicks" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedor_clicks" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteo_revendedores" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteo_revendedores" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteo_revendedores" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedores" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteo_revendedores" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteo_revendedores" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteo_revendedores" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedores" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedores" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteo_revendedores" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteo_ticket_deliveries" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteo_ticket_deliveries" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteo_ticket_deliveries" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteo_ticket_deliveries" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteo_ticket_deliveries" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteo_ticket_deliveries" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteo_ticket_deliveries" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteo_ticket_deliveries" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteo_ticket_deliveries" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteo_ticket_deliveries" TO "service_role";
GRANT DELETE ON "oymcomercial"."sorteos" TO "anon";
GRANT INSERT ON "oymcomercial"."sorteos" TO "anon";
GRANT SELECT ON "oymcomercial"."sorteos" TO "anon";
GRANT UPDATE ON "oymcomercial"."sorteos" TO "anon";
GRANT DELETE ON "oymcomercial"."sorteos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sorteos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sorteos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sorteos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sorteos" TO "postgres";
GRANT INSERT ON "oymcomercial"."sorteos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."sorteos" TO "postgres";
GRANT SELECT ON "oymcomercial"."sorteos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."sorteos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."sorteos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."sorteos" TO "postgres";
GRANT DELETE ON "oymcomercial"."sorteos" TO "service_role";
GRANT INSERT ON "oymcomercial"."sorteos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."sorteos" TO "service_role";
GRANT SELECT ON "oymcomercial"."sorteos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."sorteos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."sorteos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sorteos" TO "service_role";
GRANT DELETE ON "oymcomercial"."sucursales" TO "anon";
GRANT INSERT ON "oymcomercial"."sucursales" TO "anon";
GRANT SELECT ON "oymcomercial"."sucursales" TO "anon";
GRANT UPDATE ON "oymcomercial"."sucursales" TO "anon";
GRANT DELETE ON "oymcomercial"."sucursales" TO "authenticated";
GRANT INSERT ON "oymcomercial"."sucursales" TO "authenticated";
GRANT SELECT ON "oymcomercial"."sucursales" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."sucursales" TO "authenticated";
GRANT DELETE ON "oymcomercial"."sucursales" TO "service_role";
GRANT INSERT ON "oymcomercial"."sucursales" TO "service_role";
GRANT SELECT ON "oymcomercial"."sucursales" TO "service_role";
GRANT UPDATE ON "oymcomercial"."sucursales" TO "service_role";
GRANT DELETE ON "oymcomercial"."suscripciones" TO "anon";
GRANT INSERT ON "oymcomercial"."suscripciones" TO "anon";
GRANT SELECT ON "oymcomercial"."suscripciones" TO "anon";
GRANT UPDATE ON "oymcomercial"."suscripciones" TO "anon";
GRANT DELETE ON "oymcomercial"."suscripciones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."suscripciones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."suscripciones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."suscripciones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."suscripciones" TO "postgres";
GRANT INSERT ON "oymcomercial"."suscripciones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."suscripciones" TO "postgres";
GRANT SELECT ON "oymcomercial"."suscripciones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."suscripciones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."suscripciones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."suscripciones" TO "postgres";
GRANT DELETE ON "oymcomercial"."suscripciones" TO "service_role";
GRANT INSERT ON "oymcomercial"."suscripciones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."suscripciones" TO "service_role";
GRANT SELECT ON "oymcomercial"."suscripciones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."suscripciones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."suscripciones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."suscripciones" TO "service_role";
GRANT DELETE ON "oymcomercial"."tipificaciones" TO "anon";
GRANT INSERT ON "oymcomercial"."tipificaciones" TO "anon";
GRANT SELECT ON "oymcomercial"."tipificaciones" TO "anon";
GRANT UPDATE ON "oymcomercial"."tipificaciones" TO "anon";
GRANT DELETE ON "oymcomercial"."tipificaciones" TO "authenticated";
GRANT INSERT ON "oymcomercial"."tipificaciones" TO "authenticated";
GRANT SELECT ON "oymcomercial"."tipificaciones" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."tipificaciones" TO "authenticated";
GRANT DELETE ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT INSERT ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT SELECT ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT UPDATE ON "oymcomercial"."tipificaciones" TO "postgres";
GRANT DELETE ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT INSERT ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT SELECT ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT UPDATE ON "oymcomercial"."tipificaciones" TO "service_role";
GRANT DELETE ON "oymcomercial"."transferencias_inventario" TO "anon";
GRANT INSERT ON "oymcomercial"."transferencias_inventario" TO "anon";
GRANT SELECT ON "oymcomercial"."transferencias_inventario" TO "anon";
GRANT UPDATE ON "oymcomercial"."transferencias_inventario" TO "anon";
GRANT DELETE ON "oymcomercial"."transferencias_inventario" TO "authenticated";
GRANT INSERT ON "oymcomercial"."transferencias_inventario" TO "authenticated";
GRANT SELECT ON "oymcomercial"."transferencias_inventario" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."transferencias_inventario" TO "authenticated";
GRANT DELETE ON "oymcomercial"."transferencias_inventario" TO "service_role";
GRANT INSERT ON "oymcomercial"."transferencias_inventario" TO "service_role";
GRANT SELECT ON "oymcomercial"."transferencias_inventario" TO "service_role";
GRANT UPDATE ON "oymcomercial"."transferencias_inventario" TO "service_role";
GRANT DELETE ON "oymcomercial"."transferencias_inventario_items" TO "anon";
GRANT INSERT ON "oymcomercial"."transferencias_inventario_items" TO "anon";
GRANT SELECT ON "oymcomercial"."transferencias_inventario_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."transferencias_inventario_items" TO "anon";
GRANT DELETE ON "oymcomercial"."transferencias_inventario_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."transferencias_inventario_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."transferencias_inventario_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."transferencias_inventario_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."transferencias_inventario_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."transferencias_inventario_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."transferencias_inventario_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."transferencias_inventario_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."usuario_dashboard_views" TO "anon";
GRANT INSERT ON "oymcomercial"."usuario_dashboard_views" TO "anon";
GRANT SELECT ON "oymcomercial"."usuario_dashboard_views" TO "anon";
GRANT UPDATE ON "oymcomercial"."usuario_dashboard_views" TO "anon";
GRANT DELETE ON "oymcomercial"."usuario_dashboard_views" TO "authenticated";
GRANT INSERT ON "oymcomercial"."usuario_dashboard_views" TO "authenticated";
GRANT SELECT ON "oymcomercial"."usuario_dashboard_views" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."usuario_dashboard_views" TO "authenticated";
GRANT DELETE ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT INSERT ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT SELECT ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT UPDATE ON "oymcomercial"."usuario_dashboard_views" TO "postgres";
GRANT DELETE ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT INSERT ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT SELECT ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT UPDATE ON "oymcomercial"."usuario_dashboard_views" TO "service_role";
GRANT DELETE ON "oymcomercial"."usuario_modulos" TO "anon";
GRANT INSERT ON "oymcomercial"."usuario_modulos" TO "anon";
GRANT SELECT ON "oymcomercial"."usuario_modulos" TO "anon";
GRANT UPDATE ON "oymcomercial"."usuario_modulos" TO "anon";
GRANT DELETE ON "oymcomercial"."usuario_modulos" TO "authenticated";
GRANT INSERT ON "oymcomercial"."usuario_modulos" TO "authenticated";
GRANT SELECT ON "oymcomercial"."usuario_modulos" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."usuario_modulos" TO "authenticated";
GRANT DELETE ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT INSERT ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT SELECT ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT UPDATE ON "oymcomercial"."usuario_modulos" TO "postgres";
GRANT DELETE ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT INSERT ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT SELECT ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT UPDATE ON "oymcomercial"."usuario_modulos" TO "service_role";
GRANT DELETE ON "oymcomercial"."usuarios" TO "anon";
GRANT INSERT ON "oymcomercial"."usuarios" TO "anon";
GRANT SELECT ON "oymcomercial"."usuarios" TO "anon";
GRANT UPDATE ON "oymcomercial"."usuarios" TO "anon";
GRANT DELETE ON "oymcomercial"."usuarios" TO "authenticated";
GRANT INSERT ON "oymcomercial"."usuarios" TO "authenticated";
GRANT SELECT ON "oymcomercial"."usuarios" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."usuarios" TO "authenticated";
GRANT DELETE ON "oymcomercial"."usuarios" TO "postgres";
GRANT INSERT ON "oymcomercial"."usuarios" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."usuarios" TO "postgres";
GRANT SELECT ON "oymcomercial"."usuarios" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."usuarios" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."usuarios" TO "postgres";
GRANT UPDATE ON "oymcomercial"."usuarios" TO "postgres";
GRANT DELETE ON "oymcomercial"."usuarios" TO "service_role";
GRANT INSERT ON "oymcomercial"."usuarios" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."usuarios" TO "service_role";
GRANT SELECT ON "oymcomercial"."usuarios" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."usuarios" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."usuarios" TO "service_role";
GRANT UPDATE ON "oymcomercial"."usuarios" TO "service_role";
GRANT DELETE ON "oymcomercial"."ventas" TO "anon";
GRANT INSERT ON "oymcomercial"."ventas" TO "anon";
GRANT SELECT ON "oymcomercial"."ventas" TO "anon";
GRANT UPDATE ON "oymcomercial"."ventas" TO "anon";
GRANT DELETE ON "oymcomercial"."ventas" TO "authenticated";
GRANT INSERT ON "oymcomercial"."ventas" TO "authenticated";
GRANT SELECT ON "oymcomercial"."ventas" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."ventas" TO "authenticated";
GRANT DELETE ON "oymcomercial"."ventas" TO "postgres";
GRANT INSERT ON "oymcomercial"."ventas" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."ventas" TO "postgres";
GRANT SELECT ON "oymcomercial"."ventas" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."ventas" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."ventas" TO "postgres";
GRANT UPDATE ON "oymcomercial"."ventas" TO "postgres";
GRANT DELETE ON "oymcomercial"."ventas" TO "service_role";
GRANT INSERT ON "oymcomercial"."ventas" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."ventas" TO "service_role";
GRANT SELECT ON "oymcomercial"."ventas" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."ventas" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."ventas" TO "service_role";
GRANT UPDATE ON "oymcomercial"."ventas" TO "service_role";
GRANT DELETE ON "oymcomercial"."ventas_items" TO "anon";
GRANT INSERT ON "oymcomercial"."ventas_items" TO "anon";
GRANT SELECT ON "oymcomercial"."ventas_items" TO "anon";
GRANT UPDATE ON "oymcomercial"."ventas_items" TO "anon";
GRANT DELETE ON "oymcomercial"."ventas_items" TO "authenticated";
GRANT INSERT ON "oymcomercial"."ventas_items" TO "authenticated";
GRANT SELECT ON "oymcomercial"."ventas_items" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."ventas_items" TO "authenticated";
GRANT DELETE ON "oymcomercial"."ventas_items" TO "postgres";
GRANT INSERT ON "oymcomercial"."ventas_items" TO "postgres";
GRANT REFERENCES ON "oymcomercial"."ventas_items" TO "postgres";
GRANT SELECT ON "oymcomercial"."ventas_items" TO "postgres";
GRANT TRIGGER ON "oymcomercial"."ventas_items" TO "postgres";
GRANT TRUNCATE ON "oymcomercial"."ventas_items" TO "postgres";
GRANT UPDATE ON "oymcomercial"."ventas_items" TO "postgres";
GRANT DELETE ON "oymcomercial"."ventas_items" TO "service_role";
GRANT INSERT ON "oymcomercial"."ventas_items" TO "service_role";
GRANT REFERENCES ON "oymcomercial"."ventas_items" TO "service_role";
GRANT SELECT ON "oymcomercial"."ventas_items" TO "service_role";
GRANT TRIGGER ON "oymcomercial"."ventas_items" TO "service_role";
GRANT TRUNCATE ON "oymcomercial"."ventas_items" TO "service_role";
GRANT UPDATE ON "oymcomercial"."ventas_items" TO "service_role";
GRANT DELETE ON "oymcomercial"."ventas_pagos_detalle" TO "anon";
GRANT INSERT ON "oymcomercial"."ventas_pagos_detalle" TO "anon";
GRANT SELECT ON "oymcomercial"."ventas_pagos_detalle" TO "anon";
GRANT UPDATE ON "oymcomercial"."ventas_pagos_detalle" TO "anon";
GRANT DELETE ON "oymcomercial"."ventas_pagos_detalle" TO "authenticated";
GRANT INSERT ON "oymcomercial"."ventas_pagos_detalle" TO "authenticated";
GRANT SELECT ON "oymcomercial"."ventas_pagos_detalle" TO "authenticated";
GRANT UPDATE ON "oymcomercial"."ventas_pagos_detalle" TO "authenticated";
GRANT DELETE ON "oymcomercial"."ventas_pagos_detalle" TO "service_role";
GRANT INSERT ON "oymcomercial"."ventas_pagos_detalle" TO "service_role";
GRANT SELECT ON "oymcomercial"."ventas_pagos_detalle" TO "service_role";
GRANT UPDATE ON "oymcomercial"."ventas_pagos_detalle" TO "service_role";

-- ---------- GRANTS (funciones) ----------
GRANT EXECUTE ON FUNCTION "oymcomercial"."_ensure_categoria" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_ensure_categoria" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_ensure_categoria" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_ensure_categoria" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_touch_updated_at" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_touch_updated_at" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_touch_updated_at" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_touch_updated_at" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_menu" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_menu" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_menu" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_menu" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_reventa" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_reventa" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_reventa" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."_upsert_producto_reventa" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."empresa_id_actual" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."empresa_id_actual" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."empresa_id_actual" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."empresa_id_actual" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."es_super_admin" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."es_super_admin" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."es_super_admin" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."es_super_admin" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_heredar_sucursal_id" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_heredar_sucursal_id" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_heredar_sucursal_id" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_receta_costeo" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_receta_costeo" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_receta_costeo" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."fn_receta_costeo" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."incrementar_secuencia_producto" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."incrementar_secuencia_producto" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."incrementar_secuencia_producto" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."incrementar_secuencia_producto" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."jwt_email_normalized" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."jwt_email_normalized" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."jwt_email_normalized" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."jwt_email_normalized" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."neura_inbox_awaiting_reply_since_batch" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."neura_inbox_awaiting_reply_since_batch" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."neura_inbox_awaiting_reply_since_batch" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."neura_inbox_awaiting_reply_since_batch" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."next_numero_factura_empresa" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."next_numero_factura_empresa" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."next_numero_factura_empresa" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."next_numero_factura_empresa" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_aprobacion_set" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_aprobacion_set" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_aprobacion_set" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_aprobacion_set" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_cancelacion_set" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_cancelacion_set" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_aplicar_cancelacion_set" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_tras_aprobacion_set_transaccional" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_tras_aprobacion_set_transaccional" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_tras_aprobacion_set_transaccional" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."nota_credito_tras_aprobacion_set_transaccional" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."puede_acceder_empresa" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."puede_acceder_empresa" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."puede_acceder_empresa" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."puede_acceder_empresa" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_chat_contact_phone_normalized" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_chat_contact_phone_normalized" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_chat_contact_phone_normalized" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_chat_contact_phone_normalized" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_crm_prospectos_updated" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_crm_prospectos_updated" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_crm_prospectos_updated" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_crm_prospectos_updated" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_updated_at" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_updated_at" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_updated_at" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."set_updated_at" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_ensure_order_from_chat" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_ensure_order_from_chat" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_ensure_order_from_chat" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_ensure_order_from_chat" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_registrar_compra_n8n" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_registrar_compra_n8n" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_registrar_compra_n8n" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."sorteos_registrar_compra_n8n" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_clientes_tipo_servicio_requiere_catalogo" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_clientes_tipo_servicio_requiere_catalogo" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_clientes_tipo_servicio_requiere_catalogo" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_clientes_tipo_servicio_requiere_catalogo" TO "service_role";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_usuario_modulos_validar_modulo_empresa" TO "anon";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_usuario_modulos_validar_modulo_empresa" TO "authenticated";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_usuario_modulos_validar_modulo_empresa" TO "postgres";
GRANT EXECUTE ON FUNCTION "oymcomercial"."trg_usuario_modulos_validar_modulo_empresa" TO "service_role";

-- ---------- COMMENTS ----------
COMMENT ON TABLE "oymcomercial"."sucursales" IS 'Sucursales operativas. El punto de expedición es informativo hasta la Fase 4 (SIFEN).';
COMMENT ON COLUMN "oymcomercial"."chat_agents"."receives_new_chats" IS 'Si false, el agente no entra en asignación automática de chats nuevos';
COMMENT ON COLUMN "oymcomercial"."chat_agents"."priority_in_queue" IS 'Mayor = preferido al empatar estrategias (Etapa 2 puede usarlo más)';
COMMENT ON COLUMN "oymcomercial"."chat_agents"."operational_status_changed_at" IS 'Momento del último cambio de operational_status (ready/offline) en esta fila.';
COMMENT ON COLUMN "oymcomercial"."chat_agents"."last_heartbeat_at" IS 'Último ping desde el inbox del agente (sesión activa en conversaciones).';
COMMENT ON COLUMN "oymcomercial"."chat_agents"."operational_status" IS 'Call center: ready = puede recibir autoasignación; offline = no recibe chats nuevos.';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."type" IS 'Canal omnicanal: whatsapp | instagram | facebook | email';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."nombre" IS 'Etiqueta visible en el ERP';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."provider" IS 'Proveedor: meta';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."provider_channel_id" IS 'ID de canal en el proveedor (ej. WABA o mismo phone_number_id)';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."activo" IS 'Si false, el webhook no enruta mensajes nuevos a este canal';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."whatsapp_access_token" IS 'Bearer de la app Meta para POST /messages; alternativa a WHATSAPP_TOKEN en Vercel';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."connection_mode" IS 'whatsapp: official (Meta Cloud API) | coexistence (YCloud) | standard | null';
COMMENT ON COLUMN "oymcomercial"."chat_channels"."config_status" IS 'active = operativo; incomplete = falta credencial crítica; inactive = deshabilitado a propósito';
COMMENT ON COLUMN "oymcomercial"."chat_comprobante_validaciones"."monto_validacion_esperado_gs" IS 'Monto esperado (GS) desde chat_flow_data del flow_session_id, si aplica validación.';
COMMENT ON COLUMN "oymcomercial"."chat_comprobante_validaciones"."monto_validacion_ocr_gs" IS 'Monto interpretado del OCR (GS).';
COMMENT ON COLUMN "oymcomercial"."chat_comprobante_validaciones"."monto_validacion_diferencia_gs" IS 'abs(esperado - ocr) al momento de validar.';
COMMENT ON COLUMN "oymcomercial"."chat_comprobante_validaciones"."monto_validacion_status" IS 'omitido_config | omitido_sin_esperado | omitido_sin_ocr | coincide | discrepancia | null si no aplica';
COMMENT ON COLUMN "oymcomercial"."chat_comprobante_validaciones"."bank_val_status" IS 'omitido_config | omitido_sin_esperado | omitido_sin_ocr_bancario | coincide | discrepancia';
COMMENT ON COLUMN "oymcomercial"."chat_conversations"."status" IS 'Ciclo operador: open | pending | closed';
COMMENT ON COLUMN "oymcomercial"."chat_conversations"."active_flow_session_id" IS 'Sesión de flujo activa; lecturas/escrituras de variables usan solo esta fila.';
COMMENT ON COLUMN "oymcomercial"."chat_conversations"."first_revendedor_id" IS 'Primer revendedor atribuido en la vida de la conversación (no se pisa).';
COMMENT ON COLUMN "oymcomercial"."chat_conversations"."assigned_agent_id" IS 'Agente responsable (chat_agents.id)';
COMMENT ON COLUMN "oymcomercial"."chat_conversations"."queue_id" IS 'Cola por la que entró la conversación';
COMMENT ON COLUMN "oymcomercial"."chat_conversations"."assignment_wait_code" IS 'UX: conversación en espera — manual_queue (cola manual), no_eligible_agent (sin agentes listos). NULL si hay agente o no aplica.';
COMMENT ON COLUMN "oymcomercial"."chat_flow_data"."flow_session_id" IS 'Run del flujo; único junto con field_name.';
COMMENT ON COLUMN "oymcomercial"."chat_flow_events"."flow_session_id" IS 'Sesión a la que pertenece el evento; hidratación usa solo la sesión activa.';
COMMENT ON COLUMN "oymcomercial"."chat_flow_nodes"."crm_action_type" IS 'Preparado para acciones CRM por nodo (ej: create_lead, move_funnel_stage, assign_advisor)';
COMMENT ON COLUMN "oymcomercial"."chat_flow_nodes"."crm_action_config" IS 'Configuración de acción CRM por nodo';
COMMENT ON COLUMN "oymcomercial"."chat_flow_options"."option_payload" IS 'Payload opcional de variables a guardar en contexto cuando el cliente elige la opción';
COMMENT ON COLUMN "oymcomercial"."chat_flow_options"."group_title" IS 'Título del grupo (cuerpo del mensaje interactivo). Vacío = modo legacy sin agrupación.';
COMMENT ON COLUMN "oymcomercial"."chat_flow_options"."group_order" IS 'Orden del grupo respecto a otros del mismo nodo.';
COMMENT ON COLUMN "oymcomercial"."chat_flow_sessions"."referral_source" IS 'click_token: canje desde sorteo_revendedor_clicks; inbound_text: parser ref= en mensaje.';
COMMENT ON COLUMN "oymcomercial"."chat_flows"."sorteo_id" IS 'Si está definido, al recibir comprobante (imagen) en este flow se crea orden en sorteo_entradas + cupones (idempotente).';
COMMENT ON COLUMN "oymcomercial"."chat_flows"."sorteo_datos_incompletos_message" IS 'Texto al cliente cuando falta nombre/cantidad/opción para crear la orden de sorteo; vacío = default del servidor.';
COMMENT ON COLUMN "oymcomercial"."chat_flows"."flow_config" IS 'JSON por flujo: close_purchase_only_on_final_confirmation; restart_enabled, restart_node_code, restart_keywords, restart_strong_keywords, restart_when_completed, restart_when_abandoned, do_not_restart_when_human_taken_over.';
COMMENT ON COLUMN "oymcomercial"."chat_queues"."channel_type" IS 'Si no es NULL, esta cola aplica solo a chat_channels.type igual';
COMMENT ON COLUMN "oymcomercial"."chat_queues"."distribution_strategy" IS 'round_robin | least_load (default) | manual_pull (sin auto-asignación desde cola)';
COMMENT ON COLUMN "oymcomercial"."chat_usuario_omnicanal"."omnicanal_agent_enabled" IS 'Si es true, el usuario puede operar como agente (autoasignación, circuito operativo).';
COMMENT ON COLUMN "oymcomercial"."clientes"."sifen_receptor_manual" IS 'Si true, gDatRec del DE usa sifen_receptor_naturaleza, sifen_ti_ope y campos DE explícitos (sin inferencia legacy).';
COMMENT ON COLUMN "oymcomercial"."clientes"."nombre_facturacion" IS 'Nombre para facturar cuando difiere de la Razón Social (ej: pareja, hijo/a). NULL = usar empresa/nombre_contacto.';
COMMENT ON COLUMN "oymcomercial"."clientes"."nivel_precio" IS 'Nivel de precio comercial: minorista | mayorista | distribuidor. Se usa como default al agregar productos a presupuestos, pedidos y ventas.';
COMMENT ON COLUMN "oymcomercial"."clientes"."es_contribuyente" IS 'Persona física inscripta como contribuyente en la SET. Cuando es true y hay RUC cargado, la factura electrónica sale como B2B (iTiOpe=1) en vez de B2C (iTiOpe=2). No aplica a empresas.';
COMMENT ON COLUMN "oymcomercial"."compras"."fecha_factura" IS 'Fecha del comprobante fiscal del proveedor (la factura que nos emitieron). Distinta a `fecha`, que es la fecha de registro en el sistema. Nullable.';
COMMENT ON COLUMN "oymcomercial"."compras"."metodo_pago" IS 'Como se pago: efectivo / transferencia / tarjeta. Distinto al tipo_pago (contado/credito) que define plazo. NULL si no se registro (compras historicas).';
COMMENT ON COLUMN "oymcomercial"."crm_prospectos"."origen_creacion" IS 'Origen del lead: manual, whatsapp, formulario_web, referido, campaña_meta, automatizacion, otro';
COMMENT ON COLUMN "oymcomercial"."crm_prospectos"."origen_detalle" IS 'Detalle opcional del origen del lead (ej: campaña, referido, utm, etc.)';
COMMENT ON COLUMN "oymcomercial"."crm_prospectos"."observaciones" IS 'Notas internas comercial (contexto, objeciones, próximos pasos). Las crm_notas siguen siendo el historial por entrada.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."certificado_password_encrypted" IS 'Contraseña del .p12 cifrada en backend (neura:v1:...). Requiere SIFEN_SECRETS_KEY.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."direccion_fiscal" IS 'Domicilio/calle del emisor para XML SIFEN (gEmis.dDirEmi). Distinto de razon_social.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."timbrado_fecha_inicio_vigencia" IS 'Inicio de vigencia del timbrado según resolución DNIT (XML dFeIniT).';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."actividad_economica_codigo" IS 'Código de actividad económica principal según catálogo SET (cActEco).';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."actividad_economica_descripcion" IS 'Descripción oficial asociada al código (dDesActEco); debe coincidir con la SET.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."sifen_plazo_cancelacion_horas" IS 'Horas desde sifen_aprobado_at durante las cuales el DE puede anularse en ERP (sin pagos).';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."kude_logo_path" IS 'Ruta del logo PNG dentro del bucket privado "sifen". Solo afecta KuDE/PDF; no toca XML/firma/SET.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."kude_color_primario" IS 'Color primario KuDE (#RRGGBB) para bordes y acentos del PDF. NULL = default Neura (#0EA5E9).';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."kude_color_primario_fill" IS 'Color de fondo suave KuDE (#RRGGBB). NULL = derivado del primario por el renderer.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."emisor_telefono" IS 'Teléfono del emisor mostrado en el KUDE (encabezado) y usado en el XML como dTelEmi. Solo dígitos (8–15). Si es null se usa un fallback histórico por retrocompatibilidad.';
COMMENT ON COLUMN "oymcomercial"."empresa_sifen_config"."emisor_email" IS 'Email del emisor mostrado en el KUDE (encabezado) y usado en el XML como dEmailE. Si es null se usa un fallback histórico.';
COMMENT ON COLUMN "oymcomercial"."empresas"."gestion_tributaria_clientes" IS 'Si true, la empresa puede usar el bloque opcional de perfil tributario en clientes.';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."xml_firmado_path" IS 'Ruta en bucket sifen del XML con firma XML-DSig. xml_path conserva el borrador sin firma.';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_d_prot_cons_lote" IS 'Valor dProtConsLote devuelto por SET al aceptar el lote (código 0300).';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_ultima_respuesta_recibe_lote" IS 'Última respuesta parseada de recibe-lote (SOAP): códigos, cuerpo crudo, httpStatus.';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_ultima_respuesta_consulta_lote" IS 'Última respuesta parseada de consulta-lote TEST: dCodResLot, dMsgResLot, detalle por CDC (gResProcLote).';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_aprobado_at" IS 'Momento en que SET confirmó aprobación (consulta-lote); base del plazo de cancelación.';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_cancelado_at" IS 'Anulación lógica del DE en ERP (no borra fila ni documento físico).';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_cancelacion_motivo" IS 'Motivo declarado al cancelar en ERP.';
COMMENT ON COLUMN "oymcomercial"."factura_electronica"."sifen_regeneracion_seq" IS 'Incrementado al regenerar XML desde estado rechazado (nueva semilla dCodSeg / nuevo CDC antes de reenviar a SET).';
COMMENT ON COLUMN "oymcomercial"."gastos"."beneficiario" IS 'Nombre de la empresa o comercio al que se efectuo el pago (texto libre; no siempre corresponde a un proveedor registrado).';
COMMENT ON COLUMN "oymcomercial"."gastos"."metodo_pago" IS 'Metodo de pago: efectivo | transferencia | tarjeta. NULL si no se registro (gastos historicos).';
COMMENT ON COLUMN "oymcomercial"."nota_credito"."numero" IS 'Número correlativo de la NC por empresa. Es el dNumDoc del CDC SIFEN. NULL = nota de legado, emitida cuando el número se derivaba de un hash del UUID.';
COMMENT ON COLUMN "oymcomercial"."presupuestos"."fecha_entrega" IS 'Fecha de entrega comprometida. Se muestra en el PDF/impresión del presupuesto.';
COMMENT ON COLUMN "oymcomercial"."productos"."controla_stock" IS 'Si false, el producto no descuenta stock (ajustes, servicios, tarifas).';
COMMENT ON COLUMN "oymcomercial"."productos"."valorizado" IS 'Si false, no entra en valuación de inventario (combos, promociones).';
COMMENT ON COLUMN "oymcomercial"."productos"."unidad_compra" IS 'Unidad usada al comprar (ej. "Bolsa 25kg").';
COMMENT ON COLUMN "oymcomercial"."productos"."unidad_receta" IS 'Unidad usada en recetas (ej. "g", "ml").';
COMMENT ON COLUMN "oymcomercial"."productos"."factor_compra_receta" IS 'Factor para convertir 1 unidad de compra a unidades de receta (ej. 25000 g por bolsa).';
COMMENT ON COLUMN "oymcomercial"."productos"."tiempo_prep_minutos" IS 'Tiempo estimado de preparación en minutos (para Kanban de cocina).';
COMMENT ON COLUMN "oymcomercial"."productos"."descripcion" IS 'Descripción detallada del producto (visible en Menú y edición).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."numero_orden" IS 'Secuencia de compras/inscripciones por sorteo (distinta de numero_cupon).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."idempotency_key" IS 'Clave estable (conv + flow + media_id) para evitar duplicar orden/cupones en reintentos.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."promo_nombre" IS 'Nombre legible de la promo elegida en el flujo (option_payload), si aplica.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."precio_fuente" IS 'lista: monto_total = precio_por_boleto * cantidad; promo: monto explícito del flujo.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."precio_regular_referencia" IS 'Referencia opcional (ej. precio de lista) cuando precio_fuente = promo.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."comprobante_validacion_id" IS 'Vínculo opcional a la fila de validación OCR/hash del comprobante (WhatsApp).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."codigo_referido_snapshot" IS 'Copia del código al confirmar orden (histórico / comisiones).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."observacion_interna" IS 'Nota interna ERP (no visible al comprador).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."venta_origen" IS 'whatsapp_flow: flujo WhatsApp; erp_manual: carga manual en panel.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."venta_canal" IS 'remote: compra remota; local: mostrador/presencial.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."pago_metodo" IS 'Medio de pago declarado en venta manual o registro interno.';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."cupones_impresos_at" IS 'Momento en que se confirmó la impresión física de cupones para urna (una vez por orden).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."cupones_impresos_by" IS 'Usuario ERP que confirmó la impresión (usuarios.id si disponible; sin FK obligatoria).';
COMMENT ON COLUMN "oymcomercial"."sorteo_entradas"."cupones_impresion_count" IS 'Cantidad de cupones (filas sorteo_cupones) considerados en la última confirmación de impresión.';
COMMENT ON COLUMN "oymcomercial"."sorteos"."ticket_delivery_mode" IS 'text_only | text_and_image | image_only — respuesta al comprador tras confirmar orden.';
COMMENT ON COLUMN "oymcomercial"."sorteos"."ticket_image_config" IS 'Diseño/caption/visibilidad del ticket PNG (JSON).';
COMMENT ON COLUMN "oymcomercial"."suscripciones"."plan_pendiente_id" IS 'Plan a aplicar (vigente desde plan_pendiente_vigente_desde).';
COMMENT ON COLUMN "oymcomercial"."suscripciones"."precio_pendiente" IS 'Precio a aplicar con el plan pendiente.';
COMMENT ON COLUMN "oymcomercial"."suscripciones"."moneda_pendiente" IS 'Moneda del precio pendiente (GS o USD en aplicación).';
COMMENT ON COLUMN "oymcomercial"."suscripciones"."plan_pendiente_vigente_desde" IS 'Fecha a partir de la cual aplica el cambio (p. ej. 1° del mes siguiente).';
COMMENT ON COLUMN "oymcomercial"."usuarios"."auth_user_id" IS 'UUID de auth.users para actualizar email/estado sin buscar por email';
COMMENT ON COLUMN "oymcomercial"."usuarios"."porcentaje_comision" IS 'Porcentaje de comisión (0–100)';
COMMENT ON COLUMN "oymcomercial"."usuarios"."fecha_ingreso" IS 'Fecha de ingreso laboral';
COMMENT ON COLUMN "oymcomercial"."usuarios"."tipo_contrato" IS 'Tipo de contrato declarado en RR.HH.';
COMMENT ON COLUMN "oymcomercial"."usuarios"."salario_base" IS 'Salario base en guaraníes';
COMMENT ON COLUMN "oymcomercial"."usuarios"."ips" IS 'Si cotiza IPS';
COMMENT ON COLUMN "oymcomercial"."usuarios"."area" IS 'Área funcional del usuario';

COMMIT;
