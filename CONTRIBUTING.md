# Contributing to GUM

Thank you for considering contributing to GUM! Here's how you can help.

## How to Contribute

### Reporting Bugs

- Open an issue on GitHub
- Include your OS version and bash/zsh version (`bash --version`)
- Include the full error output
- Describe what you expected to happen

### Suggesting Features

- Open an issue with the `feature request` label
- Describe the use case and why it would be useful

### Pull Requests

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/awesome-feature`)
3. Make your changes
4. Test locally (see below)
5. Commit with a clear message (`git commit -m 'Add awesome feature'`)
6. Push to your fork (`git push origin feature/awesome-feature`)
7. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/gum.git
cd gum

# Install locally for testing
bash install.sh
source ~/.zshrc  # or ~/.bashrc

# Make changes to gum.sh
# Then re-install to test
cp gum.sh ~/.gum/bin/gum
```

## Testing

Before submitting a PR, please test:

```bash
# Basic functionality
gum version
gum help
gum list

# Create and switch profiles (use a test name)
gum create test-profile
gum use test-profile
gum current
gum show test-profile

# Verify git config changed
git config --global user.name
git config --global user.email

# Clean up
gum delete test-profile

# Check SSH config is clean
cat ~/.ssh/config
```

## Code Style

- Use 4-space indentation
- Function names: `gum_<command_name>()`
- Section separators: `# ====...====`
- Comments for non-obvious logic
- All user-facing output should use color helpers (`gum_echo`, `gum_warn`, `gum_error`, `gum_info`)

## Project Structure

See [docs/architecture.md](docs/architecture.md) for a detailed walkthrough of the codebase.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
