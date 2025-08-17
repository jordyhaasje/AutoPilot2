# AutoPilot - AI-Powered Customer Service for Dropshippers

AutoPilot is a multi-tenant SaaS customer service system built on n8n (community edition) and Supabase (PostgreSQL with pgvector). It provides fully rule-driven AI customer service without hardcoded texts or logic in flows or prompts.

## 🚀 Features

- **Multi-tenant architecture** with complete tenant isolation
- **AI-powered email classification** and response generation
- **Rule-driven policies** stored in database (compensation, returns, delivery windows)
- **Multi-language support** with automatic language detection
- **Vector similarity search** for KB/FAQ integration
- **Comprehensive audit logging** and notifications
- **Email filtering** with whitelist/blacklist support
- **Conversation state management** with customer name locking
- **Threat detection** and chargeback risk mitigation

## 🏗️ Architecture

### Core Components

1. **Database Layer** (Supabase + PostgreSQL)
   - Multi-tenant schema with RLS policies
   - Vector embeddings for similarity search
   - Audit logs and notifications

2. **Workflow Engine** (n8n Community Edition)
   - Gmail integration for email processing
   - OpenAI integration for AI classification and writing
   - PostgreSQL integration for data persistence

3. **AI Layer** (OpenAI)
   - GPT-4o-mini for classification and writing
   - text-embedding-3-small for vector embeddings

### Database Schema

The system uses a comprehensive schema with the following key tables:

- `tenants` - Multi-tenant configuration
- `customers` - Customer information per tenant
- `conversations` - Email conversation threads
- `messages` - Individual email messages
- `conversation_state` - Conversation context and state
- `tenant_*` - Tenant-specific policies and rules
- `embeddings_*` - Vector embeddings for similarity search
- `notifications` - System notifications
- `audit_logs` - Complete audit trail

## 📋 Prerequisites

- n8n Community Edition v1.104.1+
- Supabase account with PostgreSQL + pgvector
- OpenAI API key
- Gmail account for email processing

## 🛠️ Installation & Setup

### 1. Database Setup

1. **Create Supabase project** and enable pgvector extension
2. **Run schema.sql** to create all tables and indexes:
   ```sql
   -- Execute schema.sql in your Supabase SQL editor
   ```

3. **Run seed.sql** to create demo tenant and test data:
   ```sql
   -- Execute seed.sql in your Supabase SQL editor
   ```

### 2. n8n Setup

1. **Install n8n** (Community Edition)
2. **Configure credentials**:
   - **OpenAI**: Add your OpenAI API key
   - **Gmail**: Configure OAuth2 for Gmail access
   - **PostgreSQL**: Add Supabase connection details

3. **Import workflows**:
   - Import `inbound_orchestrator.json`
   - Import `monitor_inactivity.json`

### 3. Configuration

1. **Update TENANT_ID** in both workflows:
   - Demo tenant ID: `00000000-0000-0000-0000-00000000d001`
   - Change to your actual tenant ID

2. **Configure Gmail credentials** in both workflows

3. **Set up database connections** with your Supabase credentials

## 🔧 Configuration

### Tenant Configuration

Each tenant can configure:

- **Delivery Windows**: Time-based delivery expectations
- **Compensation Steps**: Escalating compensation percentages
- **Return Steps**: Multi-step return process
- **Email Filters**: Whitelist/blacklist rules
- **Time Windows**: Cancellation and address change limits
- **KB/FAQ**: Knowledge base articles with embeddings

### AI Configuration

- **Classifier Model**: GPT-4o-mini (configurable)
- **Writer Model**: GPT-4o-mini (configurable)
- **Embedding Model**: text-embedding-3-small
- **Temperature**: 0.1 for classification, 0.4 for writing

## 📊 Workflows

### 1. Inbound Orchestrator

**Trigger**: Gmail new email
**Purpose**: Process incoming customer emails

**Flow**:
1. **Email Filtering** - Apply tenant-specific filters
2. **Customer/Conversation Management** - Upsert customer and conversation data
3. **AI Classification** - Classify intent, sentiment, extract data
4. **Policy Engine** - Apply tenant rules and policies
5. **AI Response Generation** - Generate human-like response
6. **Email Sending** - Send reply via Gmail
7. **Audit & Notifications** - Log actions and create notifications

### 2. Monitor Inactivity

**Trigger**: Daily cron (09:00)
**Purpose**: Check for inactive conversations

**Flow**:
1. **Find Inactive Conversations** - Query conversations without recent activity
2. **Create Notifications** - Generate inactivity reminders

## 🎯 Use Cases

### 1. Delivery Questions
- AI calculates waiting time based on order date
- Compares with tenant delivery windows
- Provides appropriate response with delivery expectations

### 2. Returns & Compensation
- Multi-step return process with compensation ladder
- Threat detection with escalated compensation
- Automatic return address provision

### 3. Order Cancellations
- Time-window validation
- Automatic approval/rejection based on tenant rules

### 4. General Inquiries
- KB/FAQ integration via vector similarity
- Prospect vs. existing customer differentiation

## 🔒 Security

- **Row Level Security (RLS)** on all tables
- **Tenant isolation** via database policies
- **Audit logging** for all actions
- **No hardcoded secrets** in workflows

## 📈 Monitoring

### Notifications
The system generates notifications for:
- `compensation_offered` - When compensation is offered
- `last_offer_made` - When final offer is made
- `return_address_sent` - When return address is provided
- `threat_detected` - When threats are detected
- `chargeback_risk_detected` - When chargeback risk is identified
- `delivery_window_max_reached` - When delivery window is exceeded
- `email_filtered` - When emails are filtered
- `human_review_required` - When AI confidence is low
- `inactivity_reminder` - For inactive conversations

### Audit Logs
Complete audit trail including:
- Intent classification results
- Applied compensation steps
- Return address sent
- Cancellation decisions
- All AI decisions and actions

## 🚀 Deployment

### Production Considerations

1. **Database**: Use Supabase production instance
2. **n8n**: Deploy on Railway, Heroku, or self-hosted
3. **Scaling**: Configure n8n for high availability
4. **Monitoring**: Set up alerts for workflow failures
5. **Backup**: Regular database backups via Supabase

### Environment Variables

```bash
# Required
OPENAI_API_KEY=your_openai_key
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key

# Optional
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password
```

## 🔧 Customization

### Adding New Tenants

1. **Create tenant record** in `autopilot.tenants`
2. **Configure policies** in tenant-specific tables
3. **Add KB articles** with embeddings
4. **Set up email filters**

### Extending Functionality

- **New intents**: Update classifier prompt and policy engine
- **New policies**: Add new tenant configuration tables
- **New notifications**: Extend notification system
- **Custom integrations**: Add new n8n nodes

## 📝 API Reference

### Database Queries

All database operations use parameterized queries with tenant isolation:

```sql
-- Example: Fetch tenant policies
SELECT * FROM autopilot.tenant_compensation_steps 
WHERE tenant_id = $1 ORDER BY step_index;
```

### Workflow Variables

Key variables used in workflows:
- `TENANT_ID` - Current tenant identifier
- `DEFAULT_LANG` - Default language for tenant
- `filter_allow` - Email filter result
- `confidence` - AI classification confidence

## 🐛 Troubleshooting

### Common Issues

1. **Gmail Authentication**
   - Ensure OAuth2 is properly configured
   - Check Gmail API permissions

2. **Database Connection**
   - Verify Supabase credentials
   - Check RLS policies

3. **AI Classification Failures**
   - Check OpenAI API key and quota
   - Verify classifier prompt format

4. **Workflow Errors**
   - Check n8n execution logs
   - Verify node configurations

### Debug Mode

Enable debug logging in n8n:
```bash
N8N_LOG_LEVEL=debug
```

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For support and questions:
- Create an issue in this repository
- Check the n8n documentation
- Review Supabase documentation

---

**AutoPilot** - Making customer service effortless for dropshippers 🚀
