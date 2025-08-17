-- AutoPilot Database Schema
-- Multi-tenant SaaS klantenservice systeem voor dropshippers

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Create schema
CREATE SCHEMA IF NOT EXISTS autopilot;

-- Tenants table
CREATE TABLE autopilot.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    from_email TEXT NOT NULL,
    default_language TEXT NOT NULL DEFAULT 'nl',
    timezone TEXT NOT NULL DEFAULT 'Europe/Amsterdam',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers table
CREATE TABLE autopilot.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    locale TEXT DEFAULT 'nl',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

-- Orders table
CREATE TABLE autopilot.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES autopilot.customers(id) ON DELETE CASCADE,
    order_reference TEXT NOT NULL,
    order_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    total_amount NUMERIC(10,2),
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations table
CREATE TABLE autopilot.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES autopilot.customers(id) ON DELETE CASCADE,
    subject TEXT,
    external_thread_id TEXT,
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE autopilot.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES autopilot.conversations(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES autopilot.customers(id) ON DELETE CASCADE,
    direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    subject TEXT,
    body_text TEXT,
    body_html TEXT,
    raw JSONB DEFAULT '{}',
    sender_email TEXT NOT NULL,
    message_id TEXT,
    in_reply_to TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversation state table
CREATE TABLE autopilot.conversation_state (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES autopilot.conversations(id) ON DELETE CASCADE,
    locked_name TEXT,
    last_compensation_percent INTEGER,
    last_return_step INTEGER DEFAULT 0,
    last_intents JSONB DEFAULT '[]',
    last_sentiment TEXT,
    summary TEXT,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    inactivity_days INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, conversation_id)
);

-- KB chunks table
CREATE TABLE autopilot.kb_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT,
    source TEXT,
    url TEXT,
    lang TEXT DEFAULT 'nl',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KB embeddings table
CREATE TABLE autopilot.embeddings_kb (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    kb_chunk_id UUID NOT NULL REFERENCES autopilot.kb_chunks(id) ON DELETE CASCADE,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message embeddings table
CREATE TABLE autopilot.embeddings_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES autopilot.messages(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Delivery windows table
CREATE TABLE autopilot.tenant_delivery_windows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    window_index INTEGER NOT NULL,
    min_days INTEGER NOT NULL,
    max_days INTEGER NOT NULL,
    template TEXT NOT NULL,
    notify_on_max BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, window_index)
);

-- Compensation steps table
CREATE TABLE autopilot.tenant_compensation_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    step_index INTEGER NOT NULL,
    percent INTEGER NOT NULL,
    template TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, step_index)
);

-- Threat compensation steps table
CREATE TABLE autopilot.tenant_threat_compensation_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    step_index INTEGER NOT NULL,
    percent INTEGER NOT NULL,
    template TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, step_index)
);

-- Return steps table
CREATE TABLE autopilot.tenant_return_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    step_index INTEGER NOT NULL,
    action TEXT NOT NULL,
    template TEXT NOT NULL,
    last_offer_framing BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, step_index)
);

-- Time windows table
CREATE TABLE autopilot.tenant_time_windows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('cancel', 'address_change')),
    max_days INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, kind)
);

-- Negotiation policy table
CREATE TABLE autopilot.tenant_negotiation_policy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    allow BOOLEAN DEFAULT TRUE,
    max_extra_percent INTEGER DEFAULT 15,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id)
);

-- Rules table
CREATE TABLE autopilot.tenant_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    tone TEXT DEFAULT 'friendly',
    language_default TEXT DEFAULT 'nl',
    writer_style JSONB DEFAULT '{"signature": "Met vriendelijke groet,\nTeam"}',
    chargeback_policy TEXT DEFAULT 'return_address' CHECK (chargeback_policy IN ('return_address', 'extra_compensation')),
    chargeback_extra_percent INTEGER DEFAULT 25,
    public_delivery_avg_min INTEGER DEFAULT 6,
    public_delivery_avg_max INTEGER DEFAULT 9,
    return_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id)
);

-- Email filters table
CREATE TABLE autopilot.tenant_email_filters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('whitelist', 'blacklist', 'custom')),
    field TEXT NOT NULL CHECK (field IN ('from', 'subject', 'body', 'domain')),
    pattern TEXT NOT NULL,
    is_regex BOOLEAN DEFAULT FALSE,
    action TEXT NOT NULL CHECK (action IN ('allow', 'deny')),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications table
CREATE TABLE autopilot.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES autopilot.conversations(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    payload JSONB DEFAULT '{}',
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit logs table
CREATE TABLE autopilot.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES autopilot.tenants(id) ON DELETE CASCADE,
    actor_type TEXT NOT NULL CHECK (actor_type IN ('ai', 'human', 'system')),
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id UUID,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_messages_tenant_conversation ON autopilot.messages(tenant_id, conversation_id, direction);
CREATE INDEX idx_messages_tenant_sent_at ON autopilot.messages(tenant_id, sent_at DESC);
CREATE INDEX idx_notifications_tenant_created_at ON autopilot.notifications(tenant_id, created_at DESC);
CREATE INDEX idx_audit_logs_tenant_created_at ON autopilot.audit_logs(tenant_id, created_at DESC);
CREATE INDEX idx_customers_tenant_email ON autopilot.customers(tenant_id, email);
CREATE INDEX idx_orders_tenant_customer ON autopilot.orders(tenant_id, customer_id);
CREATE INDEX idx_conversations_tenant_customer ON autopilot.conversations(tenant_id, customer_id);
CREATE INDEX idx_conversations_external_thread ON autopilot.conversations(tenant_id, external_thread_id);

-- Vector indexes for similarity search
CREATE INDEX idx_embeddings_kb_vector ON autopilot.embeddings_kb USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_embeddings_messages_vector ON autopilot.embeddings_messages USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Enable Row Level Security (RLS)
ALTER TABLE autopilot.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.conversation_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.kb_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.embeddings_kb ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.embeddings_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_delivery_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_compensation_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_threat_compensation_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_return_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_time_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_negotiation_policy ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.tenant_email_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE autopilot.audit_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (tenant isolation)
-- Note: In production, you would use JWT claims or similar for tenant_id
-- For now, we'll create policies that work with explicit tenant_id filtering

-- Tenants policy (read-only for now)
CREATE POLICY tenants_select_policy ON autopilot.tenants FOR SELECT USING (true);

-- Customers policy
CREATE POLICY customers_tenant_policy ON autopilot.customers FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Orders policy
CREATE POLICY orders_tenant_policy ON autopilot.orders FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Conversations policy
CREATE POLICY conversations_tenant_policy ON autopilot.conversations FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Messages policy
CREATE POLICY messages_tenant_policy ON autopilot.messages FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Conversation state policy
CREATE POLICY conversation_state_tenant_policy ON autopilot.conversation_state FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- KB chunks policy
CREATE POLICY kb_chunks_tenant_policy ON autopilot.kb_chunks FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- KB embeddings policy
CREATE POLICY embeddings_kb_tenant_policy ON autopilot.embeddings_kb FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Message embeddings policy
CREATE POLICY embeddings_messages_tenant_policy ON autopilot.embeddings_messages FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Delivery windows policy
CREATE POLICY delivery_windows_tenant_policy ON autopilot.tenant_delivery_windows FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Compensation steps policy
CREATE POLICY compensation_steps_tenant_policy ON autopilot.tenant_compensation_steps FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Threat compensation steps policy
CREATE POLICY threat_compensation_steps_tenant_policy ON autopilot.tenant_threat_compensation_steps FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Return steps policy
CREATE POLICY return_steps_tenant_policy ON autopilot.tenant_return_steps FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Time windows policy
CREATE POLICY time_windows_tenant_policy ON autopilot.tenant_time_windows FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Negotiation policy
CREATE POLICY negotiation_policy_tenant_policy ON autopilot.tenant_negotiation_policy FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Rules policy
CREATE POLICY rules_tenant_policy ON autopilot.tenant_rules FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Email filters policy
CREATE POLICY email_filters_tenant_policy ON autopilot.tenant_email_filters FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Notifications policy
CREATE POLICY notifications_tenant_policy ON autopilot.notifications FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Audit logs policy
CREATE POLICY audit_logs_tenant_policy ON autopilot.audit_logs FOR ALL USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION autopilot.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON autopilot.tenants FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON autopilot.customers FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON autopilot.orders FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON autopilot.conversations FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
CREATE TRIGGER update_conversation_state_updated_at BEFORE UPDATE ON autopilot.conversation_state FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
CREATE TRIGGER update_negotiation_policy_updated_at BEFORE UPDATE ON autopilot.tenant_negotiation_policy FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
CREATE TRIGGER update_rules_updated_at BEFORE UPDATE ON autopilot.tenant_rules FOR EACH ROW EXECUTE FUNCTION autopilot.update_updated_at_column();
