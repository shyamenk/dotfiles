# Additional Development Tools for Salesforce, AWS & Fullstack Development

## Salesforce Development Tools

### CLI Tools
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Salesforce CLI (sf)** | `npm install -g @salesforce/cli` | Official Salesforce CLI (replaces sfdx) |
| **SFDX Scanner** | `sf plugins install @salesforce/sfdx-scanner` | Code quality and security scanner |
| **Salesforce Functions** | `sf plugins install @salesforce/plugin-functions` | Serverless functions for SF |
| **Data Cloud** | `sf plugins install @salesforce/plugin-data` | Data Cloud CLI plugin |
| **Shane Plugins** | `sf plugins install shane-sfdx-plugins` | Community plugins by Shane McLaughlin |

### Development Tools
| Tool | Installation | Purpose |
|------|--------------|---------|
| **VS Code + Extensions** | Via script (already included) | Primary IDE |
| **Salesforce Extensions Pack** | VS Code extension | Official SF extension pack |
| **Prettier Apex** | `npm install -g prettier prettier-plugin-apex` | Code formatting for Apex |
| **ApexPMD** | Via SFDX Scanner | Static code analysis |
| **Illuminated Cloud** | IntelliJ plugin (optional) | Alternative to VS Code |

### Testing & Quality
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Jest** | `npm install -g jest @salesforce/sfdx-lwc-jest` | LWC unit testing |
| **Mocha** | `npm install -g mocha` | JS testing framework |
| **ESLint** | `npm install -g eslint` | JavaScript linting |
| **@salesforce/eslint-config-lwc** | `npm install -g @salesforce/eslint-config-lwc` | LWC-specific ESLint rules |

### Data Management
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Salesforce Data Loader** | Flatpak or AppImage | GUI data import/export |
| **CopyStorm** | Commercial tool | Backup and restore |
| **sfdx-hardis** | `sf plugins install sfdx-hardis` | DevOps automation |

### Productivity
| Tool | Installation | Purpose |
|------|--------------|---------|
| **sf-org-browser** | `sf plugins install @texei/sfa` | Browse org metadata |
| **Git Delta** | `dnf install git-delta` | Better git diffs |
| **Mermaid CLI** | `npm install -g @mermaid-js/mermaid-cli` | Generate diagrams from text |

## AWS Development Tools

### Core AWS CLI Tools
| Tool | Installation | Purpose |
|------|--------------|---------|
| **AWS CLI v2** | Already in script | Primary AWS CLI |
| **AWS SAM CLI** | `pip install aws-sam-cli` | Serverless application model |
| **AWS CDK** | `npm install -g aws-cdk` | Infrastructure as code |
| **AWS Amplify CLI** | `npm install -g @aws-amplify/cli` | Frontend/mobile backend |
| **AWS Copilot** | Via brew or manual | Container apps on ECS/Fargate |
| **eksctl** | Via script below | EKS cluster management |
| **AWS Vault** | Via script below | Secure credential storage |

### AWS Deployment & IaC
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Terraform** | Already in script | Infrastructure as code |
| **Terragrunt** | Via script below | Terraform wrapper |
| **Pulumi** | `curl -fsSL https://get.pulumi.com \| sh` | Modern IaC |
| **CloudFormation Linter** | `pip install cfn-lint` | Validate CloudFormation |
| **Troposphere** | `pip install troposphere` | CloudFormation in Python |

### AWS Monitoring & Management
| Tool | Installation | Purpose |
|------|--------------|---------|
| **aws-sso-util** | `pip install aws-sso-util` | AWS SSO helper |
| **aws-nuke** | Via GitHub releases | Clean up AWS resources |
| **Steampipe** | Via script below | Cloud asset inventory with SQL |
| **CloudWatch Logs Insights CLI** | Built into AWS CLI | Query logs |

### Container & Kubernetes Tools
| Tool | Installation | Purpose |
|------|--------------|---------|
| **kubectl** | Already in script | Kubernetes CLI |
| **k9s** | Already in script | Kubernetes TUI |
| **kubectx/kubens** | Via script below | Switch k8s contexts |
| **Helm** | Via script below | Kubernetes package manager |
| **Lens** | Flatpak or AppImage | Kubernetes IDE |
| **Dive** | Via script below | Docker image layer analysis |
| **ctop** | Via script below | Container metrics TUI |

## Fullstack Development Tools

### Frontend Development
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Vite** | `npm install -g vite` | Fast build tool |
| **Create React App** | `npm install -g create-react-app` | React scaffolding |
| **Vue CLI** | `npm install -g @vue/cli` | Vue.js development |
| **Angular CLI** | `npm install -g @angular/cli` | Angular development |
| **Next.js** | `npm install -g create-next-app` | React framework |
| **Nx** | `npm install -g nx` | Monorepo tool |
| **Turbo** | `npm install -g turbo` | High-performance build system |

### Backend Development
| Tool | Installation | Purpose |
|------|--------------|---------|
| **NestJS CLI** | `npm install -g @nestjs/cli` | Node.js framework |
| **Express Generator** | `npm install -g express-generator` | Express scaffolding |
| **FastAPI** | `pip install fastapi uvicorn` | Python web framework |
| **Django** | `pip install django` | Python web framework |
| **Poetry** | `curl -sSL https://install.python-poetry.org \| python3 -` | Python dependency management |

### Database Tools (TUI/CLI)
| Tool | Installation | Purpose |
|------|--------------|---------|
| **pgcli** | `pip install pgcli` | PostgreSQL TUI |
| **mycli** | `pip install mycli` | MySQL/MariaDB TUI |
| **litecli** | `pip install litecli` | SQLite TUI |
| **DBeaver** | Flatpak | Universal database GUI |
| **usql** | Via script below | Universal SQL CLI |
| **Redis CLI** | `dnf install redis` | Redis client |
| **MongoDB Compass** | Flatpak or download | MongoDB GUI |
| **mongosh** | Via MongoDB repo | MongoDB shell |

### API Development & Testing
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Bruno** | AppImage or build | API client (Postman alternative) |
| **HTTPie** | `pip install httpie` | Human-friendly HTTP CLI |
| **curlie** | Via script below | curl + httpie = curlie |
| **xh** | Via cargo: `cargo install xh` | Rust-based HTTP client |
| **Insomnia** | Flatpak | API client |
| **Hoppscotch** | Web-based | API testing |

### Code Quality & Formatting
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Prettier** | `npm install -g prettier` | Code formatter |
| **ESLint** | `npm install -g eslint` | JS/TS linting |
| **Ruff** | `pip install ruff` | Fast Python linter |
| **Black** | `pip install black` | Python formatter |
| **Pylint** | `pip install pylint` | Python linting |
| **shellcheck** | `dnf install ShellCheck` | Shell script linting |
| **shfmt** | Via script below | Shell script formatter |

### Version Control & Git Tools
| Tool | Installation | Purpose |
|------|--------------|---------|
| **GitHub CLI (gh)** | Already in script | GitHub from terminal |
| **GitLab CLI (glab)** | Via script below | GitLab from terminal |
| **LazyGit** | Already in script | Git TUI |
| **Tig** | `dnf install tig` | Text-mode Git interface |
| **Git-town** | Via script below | Git workflow tool |
| **Commitizen** | `npm install -g commitizen` | Conventional commits |
| **Husky** | `npm install -g husky` | Git hooks |

### Documentation & Diagramming
| Tool | Installation | Purpose |
|------|--------------|---------|
| **MkDocs** | `pip install mkdocs` | Documentation generator |
| **Docusaurus** | `npm install -g docusaurus` | Documentation sites |
| **VuePress** | `npm install -g vuepress` | Vue-powered docs |
| **Marksman** | Via script below | Markdown LSP server |
| **Glow** | `dnf install glow` | Render Markdown in terminal |
| **mdcat** | Via cargo: `cargo install mdcat` | Markdown viewer |

## TUI Applications (Terminal User Interface)

### System Monitoring
| Tool | Installation | Purpose |
|------|--------------|---------|
| **btop** | Already in script | Resource monitor |
| **htop** | Already in script | Process viewer |
| **nvtop** | Already in script | GPU monitor |
| **ctop** | Via script | Container metrics |
| **glances** | `pip install glances` | System monitoring |
| **bottom** | Via script | System monitor (Rust) |
| **bandwhich** | Via cargo: `cargo install bandwhich` | Network usage |

### File Management
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Yazi** | Via cargo (in script) | Modern file manager |
| **ranger** | `dnf install ranger` | File manager |
| **nnn** | `dnf install nnn` | Lightweight file manager |
| **lf** | Via script | Fast file manager |
| **Midnight Commander** | `dnf install mc` | Classic file manager |

### Text Editing & Processing
| Tool | Installation | Purpose |
|------|--------------|---------|
| **Neovim** | Already in script | Modern Vim |
| **Helix** | Via script | Modern modal editor |
| **micro** | `dnf install micro` | Easy terminal editor |
| **jq** | Already in script | JSON processor |
| **yq** | Via script | YAML processor |
| **fx** | `npm install -g fx` | JSON viewer |
| **Miller** | Via script | CSV/JSON/etc processor |

### Network & Security
| Tool | Installation | Purpose |
|------|--------------|---------|
| **nmap** | `dnf install nmap` | Network scanner |
| **wireshark** | `dnf install wireshark` | Packet analyzer |
| **tcpdump** | `dnf install tcpdump` | Network sniffer |
| **mtr** | `dnf install mtr` | Network diagnostic |
| **dog** | Via script | DNS client |
| **trippy** | Via cargo: `cargo install trippy` | Network traceroute |

### Productivity
| Tool | Installation | Purpose |
|------|--------------|---------|
| **taskwarrior** | `dnf install task` | Task management |
| **timewarrior** | `dnf install timew` | Time tracking |
| **calcurse** | `dnf install calcurse` | Calendar & scheduling |
| **vit** | `pip install vit` | Visual taskwarrior |
| **watson** | `pip install td-watson` | Time tracking |

### Development Helpers
| Tool | Installation | Purpose |
|------|--------------|---------|
| **tmux** | Already in script | Terminal multiplexer |
| **zellij** | Via script | Modern tmux alternative |
| **screen** | `dnf install screen` | Classic terminal multiplexer |
| **direnv** | `dnf install direnv` | Environment switcher |
| **asdf** | Via script | Version manager |
| **just** | Via cargo: `cargo install just` | Command runner |
| **mise** | Via script | Runtime version manager |

## Installation Scripts for Additional Tools

### eksctl (AWS EKS)
```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

### AWS Vault
```bash
curl -L -o /tmp/aws-vault https://github.com/99designs/aws-vault/releases/latest/download/aws-vault-linux-amd64
chmod +x /tmp/aws-vault
sudo mv /tmp/aws-vault /usr/local/bin/
```

### Terragrunt
```bash
curl -L -o /tmp/terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x /tmp/terragrunt
sudo mv /tmp/terragrunt /usr/local/bin/
```

### Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### kubectx & kubens
```bash
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

### Dive (Docker image explorer)
```bash
curl -L -o /tmp/dive.tar.gz https://github.com/wagoodman/dive/releases/latest/download/dive_$(uname -s)_amd64.tar.gz
tar -xzf /tmp/dive.tar.gz -C /tmp
sudo mv /tmp/dive /usr/local/bin/
```

### ctop (Container metrics)
```bash
sudo curl -L -o /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/latest/download/ctop-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64
sudo chmod +x /usr/local/bin/ctop
```

### Steampipe (Cloud asset inventory)
```bash
sudo /bin/sh -c "$(curl -fsSL https://steampipe.io/install/steampipe.sh)"
```

### usql (Universal SQL CLI)
```bash
curl -L -o /tmp/usql.tar.bz2 https://github.com/xo/usql/releases/latest/download/usql-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64.tar.bz2
tar -xjf /tmp/usql.tar.bz2 -C /tmp
sudo mv /tmp/usql /usr/local/bin/
```

### curlie (curl + httpie)
```bash
curl -L -o /tmp/curlie.tar.gz https://github.com/rs/curlie/releases/latest/download/curlie_$(uname -s)_amd64.tar.gz
tar -xzf /tmp/curlie.tar.gz -C /tmp
sudo mv /tmp/curlie /usr/local/bin/
```

### GitLab CLI (glab)
```bash
curl -L -o /tmp/glab.tar.gz https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_Linux_x86_64.tar.gz
tar -xzf /tmp/glab.tar.gz -C /tmp
sudo mv /tmp/bin/glab /usr/local/bin/
```

### shfmt (Shell formatter)
```bash
curl -L -o /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/latest/download/shfmt_$(uname -s | tr '[:upper:]' '[:lower:]')_amd64
sudo chmod +x /usr/local/bin/shfmt
```

### Marksman (Markdown LSP)
```bash
curl -L -o /tmp/marksman https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-x64
chmod +x /tmp/marksman
sudo mv /tmp/marksman /usr/local/bin/
```

### bottom (System monitor)
```bash
curl -L -o /tmp/bottom.tar.gz https://github.com/ClementTsang/bottom/releases/latest/download/bottom_x86_64-unknown-linux-gnu.tar.gz
tar -xzf /tmp/bottom.tar.gz -C /tmp
sudo mv /tmp/btm /usr/local/bin/
```

### lf (File manager)
```bash
curl -L -o /tmp/lf.tar.gz https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz
tar -xzf /tmp/lf.tar.gz -C /tmp
sudo mv /tmp/lf /usr/local/bin/
```

### Helix (Text editor)
```bash
curl -L -o /tmp/helix.tar.xz https://github.com/helix-editor/helix/releases/latest/download/helix-$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64.tar.xz
tar -xJf /tmp/helix.tar.xz -C /tmp
sudo mv /tmp/helix-*/hx /usr/local/bin/
sudo mv /tmp/helix-*/runtime /usr/local/share/helix
```

### yq (YAML processor)
```bash
curl -L -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### Miller (CSV/JSON processor)
```bash
curl -L -o /tmp/miller.tar.gz https://github.com/johnkerl/miller/releases/latest/download/miller-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64.tar.gz
tar -xzf /tmp/miller.tar.gz -C /tmp
sudo mv /tmp/mlr /usr/local/bin/
```

### dog (DNS client)
```bash
curl -L -o /tmp/dog.zip https://github.com/ogham/dog/releases/latest/download/dog-$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64.zip
unzip /tmp/dog.zip -d /tmp
sudo mv /tmp/bin/dog /usr/local/bin/
```

### zellij (tmux alternative)
```bash
curl -L -o /tmp/zellij.tar.gz https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xzf /tmp/zellij.tar.gz -C /tmp
sudo mv /tmp/zellij /usr/local/bin/
```

### asdf (Version manager)
```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

### mise (Runtime version manager)
```bash
curl https://mise.run | sh
```

## Recommended VS Code Extensions for Fullstack/Salesforce/AWS

### Salesforce
- Salesforce Extension Pack
- Salesforce CLI Integration
- ApexPMD
- Apex Log Analyzer
- Illuminated Cloud (if using IntelliJ)

### AWS
- AWS Toolkit
- CloudFormation Linter
- Terraform
- Docker

### General Development
- ESLint
- Prettier
- GitLens
- Thunder Client (API testing)
- Database Client
- REST Client
- Live Server
- Auto Rename Tag
- Bracket Pair Colorizer
- Path Intellisense
- Material Icon Theme

## Pro Tips

1. **Use toolbox/distrobox** for isolated development environments
2. **Install Node.js tools locally** via nvm in toolbox
3. **Use Docker** for databases instead of system packages
4. **Keep system clean** - install dev tools in containers when possible
5. **Backup your configs** - use dotfiles repo (you already do this!)
6. **Learn tmux/zellij** - essential for terminal productivity
7. **Master git** - lazygit is your friend
8. **Use k9s for Kubernetes** - way better than kubectl alone
9. **pgcli/mycli** for SQL - much better than native clients
10. **HTTPie/curlie** for API testing - more readable than curl
