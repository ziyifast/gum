# Makefile for gum (Git User Manager)
# Used by Homebrew, deb packaging, and standard Unix install

PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
DOCDIR  ?= $(PREFIX)/share/doc/gum
MANDIR  ?= $(PREFIX)/share/man/man1

VERSION := 1.1.0

.PHONY: all install uninstall test clean version help

all: help

help:
	@echo "gum (Git User Manager) - Makefile targets:"
	@echo ""
	@echo "  make install              Install gum to \$$(PREFIX) (default: /usr/local)"
	@echo "  make install PREFIX=~/.local"
	@echo "  make uninstall            Remove installed files"
	@echo "  make test                 Run smoke tests"
	@echo "  make version              Show version"
	@echo ""

version:
	@echo "$(VERSION)"

install:
	@echo "Installing gum to $(BINDIR)..."
	@install -d $(DESTDIR)$(BINDIR)
	@install -m 755 gum.sh $(DESTDIR)$(BINDIR)/gum
	@install -d $(DESTDIR)$(DOCDIR)
	@install -m 644 README.md $(DESTDIR)$(DOCDIR)/README.md
	@install -m 644 LICENSE $(DESTDIR)$(DOCDIR)/LICENSE
	@install -m 644 CHANGELOG.md $(DESTDIR)$(DOCDIR)/CHANGELOG.md
	@echo "✓ Installed:"
	@echo "    $(DESTDIR)$(BINDIR)/gum"
	@echo "    $(DESTDIR)$(DOCDIR)/"
	@echo ""
	@echo "Run 'gum init' to get started."

uninstall:
	@echo "Removing gum..."
	@rm -f $(DESTDIR)$(BINDIR)/gum
	@rm -rf $(DESTDIR)$(DOCDIR)
	@echo "✓ Uninstalled."
	@echo ""
	@echo "Note: Your profiles in ~/.gum/ are preserved."
	@echo "To remove them too: rm -rf ~/.gum"

test:
	@echo "Running smoke tests..."
	@bash -n gum.sh && echo "✓ gum.sh syntax OK"
	@bash -n install.sh && echo "✓ install.sh syntax OK"
	@bash -n uninstall.sh && echo "✓ uninstall.sh syntax OK"
	@bash gum.sh version
	@echo "✓ All tests passed."

clean:
	@rm -rf build/ dist/ *.deb
	@echo "✓ Cleaned."
