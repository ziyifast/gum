# Packaging & Release Guide

This document describes how to release a new version of gum and how each packaging method works.

## Release Workflow

When releasing a new version (e.g., v1.2.0):

### 1. Bump Version

Update version in these files:
- `gum.sh` — `GUM_VERSION="1.2.0"`
- `Makefile` — `VERSION := 1.2.0`
- `Formula/gum.rb` — `version "1.2.0"` and `url "...v1.2.0.tar.gz"`
- `packaging/deb/DEBIAN/control` — `Version: 1.2.0`
- `packaging/scoop/gum.json` — `"version": "1.2.0"`
- `CHANGELOG.md` — add release notes

### 2. Tag and Push

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

### 3. Compute SHA256 for Homebrew & Scoop

```bash
# Wait for GitHub to create the tarball, then:
curl -sL https://github.com/ziyifast/gum/archive/refs/tags/v1.2.0.tar.gz | shasum -a 256
```

Update the `sha256` field in `Formula/gum.rb` and `hash` in `packaging/scoop/gum.json`.

### 4. Build .deb Package

```bash
bash packaging/deb/build.sh
# Produces: gum_1.2.0_all.deb
```

### 5. Create GitHub Release

Upload the `.deb` file to the release page at https://github.com/ziyifast/gum/releases.

## Packaging Methods Explained

### Makefile

The `Makefile` is the foundation — Homebrew and the .deb builder both reuse it indirectly. It provides:
- `make install PREFIX=...` — installs to a target prefix
- `make uninstall` — clean removal
- `make test` — syntax checks

### Homebrew

`Formula/gum.rb` is the formula. Users tap a separate repo to discover it:

**Option A: Use this repo as a tap (simpler)**
The `Formula/` directory at repo root works as a tap:
```bash
brew tap ziyifast/gum https://github.com/ziyifast/gum
brew install gum
```

**Option B: Dedicated tap repo (cleaner, recommended for popular projects)**
Create a separate repo `homebrew-tap` with a `Formula/gum.rb` file. Users install with:
```bash
brew tap ziyifast/tap
brew install gum
```

### apt-get / Debian Package

`packaging/deb/build.sh` constructs a `.deb` package containing:
- `/usr/bin/gum` — the executable
- `/usr/share/doc/gum/` — documentation

The package metadata is in `packaging/deb/DEBIAN/control`. Users install with `dpkg -i`.

For wider distribution, you could submit to a PPA or to Debian/Ubuntu universe (much higher bar).

### Scoop (Windows)

`packaging/scoop/gum.json` is the manifest. It tells Scoop:
- Where to download the source (GitHub release tarball)
- What file to expose as a binary (`gum.sh` → `gum`)
- Dependencies (`git`, which provides Git Bash on Windows)

Users add this repo as a Scoop bucket:
```powershell
scoop bucket add ziyifast https://github.com/ziyifast/gum
scoop install gum
```

### curl | bash

`packaging/install-remote.sh` is downloaded and run directly. It:
1. Downloads `gum.sh` from the specified branch/tag
2. Installs it to `~/.gum/bin/gum`
3. Adds the bin directory to `PATH` in the user's shell config

This is the simplest install method but requires the user to trust the script.

## Testing Packages Locally

```bash
# Makefile
make install PREFIX=/tmp/gum-test
/tmp/gum-test/bin/gum version
make uninstall PREFIX=/tmp/gum-test

# Debian package (requires dpkg-deb)
bash packaging/deb/build.sh
sudo dpkg -i gum_1.1.0_all.deb
gum version
sudo dpkg -r gum

# Homebrew formula syntax (requires brew)
brew audit --new --strict Formula/gum.rb

# Scoop manifest validation
python3 -m json.tool packaging/scoop/gum.json
```
