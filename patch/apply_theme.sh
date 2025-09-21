
#!/usr/bin/env bash
set -euo pipefail

# Adjust if your stylesheet lives elsewhere:
cssPath="assets/style.css"

if [[ ! -f "$cssPath" ]]; then
  echo "Could not find $cssPath. Edit patch/apply_theme.sh and set cssPath to your stylesheet path."
  exit 1
fi

backup="${cssPath}.bak"
if [[ ! -f "$backup" ]]; then
  cp "$cssPath" "$backup"
  echo "Backup created: $backup"
else
  echo "Backup already exists: $backup"
fi

cp "patch/style.css" "$cssPath"
echo "Theme applied to $cssPath"

# Optional: ensure a top-level container exists (very conservative)
pages=(
  "index.html"
  "projects/basic-log-monitoring.html"
  "projects/password-manager.html"
  "projects/phishing-email-analysis.html"
  "projects/secure-network-lab.html"
  "projects/vulnerability-scan.html"
)
for p in "${pages[@]}"; do
  [[ -f "$p" ]] || continue
  python - <<'PY'
import re,sys,io
p=sys.argv[1]
html=open(p,'r',encoding='utf-8',errors='ignore').read()
m=re.search(r"<body([^>]*)>\s*<div(?![^>]*class=)([^>]*)>", html, re.S)
if m:
  html=re.sub(r"<body([^>]*)>\s*<div(?![^>]*class=)([^>]*)>", r"<body\1><div class=\"container\"\2>", html, count=1, flags=re.S)
  open(p,'w',encoding='utf-8').write(html)
  print("Added container class:", p)
PY
done

echo "All done. Review locally, then push."
