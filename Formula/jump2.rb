class Jump2 < Formula
  desc "Name a folder or a command, run it with one word (zsh)"
  homepage "https://github.com/mrdaiking/jump2"
  url "https://github.com/mrdaiking/jump2/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "41940af3d00179672f6a35bced237d785845ff3a46040c59a0f19b8d3345878f"
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
