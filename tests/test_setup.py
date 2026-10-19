"""Integration tests: isolated HOME and PATH; no network or real installers."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles setup ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # An allowlist prevents tests from accidentally reaching real installers.
        for name in ("dirname", "mkdir", "cmp", "ln", "mv", "date", "mktemp",
                     "cp", "grep", "find", "rm", "chmod", "sh", "cat", "awk", "readlink"):
            (self.bin / name).symlink_to(shutil.which(name))
        self.env = {
            "PATH": str(self.bin), "HOME": str(self.home), "SHELL": "/bin/zsh",
            "TMPDIR": str(self.root), "TEST_LOG": str(self.root / "commands"),
            "TEST_OS": "Darwin", "TEST_ARCH": "x86_64",
        }
        self.stub("uname", 'if [ "$1" = -m ]; then echo "$TEST_ARCH"; else echo "$TEST_OS"; fi')
        self.stub("id", 'echo 1000')
        self.stub("sudo", 'printf "sudo %s\\n" "$*" >> "$TEST_LOG"\n"$@"')
        self.stub("starship", 'echo "unexpected starship execution" >&2; exit 99')

    def stub(self, name, body):
        path = self.bin / name
        if path.is_symlink():
            path.unlink()
        path.write_text("#!/bin/bash\nset -eu\n" + body + "\n")
        path.chmod(0o755)

    def run_setup(self, *args, success=True):
        result = subprocess.run(
            ["/bin/bash", str(REPO / "init.sh"), *args], env=self.env,
            cwd=self.root, text=True, capture_output=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def run_function(self, function):
        return subprocess.run(
            ["/bin/bash", "-c", 'set -euo pipefail; source "$1/scripts/common.sh"; '
             'source "$1/scripts/install.sh"; PLATFORM=linux; "$2"',
             "test", str(REPO), function], env=self.env, cwd=self.root,
            text=True, capture_output=True,
        )

    def test_macos_links_and_second_run(self):
        self.run_setup("--skip-install")
        self.assertEqual((self.home / ".config/starship.toml").resolve(), REPO / "starship.toml")
        for source in (REPO / "warp_config").rglob("*"):
            if source.is_file():
                self.assertEqual((self.home / ".warp" / source.relative_to(REPO / "warp_config")).resolve(), source)
        before = (self.home / ".zshrc").read_bytes()
        backups_before = list(self.home.rglob("*.backup.*"))
        self.run_setup("--skip-install")
        self.assertEqual((self.home / ".zshrc").read_bytes(), before)
        self.assertEqual(list(self.home.rglob("*.backup.*")), backups_before)
        self.assertIn(b'eval "$(starship init zsh)"', before)
        self.assertLess(before.index(b"/shell_config/alias.sh"), before.index(b"starship init zsh"))

    def test_backups_broken_links_and_other_themes(self):
        config = self.home / ".config"
        config.mkdir()
        (config / "starship.toml").write_text("previous config")
        themes = self.home / ".warp/themes"
        themes.mkdir(parents=True)
        (themes / "other.yaml").write_text("keep me")
        (themes / "custom_pastel.yaml").symlink_to(self.root / "missing")
        (self.home / ".zshrc").write_text("export CUSTOM=1\n")
        self.run_setup("--skip-install")
        self.assertEqual(next(config.glob("starship.toml.backup.*")).read_text(), "previous config")
        self.assertTrue(next(themes.glob("custom_pastel.yaml.backup.*")).is_symlink())
        self.assertEqual((themes / "other.yaml").read_text(), "keep me")
        self.assertIn("export CUSTOM=1\n", [path.read_text() for path in self.home.glob(".zshrc.backup.*")])

    def test_linux_xdg_zdotdir_and_existing_shells(self):
        self.env.update(TEST_OS="Linux", XDG_CONFIG_HOME=str(self.home / "config space"),
                        XDG_DATA_HOME=str(self.home / "data space"), ZDOTDIR=str(self.home / "zsh"))
        fish = Path(self.env["XDG_CONFIG_HOME"]) / "fish/config.fish"
        fish.parent.mkdir(parents=True)
        fish.write_text("starship init fish | source\n")
        bash = self.home / ".bashrc"
        bash.write_text('eval "$(starship init bash)"\n')
        profile = self.home / ".profile"
        profile.write_text('if [ -n "$BASH_VERSION" ]; then . "$HOME/.bashrc"; fi\n')
        before = profile.read_bytes()
        self.run_setup("--skip-install")
        self.run_setup("--skip-install")
        self.assertTrue((Path(self.env["XDG_CONFIG_HOME"]) / "warp-terminal/keybindings.yaml").is_symlink())
        self.assertTrue((Path(self.env["XDG_DATA_HOME"]) / "warp-terminal/themes/assassin.jpg").is_symlink())
        self.assertTrue((self.home / "zsh/.zshrc").is_file())
        self.assertEqual(fish.read_text(), "starship init fish | source\n")
        self.assertEqual(bash.read_text(), 'eval "$(starship init bash)"\n')
        self.assertEqual(profile.read_bytes(), before)
        self.assertFalse((self.home / ".bash_profile").exists())

    def test_comment_is_not_an_initialization_and_bash_login_is_configured(self):
        self.env.update(TEST_OS="Linux", SHELL="/bin/bash")
        (self.home / ".bashrc").write_text('# eval "$(starship init bash)"\n')
        self.run_setup("--skip-install")
        profile = (self.home / ".bash_profile").read_bytes()
        self.run_setup("--skip-install")
        self.assertEqual((self.home / ".bash_profile").read_bytes(), profile)
        self.assertIn(b'. "$HOME/.bashrc"', profile)
        self.assertIn('\neval "$(starship init bash)"\n', (self.home / ".bashrc").read_text())

    def test_custom_starship_path(self):
        target = self.home / "custom prompt/config.toml"
        self.env["STARSHIP_CONFIG"] = str(target)
        self.run_setup("--skip-install")
        self.assertEqual(target.resolve(), REPO / "starship.toml")

    def test_aliases_are_loaded_from_bashrc_before_existing_starship(self):
        self.env.update(TEST_OS="Linux", SHELL="/bin/bash")
        self.stub("starship", "exit 0")
        self.stub("batcat", "exit 0")
        rc_file = self.home / ".bashrc"
        original = 'export KEEP=1\neval "$(starship init bash)"\n'
        rc_file.write_text(original)
        self.run_setup("--skip-install")
        configured = rc_file.read_bytes()
        self.assertLess(configured.index(b"/shell_config/alias.sh"), configured.index(b"starship init bash"))
        self.assertIn(b"export KEEP=1", configured)
        self.assertEqual(next(self.home.glob(".bashrc.backup.*")).read_text(), original)
        self.run_setup("--skip-install")
        self.assertEqual(rc_file.read_bytes(), configured)
        result = subprocess.run(
            ["/bin/bash", "--noprofile", "--norc", "-c", 'source "$HOME/.bashrc"; alias cat'],
            env=self.env, cwd=self.root, text=True, capture_output=True, check=True,
        )
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout.strip(), "alias cat='batcat'")

    def test_parent_shell_takes_priority_over_login_shell(self):
        self.env["SHELL"] = "/bin/zsh"
        self.stub("ps", "echo /bin/bash")
        self.run_setup("--skip-install")
        self.assertIn("/shell_config/alias.sh", (self.home / ".bashrc").read_text())
        self.assertFalse((self.home / ".zshrc").exists())

    def test_old_zshrc_symlink_is_backed_up_without_recreating_target(self):
        old_target = self.root / "old repo/shell_config/.zshrc"
        old_target.parent.mkdir(parents=True)
        rc_file = self.home / ".zshrc"
        rc_file.symlink_to(old_target)
        self.run_setup("--skip-install")
        self.assertFalse(old_target.exists())
        self.assertFalse(rc_file.is_symlink())
        self.assertIn("/shell_config/alias.sh", rc_file.read_text())
        self.assertTrue(any(path.is_symlink() for path in self.home.glob(".zshrc.backup.*")))

    def test_fish_does_not_source_bash_aliases(self):
        self.env.update(TEST_OS="Linux", SHELL="/usr/bin/fish")
        self.run_setup("--skip-install")
        config = (self.home / ".config/fish/config.fish").read_text()
        self.assertIn("starship init fish", config)
        self.assertNotIn("alias.sh", config)
        self.assertFalse((self.home / ".bashrc").exists())

    def brew_stub(self):
        return '''printf 'brew %s\\n' "$*" >> "$TEST_LOG"
if [ "$1" = shellenv ]; then
    printf 'export PATH=%q:$PATH\\n' "${BASH_SOURCE[0]%/*}"
fi'''

    def run_homebrew(self):
        # Isolate discovery from any real Homebrew installation on the test host.
        return subprocess.run(
            ["/bin/bash", "-c", '''set -euo pipefail
source "$1/scripts/common.sh"
source "$1/scripts/homebrew.sh"
source "$1/scripts/install.sh"
find_homebrew() {
    [ -x "$TEST_BREW" ] || return 1
    printf '%s\\n' "$TEST_BREW"
}
PLATFORM=macos
ensure_homebrew
install_starship
''', "test", str(REPO)], env=self.env, cwd=self.root,
            text=True, capture_output=True,
        )

    def test_existing_homebrew_is_activated_and_profile_is_not_duplicated(self):
        self.stub("brew", self.brew_stub())
        self.env["ZDOTDIR"] = str(self.home / "zsh config")
        self.run_setup()
        profile = Path(self.env["ZDOTDIR"]) / ".zprofile"
        before = profile.read_bytes()
        self.run_setup()
        self.assertEqual(profile.read_bytes(), before)
        self.assertIn(b"shellenv", before)
        self.assertFalse(list(profile.parent.glob(".zprofile.backup.*")))
        self.assertIn("brew shellenv", Path(self.env["TEST_LOG"]).read_text())

    def test_homebrew_outside_path_is_reused(self):
        self.stub("brew", self.brew_stub())
        existing = self.root / "existing brew/bin/brew"
        existing.parent.mkdir(parents=True)
        (self.bin / "brew").rename(existing)
        self.env["TEST_BREW"] = str(existing)
        (self.bin / "starship").unlink()
        result = self.run_homebrew()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(Path(self.env["TEST_LOG"]).read_text(),
                         "brew shellenv\nbrew install starship\n")

    def test_homebrew_bootstrap_runs_before_starship_and_preserves_profile(self):
        self.stub("brew", self.brew_stub())
        template = self.root / "brew-template"
        (self.bin / "brew").rename(template)
        self.env.update(TEST_BREW=str(self.root / "new brew/bin/brew"), TEST_TEMPLATE=str(template))
        (self.bin / "starship").unlink()
        profile = self.home / ".zprofile"
        profile.write_text("export KEEP=1\n")
        self.stub("curl", '''while [ "$1" != -o ]; do shift; done
cat > "$2" <<'INSTALLER'
printf 'homebrew installer\\n' >> "$TEST_LOG"
mkdir -p "${TEST_BREW%/*}"
cp "$TEST_TEMPLATE" "$TEST_BREW"
chmod +x "$TEST_BREW"
INSTALLER''')
        result = self.run_homebrew()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(Path(self.env["TEST_LOG"]).read_text(),
                         "homebrew installer\nbrew shellenv\nbrew install starship\n")
        self.assertEqual(next(self.home.glob(".zprofile.backup.*")).read_text(), "export KEEP=1\n")
        self.assertTrue(profile.read_text().startswith("export KEEP=1\n"))
        self.assertFalse(list(self.root.glob("tmp.*")))

    def test_homebrew_download_failure_stops_setup(self):
        self.env["TEST_BREW"] = str(self.root / "missing/bin/brew")
        self.stub("curl", "exit 22")
        result = self.run_homebrew()
        self.assertEqual(result.returncode, 22, result.stdout + result.stderr)
        self.assertFalse((self.home / ".zprofile").exists())
        self.assertFalse(list(self.root.glob("tmp.*")))

    def test_skip_install_also_skips_homebrew(self):
        self.stub("brew", 'echo "must not run" >&2; exit 99')
        self.stub("curl", 'echo "must not run" >&2; exit 99')
        self.run_setup("--skip-install")
        self.assertFalse((self.home / ".zprofile").exists())

    def test_windows_paths_and_copy_fallback(self):
        self.env.update(TEST_OS="MINGW64_NT-10.0", APPDATA=str(self.home / "Roaming"),
                        LOCALAPPDATA=str(self.home / "Local"), USERPROFILE=str(self.home))
        self.stub("cygpath", 'printf "%s\\n" "$2"')
        self.stub("powershell.exe", 'printf "powershell %s\\n" "$*" >> "$TEST_LOG"')
        self.stub("ln", "exit 1")
        self.run_setup("--skip-install")
        self.run_setup("--skip-install")
        self.assertEqual((self.home / "Local/warp/Warp/config/keybindings.yaml").read_bytes(),
                         (REPO / "warp_config/keybindings.yaml").read_bytes())
        self.assertTrue((self.home / "Roaming/warp/Warp/data/themes/assassin.jpg").is_file())
        self.assertFalse((self.home / ".config/starship.toml").is_symlink())
        self.assertFalse(list(self.home.rglob("*.backup.*")))

    def test_linux_installer_download_and_package_command(self):
        self.env.update(TEST_OS="Linux", TEST_ARCH="aarch64")
        self.stub("curl", 'printf "curl %s\\n" "$*" >> "$TEST_LOG"\nwhile [ "$1" != -o ]; do shift; done\nprintf package > "$2"')
        self.stub("apt-get", 'printf "apt-get %s\\n" "$*" >> "$TEST_LOG"')
        self.run_setup()
        log = Path(self.env["TEST_LOG"]).read_text()
        self.assertIn("https://app.warp.dev/download?package=deb_arm64", log)
        self.assertIn("sudo apt-get install -y", log)
        self.assertFalse(list(self.root.glob("tmp.*")))

    def test_failed_download_stops_before_config_changes(self):
        self.env["TEST_OS"] = "Linux"
        self.stub("curl", "exit 22")
        self.stub("apt-get", 'echo "must not run" >&2; exit 99')
        result = self.run_setup(success=False)
        self.assertEqual(result.returncode, 22)
        self.assertFalse((self.home / ".config").exists())
        self.assertFalse(list(self.root.glob("tmp.*")))

    def test_starship_installer_executes_only_after_download(self):
        self.stub("curl", '''while [ "$1" != -o ]; do shift; done
cat > "$2" <<'INSTALLER'
printf 'installed %s\\n' "$*" >> "$TEST_LOG"
INSTALLER''')
        result = self.run_function("install_starship_linux")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("installed --yes", Path(self.env["TEST_LOG"]).read_text())
        self.assertFalse(list(self.root.glob("tmp.*")))

    def test_invalid_option_and_unsupported_os_do_not_write(self):
        self.run_setup("--unknown", success=False)
        self.env["TEST_OS"] = "FreeBSD"
        self.run_setup("--skip-install", success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def run_shell_tools(self, platform):
        result = subprocess.run(
            ["/bin/bash", "-c", 'set -euo pipefail; source "$1/scripts/common.sh"; '
             'source "$1/scripts/shell-tools.sh"; PLATFORM="$2"; install_shell_tools',
             "test", str(REPO), platform], env=self.env, cwd=self.root,
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_shell_tools_macos_installs_only_missing_packages(self):
        self.stub("brew", self.brew_stub())
        self.run_shell_tools("macos")
        log = Path(self.env["TEST_LOG"])
        self.assertEqual(log.read_text(), "brew install neovim bat coreutils\n")
        log.unlink()
        for command in ("nvim", "batcat", "gls"):
            self.stub(command, "exit 0")
        self.run_shell_tools("macos")
        self.assertFalse(log.exists())
        (self.bin / "nvim").unlink()
        self.run_shell_tools("macos")
        self.assertEqual(log.read_text(), "brew install neovim\n")

    def test_linux_shell_tools_package_managers(self):
        for manager, arguments in (
            ("apt-get", "install -y neovim bat"),
            ("dnf", "install -y neovim bat"),
            ("zypper", "--non-interactive install neovim bat"),
            ("pacman", "-S --needed --noconfirm neovim bat"),
        ):
            with self.subTest(manager=manager):
                self.stub(manager, 'printf "manager %s\\n" "$*" >> "$TEST_LOG"')
                self.run_shell_tools("linux")
                log = Path(self.env["TEST_LOG"])
                self.assertIn(f"manager {arguments}\n", log.read_text())
                self.assertNotIn("coreutils", log.read_text())
                if manager == "apt-get":
                    self.assertLess(log.read_text().index("manager update"), log.read_text().index("manager install"))
                log.unlink()
                (self.bin / manager).unlink()

    def test_shell_tools_windows_is_optional(self):
        self.run_shell_tools("windows")
        self.assertFalse(Path(self.env["TEST_LOG"]).exists())


if __name__ == "__main__":
    unittest.main()
