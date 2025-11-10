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
    INTERACTIVE=true
else
    # Remote installation (curl method)
    INSTALL_METHOD="remote"
    echo -e "${BLUE}🌐 Remote installation mode${NC}"
    # For curl pipe installation, default to global + v2
    INTERACTIVE=false
fi

# Installation type selection
if [ "$INTERACTIVE" = true ]; then
    echo ""
    echo "Installation options:"
    echo "  1) Global (all projects - recommended)"
    echo "  2) Cancel"
    echo ""
    read -p "Choose installation type (1/2): " choice < /dev/tty

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
    read -p "Install v2? (y/n): " install_v2 < /dev/tty

    INSTALL_V2=false
    if [ "$install_v2" = "y" ] || [ "$install_v2" = "Y" ]; then
        INSTALL_V2=true
    fi
else
    # Non-interactive mode (curl pipe)
    INSTALL_TYPE="global"
    INSTALL_V2=true
    echo ""
    echo -e "${GREEN}📦 Auto-installing: Global + v2 optimized commands${NC}"
    echo ""
fi

# Install globally
echo -e "${BLUE}🌍 Installing globally...${NC}"

# Create global directory
mkdir -p ~/.claude/commands

# Download or copy files based on installation method
if [ "$INSTALL_METHOD" = "remote" ]; then
    # Remote installation - download from GitHub
    echo "Downloading command files from GitHub..."
    echo ""

    # Download v1 commands
    echo -n "  Downloading dailyreview.md... "
    if curl -fsSL "${GITHUB_RAW}/.claude/commands/dailyreview.md" -o ~/.claude/commands/dailyreview.md 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        exit 1
    fi

    echo -n "  Downloading todo.md... "
    if curl -fsSL "${GITHUB_RAW}/.claude/commands/todo.md" -o ~/.claude/commands/todo.md 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        exit 1
    fi

    echo -n "  Downloading portfolio.md... "
    if curl -fsSL "${GITHUB_RAW}/.claude/commands/portfolio.md" -o ~/.claude/commands/portfolio.md 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        exit 1
    fi

    # Download v2 commands if requested
    if [ "$INSTALL_V2" = true ]; then
        echo -n "  Downloading dailyreviewv2.md... "
        if curl -fsSL "${GITHUB_RAW}/.claude/commands/dailyreviewv2.md" -o ~/.claude/commands/dailyreviewv2.md 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            exit 1
        fi

        echo -n "  Downloading todov2.md... "
        if curl -fsSL "${GITHUB_RAW}/.claude/commands/todov2.md" -o ~/.claude/commands/todov2.md 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            exit 1
        fi
    fi
else
    # Local installation - copy from local directory
    echo "Copying command files from local repository..."
    echo ""

    cp -v .claude/commands/dailyreview.md ~/.claude/commands/
    cp -v .claude/commands/todo.md ~/.claude/commands/
    cp -v .claude/commands/portfolio.md ~/.claude/commands/

    if [ "$INSTALL_V2" = true ]; then
        cp -v .claude/commands/dailyreviewv2.md ~/.claude/commands/
        cp -v .claude/commands/todov2.md ~/.claude/commands/
    fi
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "📁 Commands installed to: ${BLUE}~/.claude/commands/${NC}"
echo ""
echo "📋 Available commands (in all projects):"
echo ""
echo "   ${BLUE}v1 (detailed output)${NC}"
echo "   • /dailyreview - Git-based daily work review"
echo "   • /todo        - Smart todo recommendations"
echo "   • /portfolio   - Portfolio generation (beta)"

if [ "$INSTALL_V2" = true ]; then
    echo ""
    echo "   ${GREEN}v2 (optimized, faster)${NC}"
    echo "   • /dailyreviewv2 - 80% shorter, 85% fewer approvals ⭐"
    echo "   • /todov2        - 70% shorter, faster execution ⭐"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Restart Claude Code to see the new commands:"
echo "  • macOS: Cmd+Q, then reopen"
echo "  • Windows/Linux: Ctrl+Q, then reopen"
echo ""

# Show next steps
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Quick Start${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Restart Claude Code (Cmd+Q)"
echo "2. Open any Git repository"
echo "3. Type / to see commands"
echo ""

if [ "$INSTALL_V2" = true ]; then
    echo -e "${GREEN}Try these:${NC}"
    echo ""
    echo "  /dailyreviewv2          # Quick daily summary"
    echo "  /dailyreviewv2 --brief  # Ultra-compact (3 lines)"
    echo "  /todov2                 # Fast todo list"
    echo ""
fi

echo -e "📖 Documentation: ${BLUE}https://github.com/${GITHUB_USER}/${GITHUB_REPO}${NC}"
echo -e "🐛 Report issues: ${BLUE}https://github.com/${GITHUB_USER}/${GITHUB_REPO}/issues${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
