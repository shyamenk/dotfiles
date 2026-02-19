#!/bin/bash
# ===========================================================================
# Additional Development Tools Installation Script
# For Salesforce, AWS, Fullstack Development
# ===========================================================================

set -o pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUCCESSFUL=()
FAILED=()
SKIPPED=()

log() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[-] $1${NC}" >&2; }

echo -e "${BLUE}=====================================================================
       ADDITIONAL DEVELOPMENT TOOLS INSTALLATION
=====================================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    error "Run with sudo"
    exit 1
fi

REGULAR_USER="${SUDO_USER:-$(logname 2>/dev/null)}"
if [ -z "$REGULAR_USER" ] || [ "$REGULAR_USER" = "root" ]; then
    error "Cannot determine regular user. Run with: sudo ./install-dev-tools.sh"
    exit 1
fi
USER_HOME=$(getent passwd "$REGULAR_USER" | cut -d: -f6)

log "Installing for user: $REGULAR_USER ($USER_HOME)"

# ============================================================================
# PHASE 1: Python-based Tools
# ============================================================================
log "PHASE 1: Installing Python-based tools..."

PYTHON_TOOLS=(
    pgcli          # PostgreSQL TUI
    mycli          # MySQL TUI
    litecli        # SQLite TUI
    httpie         # HTTP client
    glances        # System monitor
    black          # Python formatter
    ruff           # Python linter
    pylint         # Python linter
    ipython        # Enhanced Python shell
    poetry         # Dependency management
    pipenv         # Virtual environments
    vit            # Visual taskwarrior
    td-watson      # Time tracking
    mkdocs         # Documentation
    cfn-lint       # CloudFormation linter
    troposphere    # CloudFormation in Python
    fastapi        # Web framework
    uvicorn        # ASGI server
)

for tool in "${PYTHON_TOOLS[@]}"; do
    if command -v "${tool}" &>/dev/null; then
        SKIPPED+=("${tool} - already installed")
    else
        pip3 install --user "${tool}" && \
            SUCCESSFUL+=("${tool}") || FAILED+=("${tool}")
    fi
done

# AWS SAM CLI
if ! command -v sam &>/dev/null; then
    pip3 install --user aws-sam-cli && \
        SUCCESSFUL+=("AWS SAM CLI") || FAILED+=("AWS SAM CLI")
else
    SKIPPED+=("AWS SAM CLI - already installed")
fi

# ============================================================================
# PHASE 2: Node.js/npm Global Tools
# ============================================================================
log "PHASE 2: Installing Node.js global tools..."

# Check if nvm/node is available
if command -v node &>/dev/null; then
    NPM_TOOLS=(
        "@salesforce/cli"                    # Salesforce CLI
        prettier                              # Code formatter
        "prettier-plugin-apex"               # Apex formatting
        eslint                                # JS linting
        "@salesforce/eslint-config-lwc"      # LWC ESLint
        jest                                  # Testing
        "@salesforce/sfdx-lwc-jest"          # LWC Jest
        mocha                                 # Testing
        "@mermaid-js/mermaid-cli"            # Diagrams
        aws-cdk                               # AWS CDK
        "@aws-amplify/cli"                   # AWS Amplify
        vite                                  # Build tool
        "@nestjs/cli"                        # NestJS
        express-generator                     # Express
        "@vue/cli"                           # Vue CLI
        "@angular/cli"                       # Angular CLI
        create-next-app                       # Next.js
        nx                                    # Monorepo
        turbo                                 # Build system
        fx                                    # JSON viewer
        commitizen                            # Conventional commits
        husky                                 # Git hooks
        docusaurus                            # Documentation
        vuepress                              # Documentation
    )
    
    for tool in "${NPM_TOOLS[@]}"; do
        sudo -u "$REGULAR_USER" npm list -g "${tool}" &>/dev/null
        if [ $? -eq 0 ]; then
            SKIPPED+=("npm: ${tool} - already installed")
        else
            sudo -u "$REGULAR_USER" npm install -g "${tool}" && \
                SUCCESSFUL+=("npm: ${tool}") || FAILED+=("npm: ${tool}")
        fi
    done
    
    # Install Salesforce CLI plugins
    if command -v sf &>/dev/null; then
        SALESFORCE_PLUGINS=(
            "@salesforce/sfdx-scanner"
            "@salesforce/plugin-functions"
            "@salesforce/plugin-data"
            "sfdx-hardis"
            "@texei/sfa"
        )
        
        for plugin in "${SALESFORCE_PLUGINS[@]}"; do
            sudo -u "$REGULAR_USER" sf plugins install "${plugin}" 2>/dev/null && \
                SUCCESSFUL+=("SF plugin: ${plugin}") || warn "SF plugin ${plugin} failed"
        done
    fi
else
    warn "Node.js not found - skipping npm tools. Install nvm first!"
fi

# ============================================================================
# PHASE 3: Cargo/Rust Tools
# ============================================================================
log "PHASE 3: Installing Rust/Cargo tools..."

if command -v cargo &>/dev/null; then
    CARGO_TOOLS=(
        xh           # HTTP client
        mdcat        # Markdown viewer
        bandwhich    # Network usage monitor
        trippy       # Network traceroute
        just         # Command runner
    )
    
    for tool in "${CARGO_TOOLS[@]}"; do
        if command -v "${tool}" &>/dev/null; then
            SKIPPED+=("${tool} - already installed")
        else
            sudo -u "$REGULAR_USER" cargo install --locked "${tool}" 2>/dev/null && \
                SUCCESSFUL+=("${tool}") || FAILED+=("${tool}")
        fi
    done
else
    warn "Cargo not found - skipping Rust tools"
fi

# ============================================================================
# PHASE 4: Binary Downloads
# ============================================================================
log "PHASE 4: Installing binary tools..."

# AWS Vault
if ! command -v aws-vault &>/dev/null; then
    curl -L -o /usr/local/bin/aws-vault https://github.com/99designs/aws-vault/releases/latest/download/aws-vault-linux-amd64
    chmod +x /usr/local/bin/aws-vault
    SUCCESSFUL+=("aws-vault")
else
    SKIPPED+=("aws-vault - already installed")
fi

# Dive
if ! command -v dive &>/dev/null; then
    curl -L -o /tmp/dive.tar.gz https://github.com/wagoodman/dive/releases/latest/download/dive_$(uname -s)_amd64.tar.gz
    tar -xzf /tmp/dive.tar.gz -C /tmp
    mv /tmp/dive /usr/local/bin/
    chmod +x /usr/local/bin/dive
    rm /tmp/dive.tar.gz
    SUCCESSFUL+=("dive")
else
    SKIPPED+=("dive - already installed")
fi

# ctop
if ! command -v ctop &>/dev/null; then
    curl -L -o /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/latest/download/ctop-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64
    chmod +x /usr/local/bin/ctop
    SUCCESSFUL+=("ctop")
else
    SKIPPED+=("ctop - already installed")
fi

# Steampipe
if ! command -v steampipe &>/dev/null; then
    /bin/sh -c "$(curl -fsSL https://steampipe.io/install/steampipe.sh)"
    SUCCESSFUL+=("steampipe")
else
    SKIPPED+=("steampipe - already installed")
fi

# usql
if ! command -v usql &>/dev/null; then
    curl -L -o /tmp/usql.tar.bz2 https://github.com/xo/usql/releases/latest/download/usql-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64.tar.bz2
    tar -xjf /tmp/usql.tar.bz2 -C /tmp
    mv /tmp/usql /usr/local/bin/
    chmod +x /usr/local/bin/usql
    rm /tmp/usql.tar.bz2
    SUCCESSFUL+=("usql")
else
    SKIPPED+=("usql - already installed")
fi

# curlie
if ! command -v curlie &>/dev/null; then
    curl -L -o /tmp/curlie.tar.gz https://github.com/rs/curlie/releases/latest/download/curlie_$(uname -s)_amd64.tar.gz
    tar -xzf /tmp/curlie.tar.gz -C /tmp
    mv /tmp/curlie /usr/local/bin/
    chmod +x /usr/local/bin/curlie
    rm /tmp/curlie.tar.gz
    SUCCESSFUL+=("curlie")
else
    SKIPPED+=("curlie - already installed")
fi

# GitLab CLI (glab)
if ! command -v glab &>/dev/null; then
    curl -L -o /tmp/glab.tar.gz https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_Linux_x86_64.tar.gz
    tar -xzf /tmp/glab.tar.gz -C /tmp
    mv /tmp/bin/glab /usr/local/bin/
    chmod +x /usr/local/bin/glab
    rm -rf /tmp/glab.tar.gz /tmp/bin
    SUCCESSFUL+=("glab")
else
    SKIPPED+=("glab - already installed")
fi

# shfmt
if ! command -v shfmt &>/dev/null; then
    curl -L -o /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/latest/download/shfmt_$(uname -s | tr '[:upper:]' '[:lower:]')_amd64
    chmod +x /usr/local/bin/shfmt
    SUCCESSFUL+=("shfmt")
else
    SKIPPED+=("shfmt - already installed")
fi

# Marksman (Markdown LSP)
if ! command -v marksman &>/dev/null; then
    curl -L -o /usr/local/bin/marksman https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-x64
    chmod +x /usr/local/bin/marksman
    SUCCESSFUL+=("marksman")
else
    SKIPPED+=("marksman - already installed")
fi

# bottom (btm)
if ! command -v btm &>/dev/null; then
    curl -L -o /tmp/bottom.tar.gz https://github.com/ClementTsang/bottom/releases/latest/download/bottom_x86_64-unknown-linux-gnu.tar.gz
    tar -xzf /tmp/bottom.tar.gz -C /tmp
    mv /tmp/btm /usr/local/bin/
    chmod +x /usr/local/bin/btm
    rm /tmp/bottom.tar.gz
    SUCCESSFUL+=("bottom")
else
    SKIPPED+=("bottom - already installed")
fi

# lf (file manager)
if ! command -v lf &>/dev/null; then
    curl -L -o /tmp/lf.tar.gz https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz
    tar -xzf /tmp/lf.tar.gz -C /tmp
    mv /tmp/lf /usr/local/bin/
    chmod +x /usr/local/bin/lf
    rm /tmp/lf.tar.gz
    SUCCESSFUL+=("lf")
else
    SKIPPED+=("lf - already installed")
fi

# Helix editor
if ! command -v hx &>/dev/null; then
    curl -L -o /tmp/helix.tar.xz https://github.com/helix-editor/helix/releases/latest/download/helix-$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64.tar.xz
    tar -xJf /tmp/helix.tar.xz -C /tmp
    HELIX_DIR=$(find /tmp -maxdepth 1 -type d -name "helix-*" | head -n1)
    mv "${HELIX_DIR}/hx" /usr/local/bin/
    mkdir -p /usr/local/share/helix
    mv "${HELIX_DIR}/runtime" /usr/local/share/helix/
    chmod +x /usr/local/bin/hx
    rm -rf /tmp/helix* "${HELIX_DIR}"
    SUCCESSFUL+=("helix")
else
    SKIPPED+=("helix - already installed")
fi

# yq
if ! command -v yq &>/dev/null; then
    curl -L -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    chmod +x /usr/local/bin/yq
    SUCCESSFUL+=("yq")
else
    SKIPPED+=("yq - already installed")
fi

# Miller (mlr)
if ! command -v mlr &>/dev/null; then
    curl -L -o /tmp/miller.tar.gz https://github.com/johnkerl/miller/releases/latest/download/miller-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64.tar.gz
    tar -xzf /tmp/miller.tar.gz -C /tmp
    mv /tmp/mlr /usr/local/bin/
    chmod +x /usr/local/bin/mlr
    rm /tmp/miller.tar.gz
    SUCCESSFUL+=("miller")
else
    SKIPPED+=("miller - already installed")
fi

# dog (DNS)
if ! command -v dog &>/dev/null; then
    curl -L -o /tmp/dog.zip https://github.com/ogham/dog/releases/latest/download/dog-$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64.zip
    unzip -q /tmp/dog.zip -d /tmp
    mv /tmp/bin/dog /usr/local/bin/
    chmod +x /usr/local/bin/dog
    rm -rf /tmp/dog.zip /tmp/bin
    SUCCESSFUL+=("dog")
else
    SKIPPED+=("dog - already installed")
fi

# zellij
if ! command -v zellij &>/dev/null; then
    curl -L -o /tmp/zellij.tar.gz https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
    tar -xzf /tmp/zellij.tar.gz -C /tmp
    mv /tmp/zellij /usr/local/bin/
    chmod +x /usr/local/bin/zellij
    rm /tmp/zellij.tar.gz
    SUCCESSFUL+=("zellij")
else
    SKIPPED+=("zellij - already installed")
fi

# Pulumi
if ! command -v pulumi &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl -fsSL https://get.pulumi.com | sh'
    SUCCESSFUL+=("pulumi")
else
    SKIPPED+=("pulumi - already installed")
fi

# ============================================================================
# PHASE 5: Git Clone Tools
# ============================================================================
log "PHASE 5: Installing Git-based tools..."

# asdf
if [ ! -d "$USER_HOME/.asdf" ]; then
    sudo -u "$REGULAR_USER" git clone https://github.com/asdf-vm/asdf.git "$USER_HOME/.asdf" --branch v0.14.0
    SUCCESSFUL+=("asdf")
else
    SKIPPED+=("asdf - already installed")
fi

# mise
if ! command -v mise &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl https://mise.run | sh'
    SUCCESSFUL+=("mise")
else
    SKIPPED+=("mise - already installed")
fi

# ============================================================================
# PHASE 6: DNF Additional Tools
# ============================================================================
log "PHASE 6: Installing additional DNF packages..."

ADDITIONAL_DNF_PKGS=(
    ranger         # File manager
    nnn            # File manager
    mc             # Midnight Commander
    micro          # Text editor
    tig            # Git interface
    nmap           # Network scanner
    wireshark      # Packet analyzer
    tcpdump        # Network sniffer
    mtr            # Network diagnostic
    task           # Taskwarrior
    timew          # Timewarrior
    calcurse       # Calendar
    screen         # Terminal multiplexer
    direnv         # Environment switcher
    ShellCheck     # Shell script linter
    redis          # Redis CLI
    glow           # Markdown renderer
    pinta          # Image editor
)

for pkg in "${ADDITIONAL_DNF_PKGS[@]}"; do
    if dnf list installed "$pkg" &>/dev/null; then
        SKIPPED+=("$pkg - already installed")
    else
        dnf install -y "$pkg" && \
            SUCCESSFUL+=("$pkg") || FAILED+=("$pkg")
    fi
done

# MongoDB Shell
if ! command -v mongosh &>/dev/null; then
    cat > /etc/yum.repos.d/mongodb-org-7.0.repo << 'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF
    dnf install -y mongodb-mongosh && \
        SUCCESSFUL+=("mongosh") || FAILED+=("mongosh")
else
    SKIPPED+=("mongosh - already installed")
fi

# ============================================================================
# FINAL REPORT
# ============================================================================
echo
echo -e "${BLUE}=====================================================================
                    INSTALLATION REPORT
=====================================================================${NC}"

echo -e "\n${GREEN}✓ Successful (${#SUCCESSFUL[@]}):${NC}"
for item in "${SUCCESSFUL[@]}"; do echo -e "  ${GREEN}✓${NC} $item"; done

echo -e "\n${YELLOW}⚠ Skipped (${#SKIPPED[@]}):${NC}"
for item in "${SKIPPED[@]}"; do echo -e "  ${YELLOW}⚠${NC} $item"; done

echo -e "\n${RED}✗ Failed (${#FAILED[@]}):${NC}"
for item in "${FAILED[@]}"; do echo -e "  ${RED}✗${NC} $item"; done

LOG_FILE="/var/log/dev-tools-$(date +%Y%m%d-%H%M%S).log"
{
    echo "Dev Tools Setup Report - $(date)"
    echo "Successful: ${SUCCESSFUL[*]}"
    echo "Skipped: ${SKIPPED[*]}"
    echo "Failed: ${FAILED[*]}"
} > "$LOG_FILE"

echo
echo -e "${YELLOW}POST-INSTALL:${NC}"
echo "  1. Restart shell to use new tools"
echo "  2. Configure Salesforce CLI: sf config set"
echo "  3. Configure AWS CLI: aws configure"
echo "  4. Test tools: sf --version, aws --version"
echo
log "Setup complete! Report: $LOG_FILE"
