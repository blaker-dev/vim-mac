class VimMac < Formula
  desc "Vim-style modal window manager for macOS"
  homepage "https://github.com/blaker-dev/vim-mac"
  head "https://github.com/blaker-dev/vim-mac.git", branch: "main"
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]
  depends_on "koekeishiya/formulae/yabai"

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/vim-mac"
  end

  def caveats
    <<~EOS
      vim-mac requires Accessibility permissions to manage windows and capture modal keys.
      Open System Settings > Privacy & Security > Accessibility and ensure your terminal emulator or vim-mac binary is enabled.

      Make sure yabai service is active:
        yabai --start-service
    EOS
  end

  service do
    run [opt_bin/"vim-mac"]
    keep_alive true
    log_path var/"log/vim-mac.log"
    error_log_path var/"log/vim-mac.err.log"
  end

  test do
    assert_predicate bin/"vim-mac", :exist?
  end
end
