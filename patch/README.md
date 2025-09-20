
# Style-Preserving Patch (Content-Only Changes)

This patch **does not change your CSS or overall design**. It only updates HTML content
and adds a Docs section that reuses your existing card/grid classes.

What it does:
1) Removes the “Documentation” bullet from Outcomes on all five project pages.
2) Removes any “⬇️ Download” and extra resume.pdf links on project pages.
3) Ensures the homepage shows only a single “Resume” action.
4) Adds a **Documentation** link in the navbar (keeps your styling).
5) Adds a **/docs/** section with:
   - /docs/index.html (cards laid out like your Projects)
   - /docs/logwatch.html (detailed, no video)
   - /docs/password-manager.html (detailed draft, no video)

Backups (`.bak`) are created for any edited file.

## Apply (Windows PowerShell)
1) Copy the `patch` folder and the `docs` folder into your site root (where `index.html` lives).
2) Run:
```
.\patch\apply_style_preserving.ps1
```

## Apply (macOS/Linux or Git Bash)
```
bash patch/apply_style_preserving.sh
```

If your class names differ, the Docs pages will still render with your base styles, since we use generic semantic tags and common classes (card/grid). Adjust class names inside `/docs/*.html` if needed.
