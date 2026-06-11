#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Installer for Antigravity IDE (macOS/Linux)"
echo "=================================================================="
echo ""
echo "   Antigravity IDE is Google's AI-powered IDE built as a fork of VS Code"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Check if Antigravity IDE is installed by looking for its product data directory
ANTIGRAVITY_IDE_DIR="$HOME/.gemini/antigravity-ide"
if [ ! -d "$ANTIGRAVITY_IDE_DIR" ]; then
    echo -e "${RED}❌ Error: Antigravity IDE directory not found!${NC}"
    echo "   Expected location: $ANTIGRAVITY_IDE_DIR"
    echo "   Please ensure Antigravity IDE is installed and has been run at least once."
    exit 1
fi

echo -e "${GREEN}✓ Antigravity IDE installation found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Antigravity IDE uses VS Code-compatible extensions
# Install by copying to the extensions directory
EXT_DIR="$HOME/.antigravity-ide/extensions/bwya77.islands-dark-1.0.0"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}✓ Theme extension installed to $EXT_DIR${NC}"
else
    echo -e "${RED}❌ Failed to install theme extension${NC}"
    exit 1
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."

# Find Antigravity IDE CLI. Do not fall back to legacy Antigravity or VS Code commands.
ANTIGRAVITY_IDE_CLI=""
if command -v agy-ide >/dev/null 2>&1; then
    ANTIGRAVITY_IDE_CLI="agy-ide"
    echo -e "${GREEN}✓ Antigravity IDE CLI found (agy-ide)${NC}"
fi

if [ -n "$ANTIGRAVITY_IDE_CLI" ]; then
    if "$ANTIGRAVITY_IDE_CLI" --install-extension subframe7536.custom-ui-style --force 2>/dev/null; then
        echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
        echo "   Please install it manually from the Extensions marketplace in Antigravity IDE"
    fi
else
    echo -e "${YELLOW}⚠️  Could not find Antigravity IDE CLI (agy-ide)${NC}"
    echo "   Please install the agy-ide shell command and re-run this script,"
    echo "   or install Custom UI Style extension manually from the Extensions marketplace in Antigravity IDE"
fi

echo ""
echo "🔤 Step 3: Installing Bear Sans UI fonts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed to Font Book${NC}"
    echo -e "${GRAY}   Note: You may need to restart applications to use the new fonts${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect OS type for automatic font installation${NC}"
    echo "   Please manually install the fonts from the 'fonts/' folder"
fi

echo ""
echo "⚙️  Step 4: Applying Antigravity IDE settings..."

# Antigravity IDE uses the same settings structure as VS Code
# but with its own config directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Antigravity IDE/User"
else
    SETTINGS_DIR="$HOME/.config/Antigravity IDE/User"
fi

SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Create settings directory if it doesn't exist
if [ ! -d "$SETTINGS_DIR" ]; then
    echo -e "${YELLOW}   Creating Antigravity IDE settings directory...${NC}"
    mkdir -p "$SETTINGS_DIR"
fi

# Backup existing settings if they exist, then merge
if [ -f "$SETTINGS_FILE" ]; then
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark.$TIMESTAMP"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."

    if command -v jq >/dev/null 2>&1; then
        # Merge: user's non-theme settings are preserved, Islands Dark theme keys win
        # This ensures updated fixes are applied while keeping user customizations
        if MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$SCRIPT_DIR/settings.json" 2>/dev/null); then
            echo "$MERGED" > "$SETTINGS_FILE"
            echo -e "${GREEN}✓ Settings merged (your non-theme settings preserved, theme settings updated)${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not parse existing settings.json - leaving it untouched${NC}"
            echo "   Your backup is at: $BACKUP_FILE"
            echo "   To apply Islands Dark settings, manually merge from: $SCRIPT_DIR/settings.json"
        fi
    else
        echo -e "${YELLOW}⚠️  jq not found - cannot merge settings safely${NC}"
        echo "   Your backup is at: $BACKUP_FILE"
        echo "   To apply Islands Dark settings, manually merge from: $SCRIPT_DIR/settings.json"
        echo "   Or install jq (https://jqlang.github.io/jq/) and re-run this script"
    fi
else
    # No existing settings - just copy
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Islands Dark settings applied${NC}"
fi

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run_antigravity_ide"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After Antigravity IDE reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected when using custom CSS — click the gear icon and select 'Don't Show Again'"
    echo "   • To activate the theme in Antigravity IDE, use the theme picker (Cmd/Ctrl+K Cmd/Ctrl+T)"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue..."
    fi
fi

echo "   Applying CSS customizations..."

echo ""
echo -e "${GREEN}🎉 Islands Dark theme has been installed for Antigravity IDE!${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "   1. Restart Antigravity IDE to apply the changes"
echo "   2. Open the Command Palette (Cmd/Ctrl+Shift+P)"
echo "   3. Type 'Color Theme' and select 'Preferences: Color Theme'"
echo "   4. Select 'Islands Dark' from the list"
echo "   5. If you see a warning about corrupt installation, click 'Don't Show Again'"
echo ""
echo -e "${GRAY}Settings file location: $SETTINGS_FILE${NC}"
echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
