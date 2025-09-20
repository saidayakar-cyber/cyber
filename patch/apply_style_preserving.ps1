
# apply_style_preserving.ps1
$ErrorActionPreference = "Stop"

function Backup-Once($p) {
  $bak = "$p.bak"
  if (-not (Test-Path $bak)) { Copy-Item -LiteralPath $p -Destination $bak }
}

# Files
$projectFiles = @(
  "projects/basic-log-monitoring.html",
  "projects/password-manager.html",
  "projects/phishing-email-analysis.html",
  "projects/secure-network-lab.html",
  "projects/vulnerability-scan.html"
)

# 1) Remove “Documentation” bullet from Outcomes
foreach ($f in $projectFiles) {
  if (-not (Test-Path $f)) { Write-Host "Skip (not found): $f"; continue }
  Backup-Once $f
  $html = Get-Content -Raw -LiteralPath $f
  $patterns = @(
    '<li[^>]*>\s*<a[^>]*>[^<]*[Dd]ocumentation[^<]*</a>\s*</li>',
    '<li[^>]*>[^<]*[Dd]ocumentation[^<]*</li>'
  )
  foreach ($p in $patterns) {
    $html = [regex]::Replace($html, $p, "", "Singleline")
  }
  $html = [regex]::Replace($html, "(\r?\n){3,}", "`r`n`r`n")
  Set-Content -LiteralPath $f -Value $html -Encoding UTF8
  Write-Host "Documentation bullet removed (if present): $f"
}

# 2) Remove ⬇️ Download and resume.pdf links on project pages
foreach ($f in $projectFiles) {
  if (-not (Test-Path $f)) { continue }
  Backup-Once $f
  $html = Get-Content -Raw -LiteralPath $f
  $html = [regex]::Replace($html, '<a[^>]*>(?:(?!</a>).)*(?:⬇️|[Dd]ownload)(?:(?!</a>).)*</a>', "", "Singleline")
  $html = [regex]::Replace($html, '<a[^>]*href="[^"]*resume\.pdf"[^>]*>.*?</a>', "", "Singleline")
  $html = [regex]::Replace($html, "(\r?\n){3,}", "`r`n`r`n")
  $html = [regex]::Replace($html, ">\s+<", "> <")
  Set-Content -LiteralPath $f -Value $html -Encoding UTF8
  Write-Host "Project-page Download/resume removed (if present): $f"
}

# 3) Homepage: keep a single Resume link
$index = "index.html"
if (Test-Path $index) {
  Backup-Once $index
  $html = Get-Content -Raw -LiteralPath $index
  # Normalize resume text
  $html = [regex]::Replace($html, '(<a[^>]*href="[^"]*resume\.pdf"[^>]*>)[\s\S]*?(</a>)', '${1}Resume${2}', "Singleline")
  # Remove Download anchors
  $html = [regex]::Replace($html, '<a[^>]*>(?:(?!</a>).)*(?:⬇️|[Dd]ownload)(?:(?!</a>).)*</a>', "", "Singleline")
  # Keep only first resume.pdf anchor
  $pat = '<a[^>]*href="[^"]*resume\.pdf"[^>]*>.*?</a>'
  $matches = [regex]::Matches($html, $pat, "Singleline")
  if ($matches.Count -gt 1) {
    $sb = New-Object System.Text.StringBuilder
    $pos = 0
    for ($i=0; $i -lt $matches.Count; $i++) {
      $m = $matches[$i]
      $sb.Append($html.Substring($pos, $m.Index - $pos)) | Out-Null
      if ($i -eq 0) { $sb.Append($m.Value) | Out-Null }
      $pos = $m.Index + $m.Length
    }
    $sb.Append($html.Substring($pos)) | Out-Null
    $html = $sb.ToString()
  }
  $html = [regex]::Replace($html, "(\r?\n){3,}", "`r`n`r`n")
  $html = [regex]::Replace($html, ">\s+<", "> <")
  Set-Content -LiteralPath $index -Value $html -Encoding UTF8
  Write-Host "Homepage: single Resume link ensured."
}

# 4) Insert navbar "Documentation" link on index and project pages (non-destructive)
function Insert-DocsLink($path) {
  Backup-Once $path
  $html = Get-Content -Raw -LiteralPath $path
  if ($html -notmatch '/docs/') {
    # Try to insert before Certifications or Skills link if present
    $html2 = [regex]::Replace($html, '(?<link><a[^>]*>[^<]*Certifications[^<]*</a>)', '<a href="/docs/">Documentation</a>' + "`n        " + '${link}', 1)
    if ($html2 -eq $html) {
      $html2 = [regex]::Replace($html, '(?<link><a[^>]*>[^<]*Skills[^<]*</a>)', '<a href="/docs/">Documentation</a>' + "`n        " + '${link}', 1)
    }
    if ($html2 -ne $html) {
      $html = $html2
      Set-Content -LiteralPath $path -Value $html -Encoding UTF8
      Write-Host "Inserted Docs link in navbar: $path"
    } else {
      Write-Host "Could not auto-insert Docs link (please add manually): $path"
    }
  } else {
    Write-Host "Docs link already present: $path"
  }
}

if (Test-Path $index) { Insert-DocsLink $index }
foreach ($f in $projectFiles) { if (Test-Path $f) { Insert-DocsLink $f } }

Write-Host "Done. Backups (*.bak) created."
