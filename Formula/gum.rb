class Gum < Formula
  desc "Switch between multiple Git identities (user.name, user.email, SSH keys) with one command"
  homepage "https://github.com/ziyifast/gum"
  url "https://github.com/ziyifast/gum/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_AFTER_RELEASE"
  license "MIT"
  version "1.1.0"

  depends_on "git"
  depends_on "openssh"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match "1.1.0", shell_output("#{bin}/gum version")
  end

  def caveats
    <<~EOS
      To get started, run:
        gum init

      For documentation:
        gum help

      Profiles are stored in ~/.gum/
    EOS
  end
end
