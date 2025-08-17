-- AutoPilot2 Seed Data
-- Demo tenant and configuration

-- Demo tenant
INSERT INTO autopilot.tenants (id, name, from_email, default_language, timezone, settings) VALUES
('00000000-0000-0000-0000-00000000d001', 'Demo Shop', 'support@demoshop.nl', 'nl', 'Europe/Amsterdam', '{"return_address": "Retouradres Demo Shop\nVoorbeeldstraat 123\n1234 AB Amsterdam\nNederland"}');

-- Demo customer
INSERT INTO autopilot.customers (tenant_id, email, name, locale) VALUES
('00000000-0000-0000-0000-00000000d001', 'klant@example.com', 'Jan Jansen', 'nl');

-- Demo order
INSERT INTO autopilot.orders (tenant_id, customer_id, order_reference, order_date, status, total_amount) VALUES
('00000000-0000-0000-0000-00000000d001', (SELECT id FROM autopilot.customers WHERE email = 'klant@example.com'), 'DD-12345', CURRENT_DATE - INTERVAL '7 days', 'shipped', 99.99);

-- Demo conversation
INSERT INTO autopilot.conversations (tenant_id, customer_id, subject, external_thread_id, status) VALUES
('00000000-0000-0000-0000-00000000d001', (SELECT id FROM autopilot.customers WHERE email = 'klant@example.com'), 'Vraag over bestelling', 'thread_123', 'open');

-- Demo conversation state
INSERT INTO autopilot.conversation_state (tenant_id, conversation_id, locked_name, last_compensation_percent, last_return_step, last_sentiment, summary) VALUES
('00000000-0000-0000-0000-00000000d001', (SELECT id FROM autopilot.conversations WHERE external_thread_id = 'thread_123'), 'Jan', 0, 0, 'neutral', 'Eerste contact over bestelling');

-- Tenant rules
INSERT INTO autopilot.tenant_rules (tenant_id, tone, language_default, writer_style, chargeback_policy, chargeback_extra_percent, public_delivery_avg_min, public_delivery_avg_max) VALUES
('00000000-0000-0000-0000-00000000d001', 'friendly', 'nl', '{"signature": "Met vriendelijke groet,\nTeam Demo Shop"}', 'extra_compensation', 25, 6, 9);

-- Negotiation policy
INSERT INTO autopilot.tenant_negotiation_policy (tenant_id, allow, max_extra_percent) VALUES
('00000000-0000-0000-0000-00000000d001', true, 15);

-- Time windows
INSERT INTO autopilot.tenant_time_windows (tenant_id, kind, max_days) VALUES
('00000000-0000-0000-0000-00000000d001', 'cancel', 2),
('00000000-0000-0000-0000-00000000d001', 'address_change', 3);

-- Delivery windows
INSERT INTO autopilot.tenant_delivery_windows (tenant_id, window_index, min_days, max_days, template, notify_on_max) VALUES
('00000000-0000-0000-0000-00000000d001', 1, 2, 7, 'Je bestelling is onderweg. Meestal {{min_days}}–{{max_days}} werkdagen.', false),
('00000000-0000-0000-0000-00000000d001', 2, 5, 10, 'We verwachten levering binnen {{min_days}}–{{max_days}} werkdagen.', false),
('00000000-0000-0000-0000-00000000d001', 3, 11, 14, 'Laatste venster ({{min_days}}–{{max_days}}). We houden je op de hoogte.', true);

-- Compensation steps
INSERT INTO autopilot.tenant_compensation_steps (tenant_id, step_index, percent, template) VALUES
('00000000-0000-0000-0000-00000000d001', 1, 15, 'We bieden je 15% compensatie voor het ongemak.'),
('00000000-0000-0000-0000-00000000d001', 2, 20, 'We verhogen de compensatie naar 20%.'),
('00000000-0000-0000-0000-00000000d001', 3, 30, 'We bieden je 30% compensatie.'),
('00000000-0000-0000-0000-00000000d001', 4, 40, 'We bieden je 40% compensatie.');

-- Threat compensation steps
INSERT INTO autopilot.tenant_threat_compensation_steps (tenant_id, step_index, percent, template) VALUES
('00000000-0000-0000-0000-00000000d001', 1, 50, 'We bieden je 50% compensatie.'),
('00000000-0000-0000-0000-00000000d001', 2, 60, 'We bieden je 60% compensatie.');

-- Return steps
INSERT INTO autopilot.tenant_return_steps (tenant_id, step_index, action, template, last_offer_framing) VALUES
('00000000-0000-0000-0000-00000000d001', 1, 'offer_compensation', 'We bieden je compensatie aan.', false),
('00000000-0000-0000-0000-00000000d001', 2, 'request_photos', 'Kun je foto\'s sturen van het probleem?', false),
('00000000-0000-0000-0000-00000000d001', 3, 'request_more_info', 'We hebben meer informatie nodig.', false),
('00000000-0000-0000-0000-00000000d001', 4, 'last_offer', 'We kunnen je nog een laatste aanbieding doen, laat ons weten of je hiermee akkoord gaat, anders sturen we je het retouradres. Let wel op, de kosten hiervoor zijn voor jezelf, vandaar dat we je tegemoet wilden komen met een compensatie.', true),
('00000000-0000-0000-0000-00000000d001', 5, 'give_return_address', 'Hier is ons retouradres: Retouradres Demo Shop, Voorbeeldstraat 123, 1234 AB Amsterdam, Nederland', false);

-- Email filters
INSERT INTO autopilot.tenant_email_filters (tenant_id, kind, field, pattern, is_regex, action, active) VALUES
('00000000-0000-0000-0000-00000000d001', 'blacklist', 'subject', 'newsletter', false, 'deny', true),
('00000000-0000-0000-0000-00000000d001', 'blacklist', 'domain', 'no-reply.', false, 'deny', true);

-- KB chunks
INSERT INTO autopilot.kb_chunks (tenant_id, title, content, category, lang) VALUES
('00000000-0000-0000-0000-00000000d001', 'Verzendtijden', 'Onze standaard verzendtijd is 6-9 werkdagen. Voor spoedbestellingen neem contact op.', 'shipping', 'nl'),
('00000000-0000-0000-0000-00000000d001', 'Retourbeleid', 'Je kunt binnen 14 dagen retourneren. De retourkosten zijn voor eigen rekening.', 'returns', 'nl');
