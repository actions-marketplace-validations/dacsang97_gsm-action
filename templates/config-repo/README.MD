# Secret Configuration Repository

This repository contains encrypted configuration files for managing GitHub secrets across multiple repositories.

## Structure

```
.
├── config/
│   ├── encrypted/      # ✅ Encrypted files (safe to commit)
│   │   ├── production/
│   │   ├── staging/
│   │   └── development/
│   └── raw/           # ❌ Raw files (NEVER commit - in .gitignore)
├── .github/
│   └── workflows/
│       └── sync-secrets.yml
└── .gitignore
```

## Setup Instructions

1. **Install GSM CLI**:

   ```bash
   curl -L -o gsm https://github.com/dacsang97/gsm/releases/latest/download/gsm-linux-x86_64
   chmod +x gsm
   ```

2. **Set Encryption Key**:

   ```bash
   export ENCRYPTION_KEY="your-secure-encryption-key"
   ```

3. **Create Raw Config**:

   ```bash
   mkdir -p config/raw
   # Edit config/raw/myapp.yaml with your secrets
   ```

4. **Encrypt Config**:

   ```bash
   ./gsm encrypt --file config/raw/myapp.yaml --output config/encrypted/myapp.yaml
   ```

5. **Commit Encrypted File**:
   ```bash
   git add config/encrypted/myapp.yaml
   git commit -m "Add encrypted config for myapp"
   git push
   ```

## Security Notice

⚠️ **NEVER commit files from `config/raw/` directory!**

These contain unencrypted secrets and must remain local only. The `.gitignore` file is configured to prevent accidental commits.

## Workflow

The GitHub Actions workflow will automatically:

1. Detect changes to encrypted config files
2. Decrypt them using the stored encryption key
3. Push secrets to the configured repositories

See `.github/workflows/sync-secrets.yml` for details.
