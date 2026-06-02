# GUM Website

This is the official landing page for [gum](https://github.com/ziyifast/gum).

## Local Preview

The site is pure static HTML/CSS/JS. Just open it in a browser, or serve it locally:

```bash
# Python
cd website && python3 -m http.server 8080

# Node
cd website && npx serve

# PHP
cd website && php -S localhost:8080
```

Then visit http://localhost:8080.

## Deploy to GitHub Pages

### Option A: Deploy from `website/` subfolder

1. Push the project to GitHub
2. Go to repo **Settings** → **Pages**
3. **Source**: Deploy from a branch
4. **Branch**: `main` / `/website`
5. Save. Site will be live at `https://ziyifast.github.io/gum/` after a few minutes.

### Option B: Deploy with custom workflow

Create `.github/workflows/pages.yml`:

```yaml
name: Deploy Pages
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./website
      - id: deployment
        uses: actions/deploy-pages@v4
```

## Custom Domain (optional)

1. Add a `CNAME` file inside `website/` containing your domain (e.g., `gum.dev`)
2. Configure DNS:
   - **Apex domain**: A records pointing to `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - **Subdomain**: CNAME to `ziyifast.github.io`

## Deploy Elsewhere

The `website/` folder is a fully static site — drop it on any host:

| Host | Setup |
|------|-------|
| **Vercel** | `vercel deploy website/` |
| **Netlify** | Drag-and-drop the `website/` folder to [netlify.com/drop](https://app.netlify.com/drop) |
| **Cloudflare Pages** | Connect repo, set build directory to `website/` |
| **Static S3 / OSS** | Upload `website/` content to bucket, enable static hosting |

## File Structure

```
website/
├── index.html              # Main landing page (bilingual via JS)
├── assets/
│   ├── style.css          # Custom styles + animations
│   ├── script.js          # i18n, terminal animation, install tabs
│   ├── favicon.svg        # Site icon
│   └── og-image.svg       # Open Graph preview image (for social sharing)
└── README.md              # This file
```

## Notes

- **Tailwind CSS** is loaded via CDN (no build step required)
- **Fonts**: Inter (body) + JetBrains Mono (code) via Google Fonts
- **Bilingual**: Default language follows browser preference, user choice persisted in `localStorage`
- **No analytics, no tracking**

## ProductHunt Launch Checklist

When you're ready to launch on ProductHunt:

- [ ] Convert `assets/og-image.svg` to PNG at 1200x630 (use [CloudConvert](https://cloudconvert.com/svg-to-png) or `rsvg-convert`)
- [ ] Take 3-5 high-quality screenshots of gum in action
- [ ] Record a 30-60 second demo GIF/video showing `gum init` → `gum use work` → `gum use home`
- [ ] Prepare a one-line tagline: "Switch Git identities in one command."
- [ ] Prepare a 200-character description
- [ ] Schedule your launch for a Tuesday-Thursday at 12:01 AM Pacific
- [ ] Notify your network in advance to upvote on launch day
- [ ] Have a Maker comment ready explaining the inspiration

## Awesome List Submissions

Where to submit gum once you're ready:

- [awesome-cli-apps](https://github.com/agarrharr/awesome-cli-apps) — General CLI tools
- [awesome-shell](https://github.com/alebcay/awesome-shell) — Shell utilities
- [awesome-mac](https://github.com/jaywcjlove/awesome-mac) — Mac apps and tools
- [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles) — Dotfiles helpers
- [terminals-are-sexy](https://github.com/k4m4/terminals-are-sexy) — Terminal tools

Each repo has its own contribution guidelines (usually a PR to the README).
