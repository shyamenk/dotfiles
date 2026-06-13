# Secrets & Credentials Checklist

Run through this after `setup.sh` completes. Everything uses `pass` as the store.

## 1. GPG Key (required first — unlocks `pass`)

```bash
# Export from old machine
gpg --export-secret-keys --armor YOUR_KEY_ID > gpg-private.asc

# Import on new machine
gpg --import gpg-private.asc
gpg --edit-key YOUR_KEY_ID  # then: trust → 5 → quit

# Restore pass store
git clone git@github.com:shyamenk/pass-store.git ~/.password-store
```

## 2. SSH Keys

```bash
ssh-keygen -t ed25519 -C "shyamenk@gmail.com"
cat ~/.ssh/id_ed25519.pub   # add to GitHub → Settings → SSH keys
gh auth login               # authenticates gh CLI
```

## 3. Gmail App Password (automations)

Used by `oci-hourly-report.py` and `daily-digest.py` via `pass gmail/app-password`.

```bash
# Generate at: https://myaccount.google.com/apppasswords
pass insert gmail/app-password
```

## 4. GitHub CLI

```bash
gh auth login   # follow prompts — stores token in system keyring
```

## 5. AWS CLI Profiles

Config lives at `~/.aws/` — restore from `config/credentials/` backup.

```bash
# Profiles needed:
#   default       — personal
#   xed-staging   — XED staging account
#   xed-prod      — XED production account
mkdir -p ~/.aws
cp /path/to/backup/.aws/credentials ~/.aws/credentials
cp /path/to/backup/.aws/config ~/.aws/config
chmod 600 ~/.aws/credentials
```

## 6. rclone (Google Drive)

```bash
rclone config   # create remote named "gdrive", type: drive
# After config:
systemctl --user start rclone-gdrive.service
systemctl --user status rclone-gdrive.service
ls ~/gdrive     # should show Drive contents
```

## 7. Atuin (shell history sync)

```bash
atuin login     # enter atuin account credentials
atuin sync      # pull history from server
```

## 8. Docker Hub (optional)

```bash
docker login    # enter Docker Hub credentials
```

## 9. OCI (Oracle Cloud — if retrying ARM instance)

Config lives at `~/.oci/config` — restore from backup.

```bash
mkdir -p ~/.oci
cp /path/to/backup/oci/config ~/.oci/config
cp /path/to/backup/oci/private-key.pem ~/.oci/
chmod 600 ~/.oci/config ~/.oci/private-key.pem
```

---

## Verification

```bash
pass ls                          # GPG + pass working
ssh -T git@github.com            # SSH to GitHub
gh auth status                   # gh CLI
aws sts get-caller-identity      # AWS default profile
rclone lsd gdrive:               # rclone gdrive
atuin history list | tail -5     # atuin sync
```
