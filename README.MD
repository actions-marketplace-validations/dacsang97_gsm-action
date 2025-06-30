# GSM Action - GitHub Secrets Manager for Actions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Automate the synchronization of encrypted secrets to GitHub repositories using GSM (GitHub Secrets Manager) in your workflows.

## Overview

GSM Action allows you to:

- 🔐 Automatically decrypt config files stored in your repository
- 🚀 Push secrets to multiple GitHub repositories
- 🔄 Sync on push, schedule, or manual trigger
- ✅ Validate configs in pull requests

## Quick Start

```yaml
name: Sync Secrets
on:
  push:
    branches: [main]
    paths:
      - "config/encrypted/**/*.yaml"

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dacsang97/gsm-action@v1
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
```

## Setup Guide

### 1. Repository Structure

Organize your config repository:

```
your-config-repo/
├── config/
│   ├── encrypted/       # Encrypted config files (commit these)
│   │   ├── prod.yaml
│   │   ├── staging.yaml
│   │   └── dev.yaml
│   └── raw/            # Raw config files (DO NOT commit)
│       └── ...
├── .github/
│   └── workflows/
│       └── sync-secrets.yml
└── .gitignore          # Must include: config/raw/
```

### 2. Required Secrets

Add these secrets to your config repository:

| Secret               | Description                               | Required Permissions      |
| -------------------- | ----------------------------------------- | ------------------------- |
| `GSM_GITHUB_TOKEN`   | Personal Access Token or GitHub App Token | `repo`, `admin:repo_hook` |
| `GSM_ENCRYPTION_KEY` | Master encryption key for GSM             | N/A                       |

#### Creating a GitHub Token

**Option 1: Personal Access Token (PAT)**

1. Go to Settings → Developer settings → Personal access tokens
2. Create token with scopes: `repo`, `admin:repo_hook`
3. Store as `GSM_GITHUB_TOKEN` repository secret

**Option 2: GitHub App (Recommended for Organizations)**

1. Create a GitHub App with permissions:
   - Repository permissions: Actions (write), Secrets (write)
   - Subscribe to: Push events
2. Install the app on target repositories
3. Use app token in workflows

### 3. Encrypting Configs

Before committing configs:

```bash
# Install GSM CLI
curl -L -o gsm https://github.com/dacsang97/gsm/releases/latest/download/gsm-linux-x86_64
chmod +x gsm

# Set encryption key
export ENCRYPTION_KEY="your-strong-key"

# Encrypt all configs
./gsm encrypt-all --input config

# Commit only encrypted files
git add config/encrypted/
git commit -m "Add encrypted configs"
```

## Configuration

### Inputs

| Input            | Description                            | Default            |
| ---------------- | -------------------------------------- | ------------------ |
| `config-path`    | Path to encrypted config files         | `config/encrypted` |
| `github-token`   | GitHub token with required permissions | **Required**       |
| `encryption-key` | Master encryption key                  | **Required**       |
| `gsm-version`    | GSM version to use                     | `latest`           |
| `dry-run`        | Validate only, don't push secrets      | `false`            |
| `specific-file`  | Process only specific config file      | `""`               |

### Outputs

| Output            | Description                                    |
| ----------------- | ---------------------------------------------- |
| `processed-files` | Comma-separated list of processed config files |
| `updated-repos`   | Comma-separated list of updated repositories   |

## Example Workflows

### Basic Push-based Sync

```yaml
name: Sync Secrets

on:
  push:
    branches: [main]
    paths:
      - "config/encrypted/**/*.yaml"

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync Secrets
        uses: dacsang97/gsm-action@v1
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
```

### PR Validation

```yaml
name: Validate Configs

on:
  pull_request:
    paths:
      - "config/encrypted/**/*.yaml"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Configs
        uses: dacsang97/gsm-action@v1
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
          dry-run: "true"
```

### Scheduled Sync with Audit

```yaml
name: Daily Sync

on:
  schedule:
    - cron: "0 2 * * *" # 2 AM UTC daily

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync All Secrets
        id: sync
        uses: dacsang97/gsm-action@v1
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}

      - name: Create Audit Log
        run: |
          echo "Synced to: ${{ steps.sync.outputs.updated-repos }}"
```

### Manual Sync with Options

```yaml
name: Manual Sync

on:
  workflow_dispatch:
    inputs:
      config-file:
        description: "Specific config file (leave empty for all)"
        required: false
      dry-run:
        description: "Dry run mode"
        type: boolean
        default: false

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync Secrets
        uses: dacsang97/gsm-action@v1
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
          specific-file: ${{ inputs.config-file }}
          dry-run: ${{ inputs.dry-run }}
```

## Config File Format

GSM expects YAML config files with this structure:

```yaml
org: your-github-org
repositories:
  - repo1
  - repo2
  - repo3
env:
  DATABASE_URL: "postgresql://..."
  API_KEY: "sk-..."
  AWS_ACCESS_KEY_ID: "AKIA..."
  AWS_SECRET_ACCESS_KEY: "..."
```

Each secret in the `env` section is individually encrypted.

## Security Best Practices

### 1. Token Security

- **Use GitHub App tokens** instead of PATs when possible
- **Limit token scope** to only required repositories
- **Rotate tokens regularly** (every 90 days recommended)
- **Use environments** for additional protection:

```yaml
jobs:
  sync:
    environment: production # Requires approval
    runs-on: ubuntu-latest
```

### 2. Encryption Key Management

- **Never commit encryption keys**
- **Use strong keys**: At least 32 characters, randomly generated
- **Store in secure secret manager**: GitHub Secrets, Vault, etc.
- **Rotate keys periodically**: Update all encrypted files when rotating

### 3. Workflow Security

- **Pin action versions**: Use `@v1.2.3` instead of `@v1`
- **Limit workflow triggers**: Avoid `pull_request_target` for untrusted code
- **Review permissions**: Use minimum required permissions
- **Enable branch protection**: Require PR reviews for config changes

### 4. Monitoring

- **Set up alerts** for failed sync attempts
- **Regular review** of repository access

## Troubleshooting

### Common Issues

**1. Authentication Errors**

```
Error: Resource not accessible by integration
```

- Verify token has `repo` and `admin:repo_hook` permissions
- Check token hasn't expired
- Ensure token has access to target repositories

**2. Decryption Failures**

```
Error: Failed to decrypt config file
```

- Verify `ENCRYPTION_KEY` matches the one used for encryption
- Check if config file is corrupted
- Ensure file was encrypted with compatible GSM version

**3. Push Failures**

```
Error: Failed to update secret in org/repo
```

- Verify organization allows GitHub Actions to manage secrets
- Check if secret name contains invalid characters
- Ensure repository exists and is accessible

### Debug Mode

Enable debug logging:

```yaml
- name: Sync with Debug
  uses: dacsang97/gsm-action@v1
  env:
    ACTIONS_STEP_DEBUG: true
  with:
    github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
    encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
```

## Advanced Usage

### Multi-Environment Setup

Structure configs by environment:

```
config/
├── encrypted/
│   ├── prod/
│   │   ├── backend.yaml
│   │   └── frontend.yaml
│   ├── staging/
│   │   └── all.yaml
│   └── dev/
│       └── all.yaml
```

Sync specific environment:

```yaml
- uses: dacsang97/gsm-action@v1
  with:
    config-path: config/encrypted/prod
    github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
    encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
```

### Conditional Sync

Only sync when specific files change:

```yaml
- name: Check Changes
  id: changes
  run: |
    if git diff --name-only HEAD~1 HEAD | grep -q "critical-config.yaml"; then
      echo "sync-required=true" >> $GITHUB_OUTPUT
    fi

- name: Sync if Required
  if: steps.changes.outputs.sync-required == 'true'
  uses: dacsang97/gsm-action@v1
  with:
    github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
    encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
```

### Integration with Other Tools

**Slack Notification:**

```yaml
- name: Sync Secrets
  id: sync
  uses: dacsang97/gsm-action@v1
  with:
    github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
    encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}

- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: |
      Secret sync ${{ job.status }}
      Repos updated: ${{ steps.sync.outputs.updated-repos }}
```

## License

MIT License - see [LICENSE](../LICENSE) for details.
