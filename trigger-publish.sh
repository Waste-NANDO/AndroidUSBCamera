#!/bin/bash

# Trigger GitHub Actions Workflow to Publish Packages
# This script triggers the "Publish to GitHub Packages" workflow manually

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 GitHub Packages Publishing Script${NC}"
echo ""

# Check if local.properties has github.token
if [ ! -f "local.properties" ]; then
    echo -e "${RED}❌ Error: local.properties file not found${NC}"
    echo ""
    echo "Please create local.properties with your GitHub credentials:"
    echo "  github.actor=YOUR_USERNAME"
    echo "  github.token=YOUR_TOKEN"
    echo ""
    echo "Create a Personal Access Token with 'repo' and 'workflow' scopes:"
    echo "  https://github.com/settings/tokens"
    exit 1
fi

GITHUB_TOKEN=$(grep "github.token=" local.properties | cut -d'=' -f2)

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Error: github.token not found in local.properties${NC}"
    echo ""
    echo "Please add your GitHub token to local.properties:"
    echo "  github.actor=YOUR_USERNAME"
    echo "  github.token=YOUR_TOKEN"
    echo ""
    echo "Create a Personal Access Token with 'repo' and 'workflow' scopes:"
    echo "  https://github.com/settings/tokens"
    exit 1
fi

OWNER="NicoMederoReLearn"
REPO="AndroidUSBCamera"
WORKFLOW_ID="publish.yml"
BRANCH="master"

echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Repository: $OWNER/$REPO"
echo "  Workflow: $WORKFLOW_ID"
echo "  Branch: $BRANCH"
echo ""

# Trigger the workflow
echo -e "${BLUE}📤 Triggering workflow...${NC}"
response=$(curl -s -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/dispatches \
  -d "{\"ref\":\"$BRANCH\"}")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Workflow triggered successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Monitor progress at:${NC}"
    echo "  https://github.com/$OWNER/$REPO/actions"
    echo ""
    echo -e "${BLUE}📦 Packages will be available at:${NC}"
    echo "  https://github.com/$OWNER/$REPO/packages"
    echo ""
    echo -e "${BLUE}⏱️  Expected time: 5-10 minutes${NC}"
else
    echo -e "${RED}❌ Failed to trigger workflow${NC}"
    echo "Response: $response"
    exit 1
fi

