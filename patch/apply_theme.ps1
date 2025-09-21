
# apply_theme.ps1 — drops in a modern style.css and backs up the old one.
$ErrorActionPreference = "Stop"

# Adjust if your stylesheet lives elsewhere:
$cssPath = "assets/style.css"

if (-not (Test-Path $cssPath)) {
  throw "Could not find $cssPath. Edit apply_theme.ps1 and set `$cssPath to your stylesheet path."
}

$backup = "$cssPath.bak"
if (-not (Test-Path $backup)) {
  Copy-Item -LiteralPath $cssPath -Destination $backup
  Write-Host "Backup created: $backup"
} else {
  Write-Host "Backup already exists: $backup"
}

Copy-Item -LiteralPath ".\patch\style.css" -Destination $cssPath -Force
Write-Host "Theme applied to $cssPath"

# Optional: Inject minimal helper classes if not present (no-op if files missing)
$pages = @("index.html", "projects\basic-log-monitoring.html", "projects\password-manager.html",
           "projects\phishing-email-analysis.html", "projects\secure-network-lab.html",
           "projects\vulnerability-scan.html")
foreach ($p in $pages) {
  if (Test-Path $p) {
    # Ensure main container has class 'container' (best-effort, conservative)
    $html = Get-Content -Raw -LiteralPath $p
    if ($html -match "<body[^>]*>\s*<div(?![^>]*class=).*?>") {
      $html = [regex]::Replace($html, "<body([^>]*)>\s*<div(?![^>]*class=)([^>]*)>", '<body$1><div class="container"$2>', 1, "Singleline")
      Set-Content -LiteralPath $p -Value $html -Encoding UTF8
      Write-Host "Added container class to: $p"
    }
  }
}

Write-Host "All done. Review locally, then push."
