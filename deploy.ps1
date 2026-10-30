# Upload pi-web source to 172.168.2.40 over SSH (upload only, no remote build/start).
#
# Uses the built-in OpenSSH (ssh / scp). The SSH password is entered at the prompt
# (not collected by this script). Connection multiplexing (ControlMaster) is intentionally
# disabled because it triggers a "getsockname failed: Not a socket" bug on Windows OpenSSH;
# you will be prompted for the password on each ssh/scp call. For a password-free run, set up
# SSH keys (ssh-keygen + ssh-copy-id) - the script then works without any prompt.
#
# Prereqs:
#   - Windows 10/11 has OpenSSH client built in. If missing, add "OpenSSH Client" in Optional Features.
#   - The deploy directory's parent must be creatable/writable by the SSH user.
#
# Run from the project root (D:\05.BYG\pi-web): .\deploy.ps1

param(
  [string]$HostIp = "172.168.2.41"
)

# Preflight: built-in OpenSSH
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
  Write-Error "ssh not found. Install the OpenSSH client (Windows Optional Features) or put ssh.exe on PATH."
  exit 1
}
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
  Write-Error "scp not found."
  exit 1
}

# Collect parameters (password is handled by the ssh/scp prompt)
$user = Read-Host "Target server username"
$deployDir = Read-Host "Remote deploy directory (default: /home/kaka/byg-web)"
if ([string]::IsNullOrWhiteSpace($deployDir)) { $deployDir = "/home/kaka/byg-web" }
while (-not ($deployDir -match '^/')) {
  $deployDir = Read-Host "Deploy directory must be absolute (start with /), try again"
}

$target = "$user@$HostIp"

# Stage source locally (exclude node_modules/.next/.git and this script)
Write-Host "==> Staging source (excluding node_modules/.next/.git)..." -ForegroundColor Cyan
$leaf = Split-Path $deployDir -Leaf
$staging = Join-Path $env:TEMP $leaf
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null
robocopy . $staging /E /XD node_modules .next .git /XF deploy.ps1 deploy-remote.sh .env .env.* *.log 2>$null | Out-Null

# Ensure parent exists, is writable, and clear any previous deploy (so re-runs don't nest)
$parentDir = Split-Path $deployDir
Write-Host "==> Connecting to $target (enter password, and accept the host key if prompted)..." -ForegroundColor Cyan
ssh $target "mkdir -p '$parentDir' && test -w '$parentDir' && rm -rf '$deployDir'"
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to prepare '$deployDir' on the server. Check: (1) SSH connection/network; (2) the parent '$parentDir' must be creatable and writable by user '$user'. Non-root users should deploy under their home, e.g. /home/$user/byg-web (or create the directory as root first)."
  exit 1
}

Write-Host "==> Uploading source to $target : $deployDir ..." -ForegroundColor Cyan
scp -r "$staging" "${target}:${parentDir}"
if ($LASTEXITCODE -ne 0) { Write-Error "Upload failed (exit $LASTEXITCODE)"; exit 1 }

Write-Host "==> Upload complete. Files are at $target : $deployDir" -ForegroundColor Green
