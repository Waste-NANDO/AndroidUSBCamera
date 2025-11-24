#!/bin/bash

# Quick Publish Script - Publishes to GitHub Packages
# This is the FASTEST way to publish your committed changes

set -e

echo "🚀 AndroidUSBCamera - Quick Publish"
echo "===================================="
echo ""
echo "This will publish your latest master branch code to GitHub Packages"
echo ""

# Check if git is clean
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Warning: You have uncommitted changes"
    echo ""
    read -p "Do you want to commit them first? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        read -p "Enter commit message: " commit_msg
        git commit -m "$commit_msg"
        git push origin master
        echo "✅ Changes committed and pushed"
        echo ""
    fi
fi

echo "📋 Current version in build.gradle:"
grep "versionNameString = " build.gradle | sed "s/.*versionNameString = '\(.*\)'/\1/"
echo ""

echo "Choose publishing method:"
echo "1) Trigger GitHub Actions (Recommended - builds on GitHub servers)"
echo "2) Publish locally (Faster but requires local build)"
echo "3) Cancel"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📤 Triggering GitHub Actions workflow..."

        if [ -z "$GITHUB_TOKEN" ]; then
            echo ""
            echo "❌ GITHUB_TOKEN not set. Please run:"
            echo "   export GITHUB_TOKEN=your_token_here"
            echo ""
            echo "Create token at: https://github.com/settings/tokens"
            echo "Required scopes: 'repo' and 'workflow'"
            exit 1
        fi

        ./trigger-publish.sh
        ;;
    2)
        echo ""
        echo "🔨 Building and publishing locally..."

        if ! grep -q "gpr.user" local.properties 2>/dev/null; then
            echo ""
            echo "⚠️  GitHub credentials not found in local.properties"
            echo ""
            read -p "Enter your GitHub username: " gh_user
            read -s -p "Enter your GitHub token (with write:packages): " gh_token
            echo ""
            echo "gpr.user=$gh_user" >> local.properties
            echo "gpr.token=$gh_token" >> local.properties
            echo "✅ Credentials saved to local.properties"
            echo ""
        fi

        ./gradlew clean publish

        echo ""
        echo "✅ Published successfully!"
        echo ""
        echo "View packages at:"
        echo "  https://github.com/NicoMederoReLearn/AndroidUSBCamera/packages"
        ;;
    3)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

