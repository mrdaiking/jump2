class Jump2 < Formula
  desc "Name a folder or a command, run it with one word (zsh)"
  homepage "https://github.com/mrdaiking/jump2"
  url "https://github.com/mrdaiking/jump2/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "MIT"

  depends_on "zsh"

  def install
    pkgshare.install "jump2.zsh"
  end

  def caveats
    <<~EOS
      Add this line to ~/.zshrc, then run `exec zsh`:
        source #{opt_pkgshare}/jump2.zsh
    EOS
  end

  test do
    out = shell_output("zsh -f -c 'source #{pkgshare}/jump2.zsh; jump2 --version'")
    assert_match "jump2 #{version}", out
  end
end
