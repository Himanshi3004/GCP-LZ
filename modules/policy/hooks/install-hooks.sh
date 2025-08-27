#!/bin/bash

# Script to install pre-commit hooks
set -e

echo "Installing pre-commit hooks..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp modules/policy/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed successfully"

# Install required tools if not present
echo "Checking required tools..."

# Check for terraform
if ! command -v terraform >/dev/null 2>&1; then
    echo "❌ Terraform not found. Please install Terraform"
    exit 1
fi

# Check for tfsec
if ! command -v tfsec >/dev/null 2>&1; then
    echo "⚠️  tfsec not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install tfsec
    elif command -v curl >/dev/null 2>&1; then
        curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
    else
        echo "Please install tfsec manually: https://github.com/aquasecurity/tfsec"
    fi
fi

# Check for conftest
if ! command -v conftest >/dev/null 2>&1; then
    echo "⚠️  conftest not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install conftest
    elif command -v curl >/dev/null 2>&1; then
        curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
        sudo mv conftest /usr/local/bin
    else
        echo "Please install conftest manually: https://github.com/open-policy-agent/conftest"
    fi
fi

# Check for OPA
if ! command -v opa >/dev/null 2>&1; then
    echo "⚠️  OPA not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install opa
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
        chmod +x opa
        sudo mv opa /usr/local/bin
    else
        echo "Please install OPA manually: https://www.openpolicyagent.org/docs/latest/#running-opa"
    fi
fi

echo "✅ All tools installed successfully"
echo "Pre-commit hooks are now active. They will run automatically on git commit."