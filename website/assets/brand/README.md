# GUM Brand Assets

This directory contains the official logo and brand assets for the gum project.

## Concept

The logo plays on a clever **dual metaphor**:

- **"Gum" the chewing gum**: Stacked colorful bars resemble a pack of chewing gum or stacked gum slices.
- **"Gum" the Git User Manager**: The Git branch icon on top makes the function clear, and the multiple stacked layers represent multiple Git identities.

This three-way alignment of **name → visual → function** is rare and memorable.

## Files

| File | Size | Use case |
|------|------|----------|
| `logo-original.png` | 1408×768 | Original source (do not modify) |
| `logo.png` | 494×474 | Tightly cropped, original background |
| `logo-transparent.png` | 494×474 | Transparent background |
| `logo-512.png` | 512×512 | Square, transparent — for OG images, ProductHunt |
| `logo-256.png` | 256×256 | App icon, GitHub social preview |
| `logo-128.png` | 128×128 | Documentation, README header |
| `logo-64.png` | 64×64 | Navigation bar, in-page logo |
| `logo-32.png` | 32×32 | Favicon |
| `logo-light.png` | 494×494 | White background variant (for light themes) |
| `logo-dark.png` | 494×494 | Dark background variant (`#0a0e1a` — matches website) |

## Usage Guidelines

### Do

- Use `logo-transparent.png` or PNGs with transparent background on colored surfaces
- Maintain at least 8px of clear space around the logo
- Use the smallest size that fits your use case to keep file sizes small

### Don't

- Don't recolor or redraw the logo
- Don't add effects (drop shadows, glows, etc.)
- Don't squish or stretch — always preserve aspect ratio
- Don't use sizes below 32×32 (the smaller blue layer becomes illegible)

## Color Palette

Matched to the website theme:

| Role | Hex | Usage |
|------|-----|-------|
| Logo green (primary) | `#3ab78f` | Top layer, main brand color |
| Logo blue | `#5a9ee0` | Second layer |
| Logo yellow | `#f0c346` | Third layer |
| Logo orange | `#ee9646` | Fourth layer |
| Logo coral | `#f08a7a` | Bottom layer |
| Background dark | `#0a0e1a` | Website background |
| Gradient start | `#a855f7` | Purple (text gradient) |
| Gradient end | `#06b6d4` | Cyan (text gradient) |

## Markdown Embedding

```markdown
<!-- README header -->
<img src="website/assets/brand/logo-128.png" alt="gum" width="80">

<!-- Inline -->
![gum](website/assets/brand/logo-32.png)
```

## License

The logo is released under the same MIT License as the project. You are free to use it
when referring to the gum project in articles, blog posts, or documentation.
