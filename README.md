# AutoPilot - Multi-Tenant SaaS Customer Service System

AutoPilot is een volledig geautomatiseerd klantenservice systeem voor dropshippers, gebouwd op n8n (Community Edition) en Supabase. Het systeem verwerkt inkomende e-mails automatisch met AI, past tenant-specifieke regels toe, en genereert menselijke antwoorden.

## 🚀 Features

- **Multi-tenant architectuur** met volledige data isolatie
- **AI-powered email processing** met intent detection en sentiment analysis
- **Database-driven business rules** - alles configureerbaar via database
- **Compensation & return workflows** met retention-first approach
- **Delivery window management** met automatische notificaties
- **Threat detection** en escalatie management
- **Knowledge Base** met vector embeddings voor relevante antwoorden
- **Email filtering** (whitelist/blacklist/custom rules)
- **Conversation state management** met naam detectie
- **Audit logging** en notificaties voor alle acties

## 🏗️ Architecture

- **Frontend**: n8n Community Edition (v1.104.1)
- **Backend**: Supabase (PostgreSQL + pgvector)
- **AI Models**: OpenAI GPT-4o-mini (classifier & writer), text-embedding-3-small (embeddings)
- **Email**: Gmail integration via n8n nodes
- **Hosting**: Railway (n8n), Supabase Cloud

## 📋 Prerequisites

- n8n Community Edition v1.104.1
- Supabase account met PostgreSQL database
- OpenAI API key
- Gmail account voor email processing
- Railway account (voor n8n hosting)

## 🛠️ Installation

### 1. Database Setup

Voer de volgende SQL bestanden uit in je Supabase SQL Editor:

```sql
-- 1. Schema setup
-- Kopieer en voer schema.sql uit

-- 2. Demo data
-- Kopieer en voer seed.sql uit
```

### 2. n8n Configuration

#### Credentials Setup

1. **PostgreSQL Credential**:
   - Host: `db.xhkaqcqmuswjfhkjufag.supabase.co`
   - Database: `postgres`
   - User: `postgres`
   - Password: `sb_secret_7h7OCVe2efxkX85rjU1mg_wAqJZnWz`
   - Port: `5432`

2. **OpenAI Credential**:
   - API Key: Je OpenAI API key

3. **Gmail Credential**:
   - OAuth2 setup voor Gmail access

#### Workflow Import

1. Importeer de `inbound_orchestrator.json` workflow
2. Configureer de credentials in elke node
3. Update de `TENANT_ID` in de "Config (Tenant)" node naar jouw tenant ID

### 3. Environment Variables

Zorg ervoor dat de volgende environment variables zijn ingesteld in je n8n instance:

```bash
# Database
DB_POSTGRESDB_DATABASE="postgres"
DB_POSTGRESDB_HOST="db.xhkaqcqmuswjfhkjufag.supabase.co"
DB_POSTGRESDB_PASSWORD="sb_secret_7h7OCVe2efxkX85rjU1mg_wAqJZnWz"
DB_POSTGRESDB_PORT="5432"
DB_POSTGRESDB_USER="postgres"
DB_TYPE="postgresdb"

# n8n
N8N_ENCRYPTION_KEY="7~i62e0Ks5tJs*wuOFA7yDRC_Wcf1TYI"
N8N_EDITOR_BASE_URL="https://your-railway-domain.up.railway.app"
```

## 🔧 Configuration

### Tenant Setup

1. **Basis tenant gegevens**:
   ```sql
   INSERT INTO autopilot.tenants (id, name, from_email, default_language, timezone, settings) 
   VALUES ('your-tenant-id', 'Your Shop', 'support@yourshop.com', 'nl', 'Europe/Amsterdam', 
   '{"return_address": "Your return address here"}');
   ```

2. **Business rules configureren**:
   - Compensation steps (15% → 20% → 30% → 40%)
   - Delivery windows (2-7, 5-10, 11-14 days)
   - Return workflow steps
   - Email filters
   - Knowledge Base chunks

### Workflow Customization

De workflow gebruikt de volgende nodes in volgorde:

1. **Gmail Trigger** - Detecteert nieuwe emails
2. **Config (Tenant)** - Stelt tenant ID en default taal in
3. **Preprocess** - Verwerkt email data
4. **Fetch Filters** - Haalt email filters op
5. **Apply Filters** - Past filters toe
6. **Filtered?** - Checkt of email gefilterd moet worden
7. **Upsert Customer** - Maakt/update klant record
8. **Upsert Conversation** - Maakt/update conversatie
9. **Insert Message** - Slaat inbound message op
10. **Classifier (JSON)** - AI intent detection
11. **Parse/Validate JSON** - Valideert AI output
12. **Writer (final)** - Genereert antwoord
13. **Gmail Send Reply** - Stuurt antwoord

## 📊 Database Schema

### Core Tables

- `tenants` - Tenant informatie
- `customers` - Klant gegevens
- `orders` - Bestellingen
- `conversations` - Email conversaties
- `messages` - Individuele berichten
- `conversation_state` - Conversatie context

### Policy Tables

- `tenant_rules` - Algemene regels
- `tenant_compensation_steps` - Compensatie ladder
- `tenant_delivery_windows` - Levering vensters
- `tenant_return_steps` - Retour workflow
- `tenant_email_filters` - Email filters

### AI Tables

- `kb_chunks` - Knowledge Base content
- `embeddings_kb` - Vector embeddings voor KB
- `embeddings_messages` - Vector embeddings voor messages

### Audit Tables

- `notifications` - Systeem notificaties
- `audit_logs` - Audit trail

## 🔒 Security

- **Row Level Security (RLS)** op alle tenant-specifieke tabellen
- **Tenant isolation** via `current_setting('app.tenant_id')`
- **API key authentication** voor externe toegang
- **Audit logging** voor alle acties

## 📈 Monitoring

### Notifications

Het systeem genereert automatisch notificaties voor:

- `compensation_offered` - Compensatie aangeboden
- `threat_detected` - Dreiging gedetecteerd
- `chargeback_risk_detected` - Chargeback risico
- `delivery_window_max_reached` - Maximale levertijd bereikt
- `human_review_required` - AI confidence te laag
- `email_filtered` - Email gefilterd

### Audit Logs

Alle acties worden gelogd met:
- Actor type (system, ai, human)
- Action performed
- Target type en ID
- Metadata

## 🚨 Troubleshooting

### Common Issues

1. **Database connection failed**:
   - Controleer Supabase credentials
   - Zorg dat schema.sql is uitgevoerd

2. **AI nodes failing**:
   - Controleer OpenAI API key
   - Zorg dat je API credits hebt

3. **Gmail not working**:
   - Controleer OAuth2 setup
   - Zorg dat Gmail API is ingeschakeld

4. **Workflow not triggering**:
   - Controleer of workflow actief is
   - Controleer Gmail trigger settings

### Debug Mode

Voor debugging, voeg een "NoOp" node toe na elke belangrijke stap om de data flow te controleren.

## 📝 Customization

### Adding New Intent Types

1. Update de Classifier system prompt
2. Voeg nieuwe intent handling toe in Policy Engine
3. Update Writer prompt voor nieuwe scenarios

### Custom Business Rules

Alle business rules zijn opgeslagen in de database en kunnen aangepast worden via SQL of een toekomstig dashboard.

### Multi-language Support

Het systeem ondersteunt meerdere talen. Configureer per tenant:
- `default_language` in tenants table
- `language_default` in tenant_rules
- Taal-specifieke templates in policy tables

## 🤝 Contributing

1. Fork de repository
2. Maak een feature branch
3. Commit je changes
4. Push naar de branch
5. Open een Pull Request

## 📄 License

Dit project is gelicenseerd onder de MIT License.

## 🆘 Support

Voor vragen of problemen:
1. Check de troubleshooting sectie
2. Controleer de audit logs
3. Open een issue in de repository

---

**AutoPilot** - Automatiseer je klantenservice met AI-powered intelligentie.
