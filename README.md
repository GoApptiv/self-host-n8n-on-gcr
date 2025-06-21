# Self-Hosting n8n on Google Cloud Run (Modified for GoApptiv)

> **Note:** This guide is a **modified version** of the original [n8n Cloud Run setup](https://github.com/n8n-io) tailored for **GoApptiv's infrastructure and security policies**.
>
> Key Modifications:
>
> - Uses **GoApptiv's internal PostgreSQL database** (instead of creating a new Cloud SQL instance).
> - Reuses an **existing encryption key stored in Secret Manager** (no new key generation).
> - Adjusts the **public URL and deployment configuration** to match GoApptiv’s internal and external access conventions.

---

## Overview

This guide will help you deploy `n8n` on **Google Cloud Run** using an existing **PostgreSQL database** and **Google Secret Manager** secrets.

With this setup:

- No new database or credentials are provisioned.
- Your internal secrets are reused securely.
- Custom domain and path are supported as per GoApptiv’s standards.

---

## Key Differences from Original Setup

| Area                    | Original Guide                   | GoApptiv Modified Version                     |
| ----------------------- | -------------------------------- | --------------------------------------------- |
| Database                | Creates new Cloud SQL PostgreSQL | Uses existing internal PostgreSQL             |
| Encryption Key          | Creates new Secret               | Uses existing secret stored in Secret Manager |
| URL Configuration       | Default Cloud Run URL            | Uses internal or branded URL                  |
| Environment Integration | General-purpose                  | Aligned with GoApptiv's deployment pipelines  |

---

## Step-by-Step Changes Summary

### 1. **No New Cloud SQL Instance**

> Skip the `gcloud sql instances create` and related steps.

Instead, ensure that the following env vars match your **existing internal DB** configuration:

```bash
--set-env-vars="
  DB_TYPE=postgresdb,
  DB_POSTGRESDB_HOST=<INTERNAL_DB_HOST>,
  DB_POSTGRESDB_PORT=5432,
  DB_POSTGRESDB_DATABASE=<EXISTING_DB_NAME>,
  DB_POSTGRESDB_USER=<EXISTING_USER>,
  N8N_PATH=/,
  N8N_PORT=443,
  N8N_PROTOCOL=https
"
```

**Note**: The actual DB password will be injected via Secret Manager (see next section).

---

### 2. **Use Existing Secrets**

Instead of creating new secrets like this:

```bash
echo -n "your-value" | gcloud secrets create ...
```

> Replace with referencing existing secrets already created and managed by your platform team.

For example:

```bash
--set-secrets="
  DB_POSTGRESDB_PASSWORD=goapptiv-db-password:latest,
  N8N_ENCRYPTION_KEY=goapptiv-encryption-key:latest
"
```

Ensure the **Cloud Run service account** has the required **`roles/secretmanager.secretAccessor`** for these secrets.

---

### 3. **Updated URL and OAuth Config**

Use the branded or internal URL GoApptiv provides, like:

```bash
https://automation.goapptiv.com
```

Update deployment accordingly:

```bash
--update-env-vars="
  N8N_HOST=automation.goapptiv.com,
  N8N_WEBHOOK_URL=https://automation.goapptiv.com,
  N8N_EDITOR_BASE_URL=https://automation.goapptiv.com
"
```

---

### 4. **Dockerfile & startup.sh (Unchanged)**

These are retained from the original guide to resolve Cloud Run port compatibility issues.

---

### 5. **Terraform Deployment (Optional)**

If GoApptiv uses Terraform (recommended), configure:

- Database host and user from variables
- Secret names injected via `terraform.tfvars`
- Avoid provisioning new SQL/Secret resources

> Your Terraform file should read like this:

```hcl
variable "db_host" {}
variable "db_password_secret_name" {}
variable "encryption_key_secret_name" {}
...
```

---

## Final Notes for GoApptiv Teams

- Always **reuse existing resources** when possible to align with internal security protocols.
- Coordinate with **infra/security teams** before updating secret references or modifying service accounts.
- Maintain the Cloud Run YAML or Terraform files in a **secure Git repo** for reproducibility.
- **Update n8n regularly** and maintain version-locking in the Dockerfile for production use.
- Use **budget alerts** in GCP for proactive cost control.

---

### Recommended Folder Structure for GoApptiv

```
n8n-gcp-cloudrun/
├── Dockerfile
├── startup.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
├── scripts/
│   └── deploy.sh
└── README.md
```

---

## Cost Reminder

GoApptiv's internal setup minimizes the following costs:

| Component         | Approx. Monthly Cost | Notes                                             |
| ----------------- | -------------------- | ------------------------------------------------- |
| Cloud SQL         | Reused               | No additional charges                             |
| Cloud Run         | ₹0–₹500              | Depends on usage — serverless scaling             |
| Secret Manager    | ₹0                   | Free for up to 10,000 access/month                |
| Artifact Registry | ₹0                   | Free for up to 0.5 GB storage per month (approx.) |

---
