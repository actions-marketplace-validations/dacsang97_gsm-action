# Security Policy

## Overview

GSM Action handles sensitive secrets and requires careful security considerations. This document outlines security best practices and our vulnerability disclosure process.

## Security Model

### Threat Model

1. **Encrypted Secrets at Rest**

   - Threat: Unauthorized access to encrypted config files
   - Mitigation: AES-256-GCM encryption with unique salt/nonce per value

2. **Secrets in Transit**

   - Threat: Interception during GitHub API calls
   - Mitigation: HTTPS only, GitHub's native secret encryption

3. **Workflow Compromise**

   - Threat: Malicious PR modifying workflows
   - Mitigation: Branch protection, environment approvals

4. **Token Exposure**
   - Threat: GitHub token or encryption key exposure
   - Mitigation: Secret scanning, limited token scope

## Best Practices

### 1. Repository Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "security-team"
```

### 2. Branch Protection Rules

Required settings for config repository:

- ✅ Require pull request reviews (2+ reviewers)
- ✅ Dismiss stale PR approvals
- ✅ Require status checks (CI validation)
- ✅ Require branches to be up to date
- ✅ Include administrators
- ✅ Restrict who can push

### 3. Token Management

#### GitHub App (Recommended)

```yaml
# Minimal required permissions
permissions:
  actions: write # To read workflow runs
  contents: read # To read config files
  secrets: write # To update secrets
```

#### Personal Access Token

If using PAT, implement rotation:

```yaml
name: Token Rotation Reminder

on:
  schedule:
    - cron: "0 0 1 */3 *" # Every 3 months

jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
      - name: Create Reminder Issue
        uses: actions/github-script@v7
        with:
          script: |
            const title = '[Security] Time to rotate GSM tokens';
            const body = `## Token Rotation Required

            It's been 3 months since the last token rotation.

            ### Rotation Checklist
            - [ ] Generate new GitHub token
            - [ ] Update GSM_GITHUB_TOKEN secret
            - [ ] Verify workflows still function
            - [ ] Revoke old token
            - [ ] Update rotation date in security log`;

            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title,
              body,
              labels: ['security', 'maintenance']
            });
```

### 4. Encryption Key Security

#### Key Requirements

- Minimum 32 characters
- Generated using cryptographically secure random source
- Never derived from passwords or predictable sources

#### Key Generation

```bash
# Generate secure key
openssl rand -base64 32

# Or using gsm
gsm generate-key
```

#### Key Storage

- Store in GitHub Secrets (encrypted at rest)
- Use environment-specific keys for isolation
- Never commit to repository

### 5. Workflow Security

#### Secure Workflow Template

```yaml
name: Secure Secret Sync

on:
  push:
    branches: [main]
    paths:
      - "config/encrypted/**/*.yaml"

permissions:
  contents: read
  # No write permissions at job level

jobs:
  sync:
    runs-on: ubuntu-latest
    environment: production # Requires manual approval
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          persist-credentials: false # Don't persist auth

      - name: Validate Actor
        run: |
          ALLOWED_ACTORS="user1,user2,bot-account"
          if [[ ! ",${ALLOWED_ACTORS}," =~ ",${GITHUB_ACTOR}," ]]; then
            echo "::error::Unauthorized actor: ${GITHUB_ACTOR}"
            exit 1
          fi

      - name: Sync Secrets
        uses: dacsang97/gsm-action@v1.2.3 # Pin version
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
```

## Vulnerability Disclosure

### Reporting Security Issues

**DO NOT** create public issues for security vulnerabilities.

Email: security@example.com
PGP Key: [Download](https://example.com/pgp-key.asc)

Include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Fix Timeline**: Based on severity
  - Critical: 7 days
  - High: 14 days
  - Medium: 30 days
  - Low: 90 days

## Security Checklist

### Initial Setup

- [ ] Generate strong encryption key (32+ chars)
- [ ] Store encryption key in GitHub Secrets
- [ ] Create GitHub App or PAT with minimal permissions
- [ ] Enable branch protection on main
- [ ] Set up environment protection rules
- [ ] Configure secret scanning
- [ ] Enable Dependabot

### Ongoing Maintenance

- [ ] Rotate tokens every 90 days
- [ ] Review workflow permissions quarterly
- [ ] Audit repository access monthly
- [ ] Update GSM version promptly

- [ ] Test disaster recovery annually

## Incident Response

### If Encryption Key is Compromised

1. **Immediate Actions** (Within 1 hour)

   ```bash
   # Generate new key
   NEW_KEY=$(openssl rand -base64 32)

   # Update GitHub Secret
   gh secret set GSM_ENCRYPTION_KEY --body "$NEW_KEY"
   ```

2. **Re-encrypt All Configs** (Within 4 hours)

   ```bash
   # Decrypt with old key
   OLD_KEY=$COMPROMISED_KEY gsm decrypt-all --input config

   # Encrypt with new key
   ENCRYPTION_KEY=$NEW_KEY gsm encrypt-all --input config

   # Commit updated files
   git add config/encrypted/
   git commit -m "security: rotate encryption key"
   ```

3. **Update All Secrets** (Within 24 hours)
   - Rotate all secrets in config files
   - Use `gsm push` to update repositories

### If GitHub Token is Compromised

1. **Revoke Immediately**

   - Go to Settings → Developer settings → Personal access tokens
   - Click "Revoke" on compromised token

2. **Generate New Token**

   - Create new token with same permissions
   - Update GSM_GITHUB_TOKEN secret

3. **Review Activity**
   - Review GitHub activity log for unauthorized actions
   - Check all repositories for unexpected changes

## Compliance

### SOC 2 Compliance

- Encryption at rest: ✅ AES-256-GCM
- Encryption in transit: ✅ TLS 1.2+
- Access controls: ✅ GitHub RBAC
- Activity logging: ✅ GitHub activity log

### GDPR Compliance

- Data minimization: Only store necessary secrets
- Right to erasure: Secrets can be deleted via GitHub API
- Data portability: Export via GSM decrypt commands

## Resources

- [GitHub Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GSM Security Documentation](https://github.com/dacsang97/gsm/security)
