
#!/usr/bin/env bash
set -euo pipefail

backup_once() {
  local f="$1"
  [[ -f "${f}.bak" ]] || cp "$f" "${f}.bak"
}

project_files=(
  "projects/basic-log-monitoring.html"
  "projects/password-manager.html"
  "projects/phishing-email-analysis.html"
  "projects/secure-network-lab.html"
  "projects/vulnerability-scan.html"
)

# 1) Remove “Documentation” bullet
for f in "${project_files[@]}"; do
  [[ -f "$f" ]] || { echo "Skip (not found): $f"; continue; }
  backup_once "$f"
  perl -0777 -pe '
    s/<li[^>]*>\s*<a[^>]*>[^<]*[Dd]ocumentation[^<]*<\/a>\s*<\/li>//gs;
    s/<li[^>]*>[^<]*[Dd]ocumentation[^<]*<\/li>//gs;
    s/(\r?\n){3,}/\n\n/gs;
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "Removed Documentation bullet: $f"
done

# 2) Remove Download & resume.pdf anchors on project pages
for f in "${project_files[@]}"; do
  [[ -f "$f" ]] || continue
  backup_once "$f"
  perl -0777 -pe '
    s/<a[^>]*>(?:(?!<\/a>).)*(?:⬇️|[Dd]ownload)(?:(?!<\/a>).)*<\/a>//gs;
    s/<a[^>]*href="[^"]*resume\.pdf"[^>]*>.*?<\/a>//gs;
    s/(\r?\n){3,}/\n\n/gs;
    s/>\s+</> </gs;
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "Cleaned Download/resume on project page: $f"
done

# 3) Homepage: single Resume
if [[ -f "index.html" ]]; then
  backup_once "index.html"
  perl -0777 -pe '
    s/(<a[^>]*href="[^"]*resume\.pdf"[^>]*>)[\s\S]*?(<\/a>)/${1}Resume${2}/gs;
    s/<a[^>]*>(?:(?!<\/a>).)*(?:⬇️|[Dd]ownload)(?:(?!<\/a>).)*<\/a>//gs;
  ' index.html > index.html.tmp

  # Keep first resume link only
  perl -0777 -e '
    local $/; $_=<>;
    my $pat = qr/<a[^>]*href="[^"]*resume\.pdf"[^>]*>.*?<\/a>/s;
    my @m = ($_ =~ /$pat/g);
    if (@m > 1) {
      my $c = 0;
      s/$pat/ ++$c==1 ? $& : q{//REMOVED_DUP_RESUME}//seg;
      s{//REMOVED_DUP_RESUME}{}g;
    }
    s/(\r?\n){3,}/\n\n/gs;
    s/>\s+</> </gs;
    print $_;
  ' index.html.tmp > index.html && rm -f index.html.tmp
  echo "Homepage: single Resume ensured."
fi

# 4) Insert navbar Docs link (index + projects). Non-destructive best-effort.
insert_docs_link() {
  local f="$1"
  [[ -f "$f" ]] || return
  backup_once "$f"
  python - <<'PY'
import re,sys
p=sys.argv[1]
html=open(p,'r',encoding='utf-8',errors='ignore').read()
if '/docs/' in html:
  print('Docs link already exists:',p); sys.exit(0)
# Try before Certifications, else before Skills
new=re.sub(r'(<a[^>]*>[^<]*Certifications[^<]*</a>)', r'<a href="/docs/">Documentation</a>\n        \1', html, count=1, flags=re.S)
if new==html:
  new=re.sub(r'(<a[^>]*>[^<]*Skills[^<]*</a>)', r'<a href="/docs/">Documentation</a>\n        \1', html, count=1, flags=re.S)
if new!=html:
  open(p,'w',encoding='utf-8').write(new)
  print('Inserted Docs link in navbar:',p)
else:
  print('Could not auto insert Docs link (add manually):',p)
PY
}
insert_docs_link "index.html"
for f in "${project_files[@]}"; do insert_docs_link "$f"; done

echo "Done. Backups (*.bak) created where edits occurred."
