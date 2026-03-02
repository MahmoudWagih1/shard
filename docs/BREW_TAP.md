# Homebrew tap (optional)

When you want to offer `brew install localai`, create a separate tap repo and use this sketch.

## 1. Create the tap repo

- Repo name: `homebrew-localai` (GitHub: `USER/homebrew-localai`).
- Add a single formula file: `Formula/localai.rb`.

## 2. Formula sketch

Put this in `Formula/localai.rb` in the tap repo. Replace `YOUR_USERNAME` and `localai` with your GitHub user and repo name. Use a real version tag (e.g. `v1.0.0`) once you have releases.

```ruby
# Formula/localai.rb
class Localai < Formula
  desc "Offline LLM chat for Apple Silicon — one command: llm"
  homepage "https://github.com/YOUR_USERNAME/localai"
  url "https://github.com/YOUR_USERNAME/localai/archive/refs/heads/main.zip"
  version "0.0.0"
  sha256 ""  # run: curl -sL URL | shasum -a 256
  license "MIT"

  depends_on "python@3.11"

  def install
    # Copy repo into prefix so 'llm' can find it; first run will call setup
    libexec.install Dir["*.py"], "setup.sh", "install.sh", "wipe_session.sh"
    libexec.install "detect.py", "config.py", "agent.py", "voice.py" if File.file?("voice.py")
    (libexec/"llm-wrapper").write <<~BASH
      #!/usr/bin/env bash
      set -e
      LOCALAI="$HOME/.localai"
      if [ ! -f "$LOCALAI/venv/bin/python" ]; then
        echo "First run: installing localai into $LOCALAI"
        FORMULA_PREFIX="$(brew --prefix localai 2>/dev/null)"
        if [ -n "$FORMULA_PREFIX" ] && [ -d "$FORMULA_PREFIX/libexec" ]; then
          mkdir -p "$LOCALAI"
          cp -R "$FORMULA_PREFIX/libexec/"* "$LOCALAI/"
          bash "$LOCALAI/setup.sh"
        else
          echo "Run: bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/localai/main/install.sh)"
          exit 1
        fi
      fi
      exec "$LOCALAI/venv/bin/python" "$LOCALAI/chat.py" "$@"
    BASH
    chmod 0755, libexec/"llm-wrapper"
    bin.install libexec/"llm-wrapper" => "llm"
  end

  test do
    assert_match "localai", shell_output("#{bin}/llm --help 2>&1", 1)
  end
end
```

Note: the formula above uses `refs/heads/main.zip`; for stable installs, prefer a GitHub release tarball and set `url` and `version` to the release. Run `brew audit --new-formula localai` in the tap repo and fix any issues.

## 3. Install for users

```bash
brew tap YOUR_USERNAME/localai
brew install localai
llm
```

## 4. README

In the main localai README, the install section already mentions:

```bash
brew tap YOUR_USERNAME/localai && brew install localai
```

Keep the curl one-liner as the primary install path; brew is an alternative for users who prefer it.
