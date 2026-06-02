#!/usr/bin/env bash
#
# gum - Git User Manager
# A tool to manage and switch between multiple Git identities
# Similar to nvm for Node.js versions
#
# Usage: gum <command> [options]
#

set -e

# ============================================================================
# Configuration
# ============================================================================

GUM_DIR="${GUM_DIR:-$HOME/.gum}"
GUM_PROFILES_DIR="$GUM_DIR/profiles"
GUM_CURRENT_FILE="$GUM_DIR/current"
GUM_CONFIG_FILE="$GUM_DIR/config"
GUM_VERSION="1.1.0"

# Default profile names (can be overridden in ~/.gum/config)
GUM_DEFAULT_PROFILES=("work" "home")

# Load user config if exists
if [[ -f "$GUM_CONFIG_FILE" ]]; then
    source "$GUM_CONFIG_FILE"
fi

# ============================================================================
# Colors & Formatting
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

gum_echo() {
    echo -e "${GREEN}[gum]${NC} $1"
}

gum_warn() {
    echo -e "${YELLOW}[gum]${NC} $1"
}

gum_error() {
    echo -e "${RED}[gum]${NC} $1" >&2
}

gum_info() {
    echo -e "${CYAN}[gum]${NC} $1"
}

# Ensure gum directories exist
gum_ensure_dirs() {
    mkdir -p "$GUM_PROFILES_DIR"
}

# Check if a profile exists
gum_profile_exists() {
    local name="$1"
    [[ -f "$GUM_PROFILES_DIR/$name.conf" ]]
}

# Get current active profile
gum_get_current() {
    if [[ -f "$GUM_CURRENT_FILE" ]]; then
        cat "$GUM_CURRENT_FILE"
    else
        echo ""
    fi
}

# Read a value from a profile
gum_read_profile() {
    local name="$1"
    local key="$2"
    local profile_file="$GUM_PROFILES_DIR/$name.conf"

    if [[ -f "$profile_file" ]]; then
        grep "^${key}=" "$profile_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"'
    fi
}

# Expand tilde in path
gum_expand_path() {
    local path="$1"
    echo "${path/#\~/$HOME}"
}

# ============================================================================
# Interactive Selector (arrow key navigation)
# ============================================================================

# Usage: gum_select "prompt" "option1" "option2" ...
# Returns the 1-based index of the selected option via the global GUM_SELECTED variable.
# Falls back to number input if not running in an interactive terminal.
GUM_SELECTED=0

gum_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}

    if [[ "$count" -eq 0 ]]; then
        return 1
    fi

    # Fallback to number input if not interactive (piped input)
    if [[ ! -t 0 ]]; then
        local i=1
        for opt in "${options[@]}"; do
            echo -e "    ${BOLD}${i})${NC} ${opt}"
            ((i++))
        done
        echo ""
        read -p "  ${prompt} [1-${count}, default: 1]: " choice
        choice="${choice:-1}"
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$count" ]]; then
            GUM_SELECTED=$choice
        else
            GUM_SELECTED=1
        fi
        return 0
    fi

    # Interactive mode: arrow key navigation
    local selected=0  # 0-based index

    # Restore cursor on Ctrl+C
    trap 'printf "\033[?25h"; exit 130' INT

    # Hide cursor
    printf '\033[?25l'

    # Draw the menu options
    _gum_render() {
        local i=0
        for opt in "${options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "    ${GREEN}❯ ${opt}${NC}"
            else
                echo -e "      ${DIM}${opt}${NC}"
            fi
            ((i++))
        done
    }

    # Initial draw
    echo ""
    echo -e "  ${prompt} ${DIM}(↑/↓ select, Enter confirm)${NC}"
    echo ""
    _gum_render

    # Input loop
    while true; do
        # Read a single character (silent, no echo)
        IFS= read -rsn1 key 2>/dev/null

        if [[ "$key" == $'\033' ]]; then
            # Escape sequence: read next 2 chars (e.g. [A, [B)
            # No timeout needed - they arrive as a burst with the escape char
            IFS= read -rsn1 bracket 2>/dev/null
            IFS= read -rsn1 arrow 2>/dev/null

            if [[ "$bracket" == "[" ]]; then
                case "$arrow" in
                    A)  # Up arrow
                        if [[ $selected -gt 0 ]]; then
                            ((selected--))
                        else
                            selected=$((count - 1))
                        fi
                        ;;
                    B)  # Down arrow
                        if [[ $selected -lt $((count - 1)) ]]; then
                            ((selected++))
                        else
                            selected=0
                        fi
                        ;;
                esac
            fi
        elif [[ "$key" == "" ]]; then
            # Enter key
            break
        elif [[ "$key" == "j" ]]; then
            # vim-style down
            if [[ $selected -lt $((count - 1)) ]]; then
                ((selected++))
            else
                selected=0
            fi
        elif [[ "$key" == "k" ]]; then
            # vim-style up
            if [[ $selected -gt 0 ]]; then
                ((selected--))
            else
                selected=$((count - 1))
            fi
        elif [[ "$key" =~ ^[0-9]$ ]] && [[ "$key" -ge 1 ]] && [[ "$key" -le "$count" ]]; then
            # Direct number input
            selected=$((key - 1))
            break
        fi

        # Redraw: move cursor up by $count lines, clear, redraw
        printf "\033[${count}A"
        printf "\033[J"
        _gum_render
    done

    # Show cursor
    printf '\033[?25h'

    # Clear the menu display and show final selection
    local total_lines=$((count + 2))
    printf "\033[${total_lines}A"
    printf "\033[J"
    echo -e "  ${prompt} ${GREEN}${options[$selected]}${NC}"
    echo ""

    # Reset trap
    trap - INT

    GUM_SELECTED=$((selected + 1))  # Return 1-based index
    return 0
}

# ============================================================================
# SSH Config Management
# ============================================================================

SSH_CONFIG_FILE="$HOME/.ssh/config"

# Add or update SSH config block for a profile
gum_update_ssh_config() {
    local profile_name="$1"
    local host="$2"
    local hostname="$3"
    local ssh_key="$4"
    local port="$5"

    # Ensure .ssh directory and config file exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$SSH_CONFIG_FILE"
    chmod 600 "$SSH_CONFIG_FILE"

    local marker_start="# >>> gum managed: ${profile_name} >>>"
    local marker_end="# <<< gum managed: ${profile_name} <<<"

    # Remove existing block for this profile
    if grep -q "$marker_start" "$SSH_CONFIG_FILE" 2>/dev/null; then
        # Use sed to remove the block between markers (inclusive)
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/$marker_start/,/$marker_end/d" "$SSH_CONFIG_FILE"
        else
            sed -i "/$marker_start/,/$marker_end/d" "$SSH_CONFIG_FILE"
        fi
    fi

    # Build the SSH config block
    local ssh_block=""
    ssh_block+="\n${marker_start}\n"
    ssh_block+="Host ${host}\n"
    ssh_block+="    HostName ${hostname}\n"
    ssh_block+="    PreferredAuthentications publickey\n"
    ssh_block+="    IdentityFile ${ssh_key}\n"
    ssh_block+="    User git\n"
    if [[ -n "$port" ]]; then
        ssh_block+="    Port ${port}\n"
    fi
    ssh_block+="${marker_end}\n"

    # Append the block to SSH config
    echo -e "$ssh_block" >> "$SSH_CONFIG_FILE"

    # Clean up excess blank lines at the beginning of the file
    local tmpfile
    tmpfile=$(mktemp)
    sed '/./,$!d' "$SSH_CONFIG_FILE" > "$tmpfile"
    mv "$tmpfile" "$SSH_CONFIG_FILE"
    chmod 600 "$SSH_CONFIG_FILE"

    gum_echo "SSH config updated for host ${BOLD}${host}${NC}"
}

# Remove SSH config block for a profile
gum_remove_ssh_config() {
    local profile_name="$1"
    local marker_start="# >>> gum managed: ${profile_name} >>>"
    local marker_end="# <<< gum managed: ${profile_name} <<<"

    if [[ -f "$SSH_CONFIG_FILE" ]] && grep -q "$marker_start" "$SSH_CONFIG_FILE" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/$marker_start/,/$marker_end/d" "$SSH_CONFIG_FILE"
        else
            sed -i "/$marker_start/,/$marker_end/d" "$SSH_CONFIG_FILE"
        fi
    fi
}

# ============================================================================
# SSH Config Parsing (read existing entries)
# ============================================================================

# Parse ~/.ssh/config and collect non-gum-managed Host entries.
# Outputs lines in the format: HOST|HOSTNAME|IDENTITYFILE|PORT
# Each line represents one discovered Host block.
gum_parse_existing_ssh_configs() {
    if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
        return 0
    fi

    local in_block=0
    local in_gum_block=0
    local host="" hostname="" identity="" port=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip gum managed blocks entirely
        if [[ "$line" == *">>> gum managed:"* ]]; then
            in_gum_block=1
            continue
        fi
        if [[ "$line" == *"<<< gum managed:"* ]]; then
            in_gum_block=0
            continue
        fi
        if [[ "$in_gum_block" -eq 1 ]]; then
            continue
        fi

        # Trim leading/trailing whitespace
        local trimmed
        trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip comments and empty lines
        if [[ -z "$trimmed" || "$trimmed" == \#* ]]; then
            # If we were in a block and hit empty line, flush
            if [[ "$in_block" -eq 1 && -z "$trimmed" ]]; then
                if [[ -n "$host" && "$host" != "*" ]]; then
                    echo "${host}|${hostname:-$host}|${identity}|${port}"
                fi
                host="" hostname="" identity="" port=""
                in_block=0
            fi
            continue
        fi

        # Detect Host line (start of a new block)
        if [[ "$trimmed" =~ ^Host[[:space:]]+(.+)$ ]]; then
            # Flush previous block if any
            if [[ "$in_block" -eq 1 && -n "$host" && "$host" != "*" ]]; then
                echo "${host}|${hostname:-$host}|${identity}|${port}"
            fi
            host="${BASH_REMATCH[1]}"
            hostname="" identity="" port=""
            in_block=1
            continue
        fi

        # Inside a block, extract fields
        if [[ "$in_block" -eq 1 ]]; then
            if [[ "$trimmed" =~ ^HostName[[:space:]]+(.+)$ ]]; then
                hostname="${BASH_REMATCH[1]}"
            elif [[ "$trimmed" =~ ^IdentityFile[[:space:]]+(.+)$ ]]; then
                identity="${BASH_REMATCH[1]}"
            elif [[ "$trimmed" =~ ^Port[[:space:]]+(.+)$ ]]; then
                port="${BASH_REMATCH[1]}"
            fi
        fi
    done < "$SSH_CONFIG_FILE"

    # Flush last block
    if [[ "$in_block" -eq 1 && -n "$host" && "$host" != "*" ]]; then
        echo "${host}|${hostname:-$host}|${identity}|${port}"
    fi
}

# ============================================================================
# Command: create
# ============================================================================

gum_create() {
    local name="$1"

    if [[ -z "$name" ]]; then
        gum_error "Usage: gum create <profile-name>"
        gum_error "Example: gum create personal"
        return 1
    fi

    # Check if name is valid (alphanumeric, dash, underscore)
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        gum_error "Profile name can only contain letters, numbers, dashes, and underscores"
        return 1
    fi

    if gum_profile_exists "$name"; then
        gum_error "Profile '${name}' already exists. Use 'gum delete ${name}' to remove it first."
        return 1
    fi

    gum_ensure_dirs

    echo ""
    echo -e "${BOLD}${PURPLE}  Create a new Git identity profile: ${name}${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────${NC}"
    echo ""

    # Get user.name
    read -p "  Git user.name: " user_name
    if [[ -z "$user_name" ]]; then
        gum_error "user.name cannot be empty"
        return 1
    fi

    # Get user.email
    read -p "  Git user.email: " user_email
    if [[ -z "$user_email" ]]; then
        gum_error "user.email cannot be empty"
        return 1
    fi

    # ── SSH Configuration ──────────────────────────────────────────────────
    # Try to detect existing SSH config entries and offer them as choices
    echo ""
    echo -e "  ${CYAN}SSH Configuration${NC}"

    local ssh_host="" ssh_hostname="" ssh_port="" ssh_key_path=""
    local existing_entries=()
    local use_existing=0

    # Parse existing SSH config
    while IFS= read -r entry; do
        [[ -n "$entry" ]] && existing_entries+=("$entry")
    done < <(gum_parse_existing_ssh_configs)

    if [[ ${#existing_entries[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}Found existing SSH configurations:${NC}"

        # Build display options for the selector
        local select_options=()
        for entry in "${existing_entries[@]}"; do
            local e_host e_hostname e_identity e_port
            IFS='|' read -r e_host e_hostname e_identity e_port <<< "$entry"
            if [[ -n "$e_identity" ]]; then
                select_options+=("${e_host} ${DIM}(key: ${e_identity})${NC}")
            else
                select_options+=("${e_host} ${DIM}(HostName: ${e_hostname})${NC}")
            fi
        done
        select_options+=("Configure manually (new SSH setup)")

        # Use interactive selector
        gum_select "Select SSH config:" "${select_options[@]}"
        local ssh_choice=$GUM_SELECTED
        local total_entries=${#existing_entries[@]}

        if [[ "$ssh_choice" -ge 1 ]] && [[ "$ssh_choice" -le "$total_entries" ]]; then
            # User picked an existing entry
            local chosen="${existing_entries[$((ssh_choice-1))]}"
            IFS='|' read -r ssh_host ssh_hostname ssh_key_path ssh_port <<< "$chosen"
            ssh_key_path=$(gum_expand_path "$ssh_key_path")
            use_existing=1

            echo -e "  ${DIM}Using existing config:${NC}"
            echo -e "    ${DIM}Host         = ${ssh_host}${NC}"
            echo -e "    ${DIM}HostName     = ${ssh_hostname}${NC}"
            [[ -n "$ssh_key_path" ]] && echo -e "    ${DIM}IdentityFile = ${ssh_key_path}${NC}"
            [[ -n "$ssh_port" ]] && echo -e "    ${DIM}Port         = ${ssh_port}${NC}"

            # If existing entry has no IdentityFile, we still need to handle the key
            if [[ -z "$ssh_key_path" ]]; then
                use_existing=0
                echo ""
                gum_warn "No IdentityFile found in this SSH config entry."
                gum_info "You'll need to specify or generate an SSH key."
            fi
        else
            # User chose manual configuration
            use_existing=0
        fi
    fi

    # ── Manual SSH setup (if no existing config chosen) ────────────────────
    if [[ "$use_existing" -eq 0 ]]; then
        if [[ -z "$ssh_host" ]]; then
            echo -e "  ${DIM}Common hosts: github.com, gitlab.com, bitbucket.org${NC}"
            read -p "  SSH Host (e.g., github.com): " ssh_host
            if [[ -z "$ssh_host" ]]; then
                ssh_host="github.com"
                gum_info "Using default host: github.com"
            fi
        fi

        if [[ -z "$ssh_hostname" ]]; then
            read -p "  SSH HostName [${ssh_host}]: " ssh_hostname
            if [[ -z "$ssh_hostname" ]]; then
                ssh_hostname="$ssh_host"
            fi
        fi

        if [[ -z "$ssh_port" ]]; then
            read -p "  SSH Port (leave empty for default 22): " ssh_port
        fi

        # SSH Key selection
        echo ""
        echo -e "  ${CYAN}SSH Key${NC}"
        gum_select "SSH key:" "Generate a new SSH key (recommended)" "Use an existing SSH key"
        key_choice=$GUM_SELECTED

        case "$key_choice" in
            2)
                read -p "  Path to existing SSH key: " ssh_key_path
                ssh_key_path=$(gum_expand_path "$ssh_key_path")
                if [[ ! -f "$ssh_key_path" ]]; then
                    gum_error "SSH key file not found: ${ssh_key_path}"
                    return 1
                fi
                ;;
            *)
                # Generate new key
                local default_key_path="$HOME/.ssh/gum_${name}_id_ed25519"
                read -p "  Key file path [${default_key_path}]: " ssh_key_path
                if [[ -z "$ssh_key_path" ]]; then
                    ssh_key_path="$default_key_path"
                else
                    ssh_key_path=$(gum_expand_path "$ssh_key_path")
                fi

                if [[ -f "$ssh_key_path" ]]; then
                    gum_warn "Key file already exists: ${ssh_key_path}"
                    read -p "  Overwrite? [y/N]: " overwrite
                    if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                        gum_info "Using existing key file"
                    else
                        rm -f "$ssh_key_path" "$ssh_key_path.pub"
                    fi
                fi

                if [[ ! -f "$ssh_key_path" ]]; then
                    echo ""
                    gum_info "Generating SSH key (ed25519)..."
                    ssh-keygen -t ed25519 -C "$user_email" -f "$ssh_key_path"
                    echo ""
                fi
                ;;
        esac
    fi

    # Use path with tilde for storage
    local stored_key_path="${ssh_key_path/#$HOME/~}"

    # Save profile
    cat > "$GUM_PROFILES_DIR/$name.conf" << EOF
GUM_USER_NAME="${user_name}"
GUM_USER_EMAIL="${user_email}"
GUM_SSH_HOST="${ssh_host}"
GUM_SSH_HOSTNAME="${ssh_hostname}"
GUM_SSH_KEY="${stored_key_path}"
GUM_SSH_PORT="${ssh_port}"
EOF

    # Update SSH config
    gum_update_ssh_config "$name" "$ssh_host" "$ssh_hostname" "$ssh_key_path" "$ssh_port"

    echo ""
    echo -e "${GREEN}  ✓ Profile '${name}' created successfully!${NC}"
    echo ""
    if [[ -f "${ssh_key_path}.pub" ]]; then
        echo -e "  ${DIM}Next steps:${NC}"
        echo -e "  ${DIM}  1. Copy your public key:${NC}"
        echo -e "       ${BOLD}cat ${ssh_key_path}.pub${NC}"
        echo -e "  ${DIM}  2. Add it to your Git hosting service (${ssh_host})${NC}"
        echo -e "  ${DIM}  3. Switch to this profile:${NC}"
        echo -e "       ${BOLD}gum use ${name}${NC}"
    else
        echo -e "  ${DIM}To activate: ${BOLD}gum use ${name}${NC}"
    fi
    echo ""
}

# ============================================================================
# Command: list
# ============================================================================

gum_list() {
    gum_ensure_dirs

    local profiles=("$GUM_PROFILES_DIR"/*.conf)
    local current=$(gum_get_current)

    if [[ ! -f "${profiles[0]}" ]]; then
        gum_info "No profiles found. Create one with: ${BOLD}gum create <name>${NC}"
        return 0
    fi

    echo ""
    echo -e "${BOLD}  Git User Profiles${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────${NC}"
    echo ""

    for profile_file in "${profiles[@]}"; do
        if [[ ! -f "$profile_file" ]]; then
            continue
        fi

        local profile_name=$(basename "$profile_file" .conf)
        local user_name=$(gum_read_profile "$profile_name" "GUM_USER_NAME")
        local user_email=$(gum_read_profile "$profile_name" "GUM_USER_EMAIL")
        local ssh_host=$(gum_read_profile "$profile_name" "GUM_SSH_HOST")

        if [[ "$profile_name" == "$current" ]]; then
            echo -e "  ${GREEN}▶ ${BOLD}${profile_name}${NC}  ${user_name} <${user_email}>  ${DIM}[${ssh_host}]${NC}"
        else
            echo -e "    ${profile_name}  ${DIM}${user_name} <${user_email}>  [${ssh_host}]${NC}"
        fi
    done
    echo ""
}

# ============================================================================
# Command: use
# ============================================================================

gum_use() {
    local name="$1"
    local scope="--global"

    # Parse options
    shift 2>/dev/null || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local|-l)
                scope="--local"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ -z "$name" ]]; then
        gum_error "Usage: gum use <profile-name> [--local]"
        gum_error "Available profiles:"
        gum_list
        return 1
    fi

    if ! gum_profile_exists "$name"; then
        gum_error "Profile '${name}' not found."
        gum_error "Run 'gum list' to see available profiles."
        return 1
    fi

    local user_name=$(gum_read_profile "$name" "GUM_USER_NAME")
    local user_email=$(gum_read_profile "$name" "GUM_USER_EMAIL")
    local ssh_key=$(gum_read_profile "$name" "GUM_SSH_KEY")
    local ssh_host=$(gum_read_profile "$name" "GUM_SSH_HOST")
    local ssh_hostname=$(gum_read_profile "$name" "GUM_SSH_HOSTNAME")
    local ssh_port=$(gum_read_profile "$name" "GUM_SSH_PORT")

    ssh_key=$(gum_expand_path "$ssh_key")

    if [[ "$scope" == "--local" ]]; then
        # Check if we're in a git repo
        if ! git rev-parse --is-inside-work-tree &>/dev/null; then
            gum_error "Not inside a Git repository. Cannot use --local outside a repo."
            return 1
        fi

        git config --local --replace-all user.name "$user_name"
        git config --local --replace-all user.email "$user_email"

        local repo_name=$(basename "$(git rev-parse --show-toplevel)")
        echo ""
        echo -e "${GREEN}  ✓ Switched to '${name}' for repo: ${BOLD}${repo_name}${NC}"
        echo -e "    ${DIM}user.name  = ${user_name}${NC}"
        echo -e "    ${DIM}user.email = ${user_email}${NC}"
        echo -e "    ${DIM}scope      = local${NC}"
        echo ""
    else
        # Global switch
        git config --global --replace-all user.name "$user_name"
        git config --global --replace-all user.email "$user_email"

        # Update SSH config
        gum_update_ssh_config "$name" "$ssh_host" "$ssh_hostname" "$ssh_key" "$ssh_port"

        # Add key to ssh-agent
        if [[ -f "$ssh_key" ]]; then
            # Start ssh-agent if not running
            if ! ssh-add -l &>/dev/null; then
                eval "$(ssh-agent -s)" &>/dev/null
            fi
            ssh-add "$ssh_key" 2>/dev/null && \
                gum_info "SSH key added to ssh-agent" || \
                gum_warn "Could not add SSH key to ssh-agent (you may need to enter passphrase manually)"
        fi

        # Save current profile
        echo "$name" > "$GUM_CURRENT_FILE"

        echo ""
        echo -e "${GREEN}  ✓ Switched to '${name}' (global)${NC}"
        echo -e "    ${DIM}user.name  = ${user_name}${NC}"
        echo -e "    ${DIM}user.email = ${user_email}${NC}"
        echo -e "    ${DIM}ssh.host   = ${ssh_host}${NC}"
        echo -e "    ${DIM}ssh.key    = ${ssh_key}${NC}"
        echo ""
    fi
}

# ============================================================================
# Command: current
# ============================================================================

gum_current() {
    local current=$(gum_get_current)

    echo ""
    if [[ -z "$current" ]]; then
        gum_warn "No profile is currently active."
        echo -e "    ${DIM}Use 'gum use <name>' to activate a profile.${NC}"
    else
        local user_name=$(gum_read_profile "$current" "GUM_USER_NAME")
        local user_email=$(gum_read_profile "$current" "GUM_USER_EMAIL")
        local ssh_host=$(gum_read_profile "$current" "GUM_SSH_HOST")
        local ssh_key=$(gum_read_profile "$current" "GUM_SSH_KEY")

        echo -e "  ${GREEN}▶ ${BOLD}${current}${NC}"
        echo -e "    ${DIM}user.name  = ${user_name}${NC}"
        echo -e "    ${DIM}user.email = ${user_email}${NC}"
        echo -e "    ${DIM}ssh.host   = ${ssh_host}${NC}"
        echo -e "    ${DIM}ssh.key    = ${ssh_key}${NC}"
    fi

    # Also show actual git config
    echo ""
    echo -e "  ${CYAN}Actual Git Config:${NC}"
    echo -e "    ${DIM}user.name  = $(git config --global user.name 2>/dev/null || echo 'not set')${NC}"
    echo -e "    ${DIM}user.email = $(git config --global user.email 2>/dev/null || echo 'not set')${NC}"

    # Show local config if in a git repo
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local local_name=$(git config --local user.name 2>/dev/null)
        local local_email=$(git config --local user.email 2>/dev/null)
        if [[ -n "$local_name" || -n "$local_email" ]]; then
            echo ""
            echo -e "  ${YELLOW}Local Override (this repo):${NC}"
            [[ -n "$local_name" ]] && echo -e "    ${DIM}user.name  = ${local_name}${NC}"
            [[ -n "$local_email" ]] && echo -e "    ${DIM}user.email = ${local_email}${NC}"
        fi
    fi
    echo ""
}

# ============================================================================
# Command: show
# ============================================================================

gum_show() {
    local name="$1"

    if [[ -z "$name" ]]; then
        gum_error "Usage: gum show <profile-name>"
        return 1
    fi

    if ! gum_profile_exists "$name"; then
        gum_error "Profile '${name}' not found."
        return 1
    fi

    local user_name=$(gum_read_profile "$name" "GUM_USER_NAME")
    local user_email=$(gum_read_profile "$name" "GUM_USER_EMAIL")
    local ssh_host=$(gum_read_profile "$name" "GUM_SSH_HOST")
    local ssh_hostname=$(gum_read_profile "$name" "GUM_SSH_HOSTNAME")
    local ssh_key=$(gum_read_profile "$name" "GUM_SSH_KEY")
    local ssh_port=$(gum_read_profile "$name" "GUM_SSH_PORT")
    local current=$(gum_get_current)

    echo ""
    echo -e "${BOLD}  Profile: ${name}${NC}"
    if [[ "$name" == "$current" ]]; then
        echo -e "  ${GREEN}(currently active)${NC}"
    fi
    echo -e "${DIM}  ─────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}Git Config:${NC}"
    echo -e "    user.name     = ${user_name}"
    echo -e "    user.email    = ${user_email}"
    echo ""
    echo -e "  ${CYAN}SSH Config:${NC}"
    echo -e "    Host          = ${ssh_host}"
    echo -e "    HostName      = ${ssh_hostname}"
    echo -e "    IdentityFile  = ${ssh_key}"
    if [[ -n "$ssh_port" ]]; then
        echo -e "    Port          = ${ssh_port}"
    fi

    # Check if key exists
    local expanded_key=$(gum_expand_path "$ssh_key")
    if [[ -f "$expanded_key" ]]; then
        echo ""
        echo -e "  ${CYAN}Public Key:${NC}"
        if [[ -f "${expanded_key}.pub" ]]; then
            echo -e "  ${DIM}$(cat "${expanded_key}.pub")${NC}"
        fi
    else
        echo ""
        echo -e "  ${YELLOW}⚠ SSH key file not found: ${ssh_key}${NC}"
    fi
    echo ""
}

# ============================================================================
# Command: delete
# ============================================================================

gum_delete() {
    local name="$1"

    if [[ -z "$name" ]]; then
        gum_error "Usage: gum delete <profile-name>"
        return 1
    fi

    if ! gum_profile_exists "$name"; then
        gum_error "Profile '${name}' not found."
        return 1
    fi

    local user_name=$(gum_read_profile "$name" "GUM_USER_NAME")
    local user_email=$(gum_read_profile "$name" "GUM_USER_EMAIL")
    local ssh_key=$(gum_read_profile "$name" "GUM_SSH_KEY")

    echo ""
    echo -e "  ${YELLOW}About to delete profile: ${BOLD}${name}${NC}"
    echo -e "    ${DIM}user.name  = ${user_name}${NC}"
    echo -e "    ${DIM}user.email = ${user_email}${NC}"
    echo -e "    ${DIM}ssh.key    = ${ssh_key}${NC}"
    echo ""
    read -p "  Are you sure? [y/N]: " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        gum_info "Cancelled."
        return 0
    fi

    # Ask about SSH key deletion
    local expanded_key=$(gum_expand_path "$ssh_key")
    if [[ -f "$expanded_key" ]]; then
        read -p "  Also delete SSH key files? [y/N]: " delete_key
        if [[ "$delete_key" == "y" || "$delete_key" == "Y" ]]; then
            rm -f "$expanded_key" "${expanded_key}.pub"
            gum_info "SSH key files deleted"
        fi
    fi

    # Remove SSH config block
    gum_remove_ssh_config "$name"

    # Remove profile file
    rm -f "$GUM_PROFILES_DIR/$name.conf"

    # Clear current if this was the active profile
    local current=$(gum_get_current)
    if [[ "$current" == "$name" ]]; then
        rm -f "$GUM_CURRENT_FILE"
    fi

    echo ""
    echo -e "${GREEN}  ✓ Profile '${name}' deleted.${NC}"
    echo ""
}

# ============================================================================
# Command: init
# ============================================================================

gum_init() {
    gum_ensure_dirs

    # Temporarily allow read failures (EOF in pipe mode)
    set +e

    echo ""
    echo -e "${BOLD}${PURPLE}  GUM Quick Setup${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────${NC}"
    echo ""
    echo -e "  This will guide you through setting up your Git identities."
    echo -e "  Default profiles: ${BOLD}${GUM_DEFAULT_PROFILES[*]}${NC}"
    echo -e "  ${DIM}(You can customize defaults in ~/.gum/config)${NC}"
    echo ""

    # Ask if user wants to use default names or custom ones
    echo -e "  ${CYAN}Profile Setup${NC}"
    gum_select "Profile names:" "Use defaults: ${GUM_DEFAULT_PROFILES[*]}" "Custom profile names"
    local setup_choice=$GUM_SELECTED

    local profiles=()

    if [[ "$setup_choice" == "2" ]]; then
        echo ""
        echo -e "  ${DIM}Enter profile names separated by spaces (e.g.: work home freelance):${NC}"
        read -p "  Profiles: " -a profiles
        if [[ ${#profiles[@]} -eq 0 ]]; then
            profiles=("${GUM_DEFAULT_PROFILES[@]}")
            gum_info "Using defaults: ${profiles[*]}"
        fi
    else
        profiles=("${GUM_DEFAULT_PROFILES[@]}")
    fi

    echo ""
    echo -e "  ${DIM}Setting up ${#profiles[@]} profile(s): ${BOLD}${profiles[*]}${NC}"
    echo ""

    local created_count=0

    for profile_name in "${profiles[@]}"; do
        # Validate name
        if [[ ! "$profile_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            gum_warn "Skipping invalid name: '${profile_name}'"
            continue
        fi

        if gum_profile_exists "$profile_name"; then
            gum_warn "Profile '${profile_name}' already exists, skipping."
            continue
        fi

        echo -e "${DIM}  ─────────────────────────────────────────${NC}"
        echo -e "  ${BOLD}${CYAN}Configure: ${profile_name}${NC}"
        echo ""

        # Get user.name
        read -p "  [$profile_name] Git user.name: " user_name
        if [[ -z "$user_name" ]]; then
            gum_warn "Skipping '${profile_name}' (empty user.name)"
            echo ""
            continue
        fi

        # Get user.email
        read -p "  [$profile_name] Git user.email: " user_email
        if [[ -z "$user_email" ]]; then
            gum_warn "Skipping '${profile_name}' (empty user.email)"
            echo ""
            continue
        fi

        # SSH Configuration - detect existing
        local ssh_host="" ssh_hostname="" ssh_port="" ssh_key_path=""
        local existing_entries=()
        local use_existing=0

        while IFS= read -r entry; do
            [[ -n "$entry" ]] && existing_entries+=("$entry")
        done < <(gum_parse_existing_ssh_configs)

        if [[ ${#existing_entries[@]} -gt 0 ]]; then
            echo ""
            echo -e "  ${GREEN}Found existing SSH configs:${NC}"

            local select_options=()
            for entry in "${existing_entries[@]}"; do
                local e_host e_hostname e_identity e_port
                IFS='|' read -r e_host e_hostname e_identity e_port <<< "$entry"
                if [[ -n "$e_identity" ]]; then
                    select_options+=("${e_host} ${DIM}(key: ${e_identity})${NC}")
                else
                    select_options+=("${e_host} ${DIM}(${e_hostname})${NC}")
                fi
            done
            select_options+=("Generate new SSH key")

            gum_select "[$profile_name] SSH config:" "${select_options[@]}"
            local ssh_choice=$GUM_SELECTED
            local total_entries=${#existing_entries[@]}

            if [[ "$ssh_choice" -ge 1 ]] && [[ "$ssh_choice" -le "$total_entries" ]]; then
                local chosen="${existing_entries[$((ssh_choice-1))]}"
                IFS='|' read -r ssh_host ssh_hostname ssh_key_path ssh_port <<< "$chosen"
                ssh_key_path=$(gum_expand_path "$ssh_key_path")
                use_existing=1
            fi
        fi

        if [[ "$use_existing" -eq 0 ]]; then
            # Ask for host
            read -p "  [$profile_name] SSH Host [github.com]: " ssh_host
            ssh_host="${ssh_host:-github.com}"
            ssh_hostname="$ssh_host"
            ssh_port=""

            # Generate new key
            ssh_key_path="$HOME/.ssh/gum_${profile_name}_id_ed25519"
            if [[ -f "$ssh_key_path" ]]; then
                gum_info "Key exists: ${ssh_key_path}, reusing."
            else
                echo ""
                gum_info "Generating SSH key for ${profile_name}..."
                ssh-keygen -t ed25519 -C "$user_email" -f "$ssh_key_path"
                echo ""
            fi
        fi

        # Save profile
        local stored_key_path="${ssh_key_path/#$HOME/~}"
        cat > "$GUM_PROFILES_DIR/$profile_name.conf" << EOF
GUM_USER_NAME="${user_name}"
GUM_USER_EMAIL="${user_email}"
GUM_SSH_HOST="${ssh_host}"
GUM_SSH_HOSTNAME="${ssh_hostname:-$ssh_host}"
GUM_SSH_KEY="${stored_key_path}"
GUM_SSH_PORT="${ssh_port}"
EOF

        # Update SSH config
        gum_update_ssh_config "$profile_name" "$ssh_host" "${ssh_hostname:-$ssh_host}" "$ssh_key_path" "$ssh_port"

        echo -e "  ${GREEN}✓ Profile '${profile_name}' created!${NC}"
        echo ""
        ((created_count++))
    done

    # Save user config with their chosen profile names
    if [[ ! -f "$GUM_CONFIG_FILE" ]]; then
        cat > "$GUM_CONFIG_FILE" << EOF
# GUM User Configuration
# Customize your default profile names and preferences here.

# Default profile names shown during 'gum init'
# Modify this array to change the default suggestions
GUM_DEFAULT_PROFILES=(${profiles[@]/#/\"})
EOF
        # Fix the array format in config
        local profiles_str=""
        for p in "${profiles[@]}"; do
            profiles_str+="\"$p\" "
        done
        cat > "$GUM_CONFIG_FILE" << EOF
# GUM User Configuration
# Customize your default profile names and preferences here.
# This file is sourced by gum on startup.

# Default profile names shown during 'gum init'
GUM_DEFAULT_PROFILES=(${profiles_str})

# Default SSH key type (ed25519 or rsa)
# GUM_SSH_KEY_TYPE="ed25519"

# Auto-add key to ssh-agent on 'gum use' (true/false)
# GUM_AUTO_SSH_ADD="true"
EOF
    fi

    echo -e "${DIM}  ─────────────────────────────────────────${NC}"
    echo ""
    if [[ "$created_count" -gt 0 ]]; then
        echo -e "${GREEN}  ✓ Setup complete! Created ${created_count} profile(s).${NC}"
        echo ""
        echo -e "  ${DIM}Switch identity:${NC}"
        echo -e "    ${BOLD}gum use ${profiles[0]}${NC}"
        echo ""
        echo -e "  ${DIM}List all profiles:${NC}"
        echo -e "    ${BOLD}gum list${NC}"
        echo ""
        echo -e "  ${DIM}Customize defaults:${NC}"
        echo -e "    ${BOLD}~/.gum/config${NC}"
    else
        gum_info "No new profiles were created."
    fi
    echo ""

    # Restore strict mode
    set -e
}

# ============================================================================
# Command: config
# ============================================================================

gum_config() {
    local action="${1:-show}"

    case "$action" in
        show)
            echo ""
            echo -e "${BOLD}  GUM Configuration${NC}"
            echo -e "${DIM}  ─────────────────────────────────────────${NC}"
            echo -e "  ${CYAN}Config file:${NC} $GUM_CONFIG_FILE"
            echo ""
            if [[ -f "$GUM_CONFIG_FILE" ]]; then
                echo -e "  ${CYAN}Current settings:${NC}"
                echo -e "    ${DIM}Default profiles = (${GUM_DEFAULT_PROFILES[*]})${NC}"
                echo -e "    ${DIM}SSH key type     = ${GUM_SSH_KEY_TYPE:-ed25519}${NC}"
                echo -e "    ${DIM}Auto ssh-add     = ${GUM_AUTO_SSH_ADD:-true}${NC}"
                echo ""
                echo -e "  ${DIM}Edit with: ${BOLD}\${EDITOR:-vi} ~/.gum/config${NC}"
            else
                echo -e "  ${DIM}No config file found. Run 'gum init' to create one.${NC}"
                echo -e "  ${DIM}Or create manually: ${BOLD}~/.gum/config${NC}"
            fi
            echo ""
            ;;
        edit)
            local editor="${EDITOR:-vi}"
            if [[ ! -f "$GUM_CONFIG_FILE" ]]; then
                gum_ensure_dirs
                cat > "$GUM_CONFIG_FILE" << 'EOF'
# GUM User Configuration
# Customize your default profile names and preferences here.
# This file is sourced by gum on startup.

# Default profile names shown during 'gum init'
GUM_DEFAULT_PROFILES=("work" "home")

# Default SSH key type (ed25519 or rsa)
# GUM_SSH_KEY_TYPE="ed25519"

# Auto-add key to ssh-agent on 'gum use' (true/false)
# GUM_AUTO_SSH_ADD="true"
EOF
            fi
            "$editor" "$GUM_CONFIG_FILE"
            ;;
        reset)
            cat > "$GUM_CONFIG_FILE" << 'EOF'
# GUM User Configuration
# Customize your default profile names and preferences here.
# This file is sourced by gum on startup.

# Default profile names shown during 'gum init'
GUM_DEFAULT_PROFILES=("work" "home")

# Default SSH key type (ed25519 or rsa)
# GUM_SSH_KEY_TYPE="ed25519"

# Auto-add key to ssh-agent on 'gum use' (true/false)
# GUM_AUTO_SSH_ADD="true"
EOF
            gum_echo "Config reset to defaults."
            ;;
        *)
            gum_error "Usage: gum config [show|edit|reset]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: import
# ============================================================================

gum_import() {
    local name="$1"

    if [[ -z "$name" ]]; then
        gum_error "Usage: gum import <profile-name>"
        gum_error "Import current git global config as a new profile"
        return 1
    fi

    if gum_profile_exists "$name"; then
        gum_error "Profile '${name}' already exists."
        return 1
    fi

    gum_ensure_dirs

    local user_name=$(git config --global user.name 2>/dev/null)
    local user_email=$(git config --global user.email 2>/dev/null)

    if [[ -z "$user_name" || -z "$user_email" ]]; then
        gum_error "Cannot import: git global user.name or user.email is not set"
        return 1
    fi

    echo ""
    echo -e "  ${CYAN}Importing current global Git config as '${name}':${NC}"
    echo -e "    ${DIM}user.name  = ${user_name}${NC}"
    echo -e "    ${DIM}user.email = ${user_email}${NC}"
    echo ""

    # Ask for SSH details
    read -p "  SSH Host (e.g., github.com): " ssh_host
    if [[ -z "$ssh_host" ]]; then
        ssh_host="github.com"
    fi

    read -p "  SSH HostName [${ssh_host}]: " ssh_hostname
    if [[ -z "$ssh_hostname" ]]; then
        ssh_hostname="$ssh_host"
    fi

    read -p "  SSH Key path [~/.ssh/id_ed25519]: " ssh_key
    if [[ -z "$ssh_key" ]]; then
        ssh_key="~/.ssh/id_ed25519"
    fi

    read -p "  SSH Port (leave empty for default): " ssh_port

    # Save profile
    cat > "$GUM_PROFILES_DIR/$name.conf" << EOF
GUM_USER_NAME="${user_name}"
GUM_USER_EMAIL="${user_email}"
GUM_SSH_HOST="${ssh_host}"
GUM_SSH_HOSTNAME="${ssh_hostname}"
GUM_SSH_KEY="${ssh_key}"
GUM_SSH_PORT="${ssh_port}"
EOF

    # Update SSH config
    local expanded_key=$(gum_expand_path "$ssh_key")
    gum_update_ssh_config "$name" "$ssh_host" "$ssh_hostname" "$expanded_key" "$ssh_port"

    echo ""
    echo -e "${GREEN}  ✓ Profile '${name}' imported successfully!${NC}"
    echo ""
}

# ============================================================================
# Command: help
# ============================================================================

gum_help() {
    echo ""
    echo -e "${BOLD}${PURPLE}  gum${NC} ${DIM}v${GUM_VERSION}${NC} - Git User Manager"
    echo ""
    echo -e "  ${BOLD}USAGE${NC}"
    echo -e "    gum <command> [options]"
    echo ""
    echo -e "  ${BOLD}COMMANDS${NC}"
    echo -e "    ${GREEN}init${NC}                   Quick setup (create work & home profiles)"
    echo -e "    ${GREEN}create${NC} <name>          Create a new Git identity profile"
    echo -e "    ${GREEN}list${NC} | ${GREEN}ls${NC}             List all profiles"
    echo -e "    ${GREEN}use${NC} <name> [--local]   Switch to a profile (global or local)"
    echo -e "    ${GREEN}current${NC}                Show current active profile"
    echo -e "    ${GREEN}show${NC} <name>            Show profile details"
    echo -e "    ${GREEN}delete${NC} | ${GREEN}rm${NC} <name>    Delete a profile"
    echo -e "    ${GREEN}import${NC} <name>          Import current git config as a profile"
    echo -e "    ${GREEN}config${NC} [show|edit|reset] View or edit gum configuration"
    echo -e "    ${GREEN}help${NC}                   Show this help message"
    echo -e "    ${GREEN}version${NC}                Show version"
    echo ""
    echo -e "  ${BOLD}EXAMPLES${NC}"
    echo -e "    ${DIM}# Quick start: create work & home profiles${NC}"
    echo -e "    gum init"
    echo ""
    echo -e "    ${DIM}# Or create profiles individually${NC}"
    echo -e "    gum create work"
    echo -e "    gum create home"
    echo ""
    echo -e "    ${DIM}# Switch to work identity (global)${NC}"
    echo -e "    gum use work"
    echo ""
    echo -e "    ${DIM}# Switch to home identity${NC}"
    echo -e "    gum use home"
    echo ""
    echo -e "    ${DIM}# Use home identity only in current repo${NC}"
    echo -e "    gum use home --local"
    echo ""
    echo -e "    ${DIM}# Customize default profile names${NC}"
    echo -e "    gum config edit"
    echo ""
    echo -e "  ${BOLD}FILES${NC}"
    echo -e "    ${DIM}~/.gum/config        User configuration (custom defaults)${NC}"
    echo -e "    ${DIM}~/.gum/profiles/     Profile configuration files${NC}"
    echo -e "    ${DIM}~/.gum/current       Current active profile name${NC}"
    echo -e "    ${DIM}~/.ssh/config        SSH configuration (managed blocks)${NC}"
    echo ""
}

# ============================================================================
# Command: version
# ============================================================================

gum_version() {
    echo -e "gum v${GUM_VERSION}"
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    local command="${1:-help}"
    shift 2>/dev/null || true

    case "$command" in
        init|setup)
            gum_init "$@"
            ;;
        create|new|add)
            gum_create "$@"
            ;;
        list|ls)
            gum_list "$@"
            ;;
        use|switch)
            gum_use "$@"
            ;;
        current|status)
            gum_current "$@"
            ;;
        show|info)
            gum_show "$@"
            ;;
        delete|rm|remove)
            gum_delete "$@"
            ;;
        import)
            gum_import "$@"
            ;;
        config|cfg)
            gum_config "$@"
            ;;
        help|--help|-h)
            gum_help
            ;;
        version|--version|-v|-V)
            gum_version
            ;;
        *)
            gum_error "Unknown command: ${command}"
            gum_help
            return 1
            ;;
    esac
}

main "$@"
