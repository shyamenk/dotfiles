# Quick Reference Cheat Sheet

## 🚀 Common Commands

### System Management
```bash
# Update system
sudo dnf update -y

# Install package
sudo dnf install <package>

# Search package
dnf search <package>

# Remove package
sudo dnf remove <package>

# List installed
dnf list installed | grep <package>

# Clean cache
sudo dnf clean all
```

### Flatpak
```bash
# Update flatpaks
flatpak update

# Install app
flatpak install flathub <app-id>

# List installed
flatpak list

# Remove app
flatpak uninstall <app-id>
```

### NVIDIA
```bash
# Check GPU status
nvidia-smi

# Monitor GPU
watch -n 1 nvidia-smi

# Better GPU monitor
nvtop

# CUDA version
nvcc --version

# Test CUDA in Docker
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Docker
```bash
# Start service
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Run container
docker run -it ubuntu bash

# List containers
docker ps -a

# Remove all stopped
docker container prune

# Lazy Docker TUI
lazydocker
```

### Hyprland
```bash
# Start Hyprland
Hyprland

# Kill Hyprland
killall Hyprland

# Reload config
Super + Shift + R

# Logs
cat ~/.local/share/hyprland/hyprland.log

# Edit config
nvim ~/.config/hypr/hyprland.conf
```

### Dotfiles
```bash
# Pull latest
cd ~/dotfiles && git pull

# Re-stow all
cd ~/dotfiles
for dir in */; do stow -R "${dir%/}"; done

# Stow specific
cd ~/dotfiles
stow -R nvim

# Unstow
stow -D nvim

# Check conflicts
stow -n -v nvim
```

## 🔧 Development Tools

### Salesforce CLI
```bash
# Version
sf --version

# Login
sf org login web

# Set default org
sf config set target-org <alias>

# List orgs
sf org list

# Retrieve metadata
sf project retrieve start -m ApexClass:MyClass

# Deploy
sf project deploy start -d force-app

# Run tests
sf apex run test -t MyTestClass -r human

# Query
sf data query -q "SELECT Id, Name FROM Account LIMIT 10"

# Open org
sf org open

# Create scratch org
sf org create scratch -f config/project-scratch-def.json -a MyScratch

# Push source
sf project deploy start

# Pull changes
sf project retrieve start
```

### AWS CLI
```bash
# Version
aws --version

# Configure
aws configure

# SSO login
aws sso login --profile <profile>

# List S3 buckets
aws s3 ls

# EC2 instances
aws ec2 describe-instances

# Lambda functions
aws lambda list-functions

# CloudWatch logs
aws logs tail /aws/lambda/<function-name> --follow

# SAM
sam init
sam build
sam deploy

# CDK
cdk init app --language typescript
cdk synth
cdk deploy
```

### Kubernetes
```bash
# Get contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context>

# Or use kubectx
kubectx <context>

# Switch namespace
kubens <namespace>

# Get pods
kubectl get pods

# Describe pod
kubectl describe pod <pod-name>

# Logs
kubectl logs -f <pod-name>

# Execute command
kubectl exec -it <pod-name> -- bash

# K9s TUI
k9s
```

### Git
```bash
# Lazy Git TUI
lazygit

# Git with better diffs
git diff  # Uses delta from config

# GitHub CLI
gh auth login
gh repo create
gh pr create
gh issue list

# GitLab CLI
glab auth login
glab mr create
```

### Node.js (nvm)
```bash
# List installed versions
nvm list

# Install version
nvm install 20
nvm install --lts

# Use version
nvm use 20
nvm use --lts

# Set default
nvm alias default 20

# Current version
node --version
npm --version

# Update npm
npm install -g npm@latest
```

### Python
```bash
# uv (fast package manager)
uv pip install <package>
uv pip list
uv venv

# pyenv (version manager)
pyenv install 3.12.0
pyenv global 3.12.0
pyenv local 3.12.0

# Virtual environment
python -m venv venv
source venv/bin/activate
deactivate
```

### Databases
```bash
# PostgreSQL TUI
pgcli postgresql://user:pass@host:5432/database

# MySQL TUI
mycli -u user -p -h host database

# SQLite TUI
litecli database.db

# Universal SQL
usql postgres://user@host/db
usql mysql://user@host/db
usql sqlite:database.db

# MongoDB
mongosh "mongodb://localhost:27017/mydb"

# Redis
redis-cli
```

### API Testing
```bash
# HTTPie
http GET https://api.example.com/users
http POST https://api.example.com/users name=John

# curlie (curl + httpie)
curlie https://api.example.com/users

# xh (Rust HTTP)
xh get https://api.example.com/users
```

## 📦 Container Development

### Toolbox
```bash
# Create container
toolbox create <name>
toolbox create -i fedora:39 dev

# List containers
toolbox list

# Enter container
toolbox enter <name>

# Run command
toolbox run -c <name> <command>

# Remove container
toolbox rm <name>
```

### Distrobox
```bash
# Create container
distrobox create --name ubuntu-dev --image ubuntu:22.04

# Enter container
distrobox enter ubuntu-dev

# List containers
distrobox list

# Export app to host
distrobox-export --app <app-name>

# Remove container
distrobox rm ubuntu-dev
```

## 🎨 Wayland/Hyprland

### Screenshots
```bash
# Full screen
grim ~/Pictures/screenshot.png

# Select area
grim -g "$(slurp)" ~/Pictures/screenshot.png

# Copy to clipboard
grim -g "$(slurp)" - | wl-copy
```

### Screen Recording
```bash
# Record area
wf-recorder -g "$(slurp)" -f recording.mp4

# Stop recording
killall wf-recorder
```

### Clipboard
```bash
# Copy
wl-copy < file.txt
echo "text" | wl-copy

# Paste
wl-paste > file.txt

# Clipboard history (cliphist)
cliphist list
cliphist decode | wl-copy
```

### Color Picker
```bash
# Pick color
hyprpicker -a  # Auto copy to clipboard
```

## 🔍 System Monitoring

### Process Monitoring
```bash
# htop (interactive)
htop

# btop (better)
btop

# bottom (Rust)
btm

# top (basic)
top
```

### GPU Monitoring
```bash
# NVIDIA
nvidia-smi
watch -n 1 nvidia-smi

# nvtop (better)
nvtop
```

### Container Monitoring
```bash
# Docker stats
docker stats

# ctop (container top)
ctop

# lazydocker (TUI)
lazydocker
```

### Network Monitoring
```bash
# Bandwidth usage
bandwhich

# Network connections
ss -tuln

# MTR (traceroute + ping)
mtr google.com

# DNS query
dog google.com
```

## 📝 File Management

### Yazi (TUI file manager)
```bash
# Start
yazi

# Navigate: hjkl or arrows
# Open: Enter
# Back: Backspace
# Quit: q
```

### Other File Managers
```bash
# Ranger
ranger

# nnn
nnn

# lf
lf

# Midnight Commander
mc

# Thunar (GUI)
thunar
```

## ✏️ Text Editing

### Neovim
```bash
# Edit file
nvim file.txt

# Multiple files
nvim file1.txt file2.txt

# With config
nvim -u ~/.config/nvim/init.lua
```

### Helix
```bash
# Edit file
hx file.txt

# Multiple files
hx file1.txt file2.txt
```

### Micro
```bash
# Edit file
micro file.txt
```

## 🔐 SSH & Security

### SSH
```bash
# Generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to server
ssh-copy-id user@host

# Config
nvim ~/.ssh/config

# GitHub
ssh -T git@github.com
```

### AWS Vault
```bash
# Add credentials
aws-vault add <profile>

# Execute with credentials
aws-vault exec <profile> -- aws s3 ls

# Login
aws-vault login <profile>
```

## 🛠️ Productivity

### Tmux
```bash
# New session
tmux new -s <session-name>

# Attach
tmux attach -t <session-name>

# List sessions
tmux ls

# Kill session
tmux kill-session -t <session-name>

# Prefix: Ctrl+b (default)
# Vertical split: Ctrl+b %
# Horizontal split: Ctrl+b "
# Switch pane: Ctrl+b arrow
# New window: Ctrl+b c
# Switch window: Ctrl+b n/p
```

### Zellij (tmux alternative)
```bash
# Start
zellij

# Attach
zellij attach

# List sessions
zellij list-sessions

# Quit: Ctrl+q
```

### Task Management
```bash
# Taskwarrior
task add "Buy groceries"
task list
task 1 done

# Timewarrior
timew start "Working on project"
timew stop
timew summary
```

## 🎯 Quick Fixes

### Fix NVIDIA
```bash
sudo dnf reinstall akmod-nvidia
sudo dracut --force
sudo reboot
```

### Fix Hyprland
```bash
# From TTY (Ctrl+Alt+F3)
killall Hyprland
Hyprland
```

### Fix Docker Permissions
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Fix Node/npm
```bash
nvm install --lts
nvm use --lts
npm config get prefix  # Should be in ~/.nvm
```

### Reset Dotfiles
```bash
cd ~/dotfiles
git reset --hard origin/main
git pull
stow -R */
```

### Clear Package Cache
```bash
sudo dnf clean all
sudo dnf makecache
```

## 📚 Documentation

### Man Pages
```bash
man <command>
man -k <search>
```

### TLDR (simplified man)
```bash
# Install
npm install -g tldr

# Use
tldr <command>
```

### Help
```bash
<command> --help
<command> -h
```

## 🔄 Service Management

### Systemd
```bash
# Status
systemctl status <service>

# Start
sudo systemctl start <service>

# Stop
sudo systemctl stop <service>

# Enable
sudo systemctl enable <service>

# Restart
sudo systemctl restart <service>

# Logs
journalctl -u <service> -f
```

### User Services
```bash
# Status
systemctl --user status <service>

# Same commands as above, add --user
```

## 💡 Pro Tips

1. **Use aliases in ~/.zshrc**
   ```bash
   alias ll='eza -la'
   alias gs='git status'
   alias dc='docker-compose'
   alias k='kubectl'
   ```

2. **Use fzf for fuzzy finding**
   ```bash
   # Search command history
   Ctrl+R
   
   # Search files
   nvim $(fzf)
   ```

3. **Use z/zoxide for directory jumping**
   ```bash
   z <partial-dir-name>
   zi  # Interactive
   ```

4. **Use bat instead of cat**
   ```bash
   bat file.txt  # Syntax highlighting
   ```

5. **Use ripgrep instead of grep**
   ```bash
   rg <pattern>  # Much faster
   ```

6. **Use fd instead of find**
   ```bash
   fd <pattern>  # Simpler syntax
   ```

7. **Use delta for git diffs**
   ```bash
   git diff  # Beautiful diffs
   ```

8. **Use starship prompt**
   - Already configured
   - Shows git status, languages, etc.

9. **Learn tmux/zellij**
   - Essential for terminal productivity
   - Run multiple terminals in one

10. **Use containers for dev**
    - Keep system clean
    - Isolated environments
    - Easy to reset

---

**Print this and keep it handy!** 📋
