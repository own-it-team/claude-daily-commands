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
    echo -e "${YELLOW}📦 Detected Git repository - Installing locally${NC}"
    INSTALL_TYPE="local"
else
    echo -e "${YELLOW}🌍 No Git repository detected - Installing globally${NC}"
    INSTALL_TYPE="global"
fi

echo ""
echo "Installation options:"
echo "  1) Local (current project only)"
echo "  2) Global (all projects)"
echo "  3) Cancel"
echo ""
read -p "Choose installation type (1/2/3): " choice

case $choice in
    1)
        INSTALL_TYPE="local"
        ;;
    2)
        INSTALL_TYPE="global"
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

# Install based on type
if [ "$INSTALL_TYPE" = "local" ]; then
    echo ""
    echo -e "${BLUE}📦 Installing locally to current project...${NC}"

    # Create directory if not exists
    mkdir -p .claude/commands

    # Copy commands
    cp -v .claude/commands/*.md .claude/commands/ 2>/dev/null || true

    echo ""
    echo -e "${GREEN}✅ Local installation complete!${NC}"
    echo ""
    echo -e "Commands installed to: ${BLUE}.claude/commands/${NC}"
    echo ""
    echo "Available commands:"
    echo "  • /dailyreview - Git-based daily work review"
    echo "  • /todo        - Smart todo recommendations"
    echo "  • /portfolio   - Portfolio generation (beta)"
    echo ""
    echo -e "${YELLOW}💡 Open Claude Code in this project to use the commands${NC}"

elif [ "$INSTALL_TYPE" = "global" ]; then
    echo ""
    echo -e "${BLUE}🌍 Installing globally...${NC}"

    # Create global directory
    mkdir -p ~/.claude/commands

    # Copy commands
    echo "Copying command files..."
    cp -v .claude/commands/dailyreview.md ~/.claude/commands/
    cp -v .claude/commands/todo.md ~/.claude/commands/
    cp -v .claude/commands/portfolio.md ~/.claude/commands/

    echo ""
    echo -e "${GREEN}✅ Global installation complete!${NC}"
    echo ""
    echo -e "Commands installed to: ${BLUE}~/.claude/commands/${NC}"
    echo ""
    echo "Available commands (in all projects):"
    echo "  • /dailyreview - Git-based daily work review"
    echo "  • /todo        - Smart todo recommendations"
    echo "  • /portfolio   - Portfolio generation (beta)"
    echo ""
    echo -e "${YELLOW}💡 Restart Claude Code to see the new commands${NC}"
fi

# Show next steps
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Next Steps${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "1. Open Claude Code"
echo "2. Navigate to a Git repository"
echo "3. Try: /dailyreview"
echo "4. Try: /todo"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
echo -e "📖 Documentation: ${BLUE}https://github.com/YOUR_USERNAME/owinit-custom-command${NC}"
echo -e "🐛 Issues: ${BLUE}https://github.com/YOUR_USERNAME/owinit-custom-command/issues${NC}"
echo ""
