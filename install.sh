#!/bin/bash

# Own It Custom Commands Installer
# Installs Claude Code custom commands for daily review and portfolio generation

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Own It - Custom Commands${NC}"
echo -e "${BLUE}  Claude Code Installer${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -d ".claude/commands" ]; then
    echo -e "${RED}❌ Error: .claude/commands directory not found${NC}"
    echo -e "${YELLOW}💡 Please run this script from the owinit-custom-command directory${NC}"
    exit 1
fi

# Check if Claude Code is installed (optional check)
echo -e "${BLUE}🔍 Checking environment...${NC}"

# Detect installation type
if [ -d ".git" ]; then
    echo -e "${YELLOW}📦 Detected Git repository - Ready to install${NC}"
fi

echo ""
echo "Installation options:"
echo "  1) Global (all projects - recommended)"
echo "  2) Local (current project only)"
echo "  3) Cancel"
echo ""
read -p "Choose installation type (1/2/3): " choice

case $choice in
    1)
        INSTALL_TYPE="global"
        ;;
    2)
        INSTALL_TYPE="local"
        ;;
    3)
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

# Install based on type
if [ "$INSTALL_TYPE" = "global" ]; then
    echo ""
    echo -e "${BLUE}🌍 Installing globally...${NC}"

    # Create global directory
    mkdir -p ~/.claude/commands

    # Copy v1 commands
    echo "Copying v1 command files..."
    cp -v .claude/commands/dailyreview.md ~/.claude/commands/
    cp -v .claude/commands/todo.md ~/.claude/commands/
    cp -v .claude/commands/portfolio.md ~/.claude/commands/

    # Copy v2 commands if requested
    if [ "$INSTALL_V2" = true ]; then
        echo "Copying v2 optimized commands..."
        cp -v .claude/commands/dailyreviewv2.md ~/.claude/commands/
        cp -v .claude/commands/todov2.md ~/.claude/commands/
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

elif [ "$INSTALL_TYPE" = "local" ]; then
    echo ""
    echo -e "${BLUE}📦 Installing locally to current project...${NC}"

    # Commands are already in .claude/commands, just confirm
    echo ""
    echo -e "${GREEN}✅ Commands are already available in this project!${NC}"
    echo ""
    echo -e "Location: ${BLUE}./.claude/commands/${NC}"
    echo ""
    echo "Available commands:"
    echo "  • /dailyreview - Git-based daily work review"
    echo "  • /todo        - Smart todo recommendations"

    if [ "$INSTALL_V2" = true ]; then
        echo "  • /dailyreviewv2 - Optimized version"
        echo "  • /todov2        - Optimized version"
    fi

    echo "  • /portfolio   - Portfolio generation (beta)"
    echo ""
    echo -e "${YELLOW}💡 Open Claude Code in this project to use the commands${NC}"
fi

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
echo -e "📖 Docs: ${BLUE}https://github.com/wineny/owinit-custom-command${NC}"
echo -e "🐛 Issues: ${BLUE}https://github.com/wineny/owinit-custom-command/issues${NC}"
echo ""
