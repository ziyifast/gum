# Open Source Launch Checklist

This document is your runway for taking gum from "code on GitHub" to "discovered by the world."

## Phase 1: Pre-Launch (1-2 weeks before)

### Repository Polish

- [ ] Ensure `README.md` has hero logo, clear tagline, badges, and quickstart
- [ ] Verify `CHANGELOG.md` is up to date
- [ ] All examples in docs work (test with a fresh user)
- [ ] Add `Topics` to GitHub repo: `git`, `cli`, `bash`, `ssh`, `developer-tools`, `git-config`
- [ ] Pin a "Welcome / How to contribute" issue
- [ ] Add a clear **About** description on the GitHub repo page
- [ ] Set the **Website** field on GitHub to `https://ziyifast.github.io/gum/`

### Branding & Assets

- [x] Logo created (`website/assets/brand/`)
- [x] Multiple sizes generated (32, 64, 128, 256, 512)
- [x] Light + dark theme variants
- [ ] Convert `logo-512.png` to a 1200×630 OG image with project tagline
- [ ] Take 3-5 high-resolution screenshots of gum in action
- [ ] Record a 30-60 second demo video (use `asciinema` for terminal recording, then convert to GIF)

### Website

- [x] Landing page deployed to `https://ziyifast.github.io/gum/`
- [ ] Test on mobile (responsive)
- [ ] Test in Chrome / Safari / Firefox
- [ ] Verify all "Copy" buttons work
- [ ] Verify language toggle works
- [ ] Verify all GitHub links go to the correct repo

### Distribution

- [ ] Create `homebrew-tap` repo, copy `Formula/gum.rb` there
- [ ] Tag and create v1.1.0 GitHub Release with built `.deb` attached
- [ ] Compute SHA256 for release tarball, fill into Formula and Scoop manifest
- [ ] Test installs work from at least one method (curl|bash is easiest)

## Phase 2: Launch Day

### ProductHunt

**Best time**: Tuesday-Thursday, 12:01 AM Pacific Time (00:01 PT)

**Preparation**:
- [ ] Create ProductHunt account well in advance (do not register day-of, looks suspicious)
- [ ] Tagline (max 60 chars): "Switch Git identities in one command. Like nvm, but for Git."
- [ ] Description (200 chars):
      "GUM is a tiny CLI that swaps your Git config (user.name/email) and SSH keys with a single 'gum use work' or 'gum use home'. Pure Bash, zero deps."
- [ ] Topics: Developer Tools, Open Source, GitHub, Productivity
- [ ] Upload: 1 thumbnail (240×240 from logo), 3-5 screenshots, 1 demo video
- [ ] First Maker comment (post within 5 minutes of launch):
      Tell the story — what made you build this? What pain were you solving?
- [ ] Have 5-10 friends ready to upvote in the first hour (organic-looking, not all at once)
- [ ] Engage with every comment within 30 minutes during the first 8 hours
- [ ] DO NOT ask for upvotes publicly — ProductHunt penalizes this

### Hacker News (Show HN)

**Best time**: Tuesday-Thursday, 8-10 AM EST (12-2 PM UTC)

- [ ] Title: `Show HN: Gum – Switch Git identities (user.name, SSH keys) in one command`
- [ ] First comment (your own): brief origin story, link to architecture doc, ask for feedback
- [ ] Don't ask friends to upvote — HN detects voting rings and will kill your post
- [ ] Engage genuinely with every comment, especially critical ones

### Reddit

- [ ] r/programming — link post with discussion in comments
- [ ] r/commandline — perfect audience
- [ ] r/git — directly relevant
- [ ] r/opensource — community appreciation
- [ ] r/coolgithubprojects — showcase

**Format**: title with the value prop, top comment with the GitHub link and a 3-line explanation.

### Awesome Lists (PRs)

Submit a PR to each of these adding gum to their list:

- [ ] [agarrharr/awesome-cli-apps](https://github.com/agarrharr/awesome-cli-apps) — under "Productivity" or "Development"
- [ ] [alebcay/awesome-shell](https://github.com/alebcay/awesome-shell) — under "Shell Script Development"
- [ ] [jaywcjlove/awesome-mac](https://github.com/jaywcjlove/awesome-mac) — under "Developer Tools"
- [ ] [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles) — under "Tools"
- [ ] [k4m4/terminals-are-sexy](https://github.com/k4m4/terminals-are-sexy) — terminal tools
- [ ] [unixorn/git-extra-commands](https://github.com/unixorn/git-extra-commands) — git tools

**PR format** (one line, alphabetical order):
```markdown
- [gum](https://github.com/ziyifast/gum) - Switch between multiple Git identities (user.name, user.email, SSH keys) with one command.
```

### Chinese Community

- [ ] [GitHub 中文社区](https://www.github.com.cn) 投稿
- [ ] [HelloGitHub 月刊](https://hellogithub.com) 投稿（编辑会精选）
- [ ] V2EX `/go/share` 节点发帖
- [ ] 知乎专栏文章：「我做了一个一键切换 Git 账号的小工具」
- [ ] 掘金 / 思否 / SegmentFault 同步
- [ ] 即刻 App 上「开源新发现」圈子
- [ ] [ruanyf/weekly](https://github.com/ruanyf/weekly) 阮一峰周刊推荐（提 issue 推荐）

### Twitter / X

- [ ] Pin a launch tweet with the website link, GIF demo, and tagline
- [ ] Tag `@ProductHunt`, `@github`, `@homebrew` once they're relevant
- [ ] Thread format works better than single tweets — start with the pain, end with the solution

## Phase 3: Post-Launch (ongoing)

### Build the Community

- [ ] Respond to every issue within 24 hours (even just to acknowledge)
- [ ] Tag friendly issues as `good first issue` for new contributors
- [ ] Create a `CODE_OF_CONDUCT.md` if community grows beyond 50 stars
- [ ] Consider GitHub Discussions for Q&A (better than scattered issues)

### Keep the Momentum

- [ ] Write a blog post explaining the architecture (cross-post to dev.to, Medium)
- [ ] Submit to weekly newsletters: TLDR Newsletter, Bytes, Pointer, Console.dev
- [ ] If you hit 1000 stars, post an update on social media — milestones drive secondary growth

### Maintenance

- [ ] Establish a release cadence (e.g., minor version every 2-3 months)
- [ ] Always update CHANGELOG.md before tagging a release
- [ ] Bump version in: `gum.sh`, `Makefile`, `Formula/gum.rb`, `packaging/scoop/gum.json`, `packaging/deb/DEBIAN/control`

## Common Pitfalls to Avoid

1. **Don't beg for stars**. It cheapens the project. Build something genuinely useful and stars come.
2. **Don't launch on Friday or weekend**. Engagement drops off a cliff.
3. **Don't launch on multiple platforms simultaneously**. Stagger them — ProductHunt one day, HN the next, Reddit a few days later. Each platform has its own news cycle.
4. **Don't ignore criticism**. Hostile comments often contain real feedback. Respond with curiosity, not defensiveness.
5. **Don't disappear after launch**. The first 30 days post-launch are when you build (or lose) momentum.

## Success Metrics

| Milestone | Signal |
|-----------|--------|
| 100 stars | Project has resonance |
| 500 stars | You've hit a real pain point |
| 1000 stars | Tipping point — discoverability accelerates |
| 5000 stars | Industry recognition |
| First external contributor | You've built community, not just code |
| First language port (e.g., Go rewrite) | You've created a category |

Good luck! 🚀
