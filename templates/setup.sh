#!/bin/bash
# GSM Config Repository Setup Script

set -e

echo "🚀 GSM Config Repository Setup"
echo "=============================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a git repository. Please run this from your config repo root."
    exit 1
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p config/encrypted
mkdir -p config/raw
mkdir -p .github/workflows

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Raw (unencrypted) config files - NEVER commit these!
config/raw/
raw/
*.raw.yaml
*.raw.yml
*.decrypted.yaml
*.decrypted.yml

# Temporary files
*.tmp
*.temp
.DS_Store

# Environment files
.env
.env.*

# GSM binary
gsm
gsm.exe
EOF
fi

# Create example raw config
echo "📄 Creating example config..."
cat > config/raw/example.yaml << 'EOF'
org: your-github-org
repositories:
  - repo1
  - repo2
env:
  DATABASE_URL: "postgresql://user:pass@host:5432/db"
  API_KEY: "your-api-key-here"
  SECRET_TOKEN: "your-secret-token"
EOF

# Create basic workflow
echo "⚙️  Creating GitHub Actions workflow..."
cat > .github/workflows/sync-secrets.yml << 'EOF'
name: Sync Secrets

on:
  push:
    branches:
      - main
    paths:
      - 'config/encrypted/**/*.yaml'
      - 'config/encrypted/**/*.yml'
  workflow_dispatch:

jobs:
  sync-secrets:
    name: Sync Secrets to Repositories
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Sync Secrets with GSM
        uses: dacsang97/gsm-action@v1
        with:
          github-token: ${{ secrets.GSM_GITHUB_TOKEN }}
          encryption-key: ${{ secrets.GSM_ENCRYPTION_KEY }}
          config-path: config/encrypted
EOF

# Download GSM if not present
if [ ! -f ./gsm ]; then
    echo "📥 Downloading GSM CLI..."
    PLATFORM="linux-x86_64"
    case "$(uname -s)" in
        Darwin*)
            if [ "$(uname -m)" = "arm64" ]; then
                PLATFORM="macos-aarch64"
            else
                PLATFORM="macos-x86_64"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            PLATFORM="windows-x86_64"
            ;;
    esac
    
    curl -L -o gsm "https://github.com/dacsang97/gsm/releases/latest/download/gsm-${PLATFORM}"
    chmod +x gsm
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Set your encryption key:"
echo "   export ENCRYPTION_KEY='your-secure-key-here'"
echo ""
echo "2. Edit your config file:"
echo "   nano config/raw/example.yaml"
echo ""
echo "3. Encrypt your config:"
echo "   ./gsm encrypt --file config/raw/example.yaml --output config/encrypted/example.yaml"
echo ""
echo "4. Add GitHub secrets to your repository:"
echo "   - GSM_GITHUB_TOKEN: Your GitHub PAT with repo and admin:repo_hook permissions"
echo "   - GSM_ENCRYPTION_KEY: Your encryption key"
echo ""
echo "5. Commit and push:"
echo "   git add config/encrypted/ .github/ .gitignore"
echo "   git commit -m 'Initial GSM setup'"
echo "   git push"
echo ""
echo "⚠️  Remember: NEVER commit files from config/raw/ !"