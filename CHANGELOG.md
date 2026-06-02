# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-29

### Added
- `gum init` command for quick one-step setup of work & home profiles
- `gum config` command to view/edit/reset user configuration
- User configuration file (`~/.gum/config`) for customizing default profile names
- Interactive arrow-key selector for all menu choices (↑/↓/j/k + Enter)
- Vim-style navigation (j/k) in selector
- Auto-detection of existing `~/.ssh/config` entries during profile creation
- Fallback to number input when running in non-interactive mode (pipes/scripts)
- `Ctrl+C` trap to restore cursor visibility in interactive selector

### Fixed
- `git config --replace-all` to handle duplicate user.name/email entries
- macOS bash 3.2 compatibility (removed `read -t 0.1` decimal timeout)

## [1.0.0] - 2026-05-28

### Added
- Initial release
- `gum create` - Create Git identity profiles with SSH key generation
- `gum list` - List all profiles with active indicator
- `gum use` - Switch profiles globally or per-repo (`--local`)
- `gum current` - Show active profile
- `gum show` - Display profile details
- `gum delete` - Remove profiles with confirmation
- `gum import` - Import existing git config as a profile
- SSH config management with marker comments (non-destructive)
- Ed25519 SSH key auto-generation
- Support for custom SSH hosts and ports
