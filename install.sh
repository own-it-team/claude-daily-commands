#!/bin/bash

# Claude Daily Commands Installer
# Supports both one-click curl install and git clone install

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# GitHub repository info
GITHUB_USER="wineny"
GITHUB_REPO="claude-daily-commands"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main"

# Banner
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Claude Daily Commands${NC}"
echo -e "${BLUE}  Installer${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Detect installation method
if [ -d ".claude/commands" ]; then
    # Local installation (git clone method)
    INSTALL_METHOD="local"
    echo -e "${BLUE}🔍 Detected local repository${NC}"
else
    # Remote installation (curl method)
    INSTALL_METHOD="remote"
    echo -e "${BLUE}🌐 Remote installation mode${NC}"
fi

echo ""
echo "Installation options:"
echo "  1) Global (all projects - recommended)"
echo "  2) Cancel"
echo ""
read -p "Choose installation type (1/2): " choice

case $choice in
    1)
        INSTALL_TYPE="global"
        ;;
    2)
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Installation cancelled${NC}"
        exit 1
        ;;
esac

# Ask about v2 installation
echo ""
echo "Would you like to install v2 optimized commands?"
echo "  v2: 80% shorter output, 85% fewer approvals, 73% faster"
echo ""
echo "  y) Install v1 + v2 (recommended)"
echo "  n) Install v1 only"
echo ""
read -p "Install v2? (y/n): " install_v2

INSTALL_V2=false
if [ "$install_v2" = "y" ] || [ "$install_v2" = "Y" ]; then
    INSTALL_V2=true
fi

# Install globally
echo ""
echo -e "${BLUE}🌍 Installing globally...${NC}"

# Create global directory
mkdir -p ~/.claude/commands

# Download or copy files based on installation method
if [ "$INSTALL_METHOD" = "remote" ]; then
    # Remote installation - download from GitHub
    echo "Downloading command files from GitHub..."

    # Download v1 commands
    curl -fsSL "${GITHUB_RAW}/.claude/commands/dailyreview.md" -o ~/.claude/commands/dailyreview.md
    echo "  ✓ dailyreview.md"

    curl -fsSL "${GITHUB_RAW}/.claude/commands/todo.md" -o ~/.claude/commands/todo.md
    echo "  ✓ todo.md"

    curl -fsSL "${GITHUB_RAW}/.claude/commands/portfolio.md" -o ~/.claude/commands/portfolio.md
    echo "  ✓ portfolio.md"

    # Download v2 commands if requested
    if [ "$INSTALL_V2" = true ]; then
        curl -fsSL "${GITHUB_RAW}/.claude/commands/dailyreviewv2.md" -o ~/.claude/commands/dailyreviewv2.md
        echo "  ✓ dailyreviewv2.md"

        curl -fsSL "${GITHUB_RAW}/.claude/commands/todov2.md" -o ~/.claude/commands/todov2.md
        echo "  ✓ todov2.md"
    fi
else
    # Local installation - copy from local directory
    echo "Copying command files from local repository..."

    cp -v .claude/commands/dailyreview.md ~/.claude/commands/
    cp -v .claude/commands/todo.md ~/.claude/commands/
    cp -v .claude/commands/portfolio.md ~/.claude/commands/

    if [ "$INSTALL_V2" = true ]; then
        cp -v .claude/commands/dailyreviewv2.md ~/.claude/commands/
        cp -v .claude/commands/todov2.md ~/.claude/commands/
    fi
fi

echo ""
echo -e "${GREEN}✅ Global installation complete!${NC}"
echo ""
echo -e "Commands installed to: ${BLUE}~/.claude/commands/${NC}"
echo ""
echo "Available commands (in all projects):"
echo ""
echo "v1 (detailed output):"
echo "  • /dailyreview - Git-based daily work review"
echo "  • /todo        - Smart todo recommendations"
echo "  • /portfolio   - Portfolio generation (beta)"

if [ "$INSTALL_V2" = true ]; then
    echo ""
    echo "v2 (optimized, faster):"
    echo "  • /dailyreviewv2 - 80% shorter, 85% fewer approvals"
    echo "  • /todov2        - 70% shorter, faster execution"
    echo ""
    echo -e "${GREEN}💡 Try v2 first for daily use!${NC}"
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Restart Claude Code completely to see the new commands${NC}"
echo -e "${YELLOW}   (Use Cmd+Q or Ctrl+Q to quit, then restart)${NC}"

# Show next steps
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Quick Start${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "1. Restart Claude Code completely (Cmd+Q)"
echo "2. Navigate to a Git repository"
echo "3. Type / to see available commands"
echo ""
if [ "$INSTALL_V2" = true ]; then
    echo -e "${GREEN}Try this:${NC}"
    echo "  /dailyreviewv2        # Fast daily review"
    echo "  /dailyreviewv2 --brief # Ultra-compact (3 lines)"
    echo "  /todov2               # Quick todo list"
    echo ""
fi
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
echo -e "📖 Docs: ${BLUE}https://github.com/${GITHUB_USER}/${GITHUB_REPO}${NC}"
echo -e "🐛 Issues: ${BLUE}https://github.com/${GITHUB_USER}/${GITHUB_REPO}/issues${NC}"
echo ""
