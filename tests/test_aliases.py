"""Check alias behavior with only explicitly provided tools on PATH."""
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SHELLS = ["/bin/bash"]
if shutil.which("zsh"):
    SHELLS.append(shutil.which("zsh"))


class AliasTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-aliases-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("dirname", "readlink"):
            (self.bin / name).symlink_to(shutil.which(name))

    def tool(self, name, body="exit 0"):
        executable = self.bin / name
        executable.write_text("#!/bin/sh\n" + body + "\n")
        executable.chmod(0o755)

    def aliases(self, shell, loader=None):
        options = ["--noprofile", "--norc"] if Path(shell).name == "bash" else ["-f"]
        result = subprocess.run(
            [shell, *options, "-c", '''
source "$1"
alias
''', "test", str(loader or REPO / "shell_config/alias.sh")],
            env={"HOME": str(self.root), "PATH": str(self.bin)},
            cwd=self.root, text=True, capture_output=True, check=True,
        )
        self.assertEqual(result.stderr, "")
        definitions = {}
        for line in result.stdout.splitlines():
            words = shlex.split(line)
            name, value = words[-1].split("=", 1)
            definitions[name] = value
        return definitions

    def test_no_optional_tools_leaves_system_commands_unaliased(self):
        for shell in SHELLS:
            with self.subTest(shell=shell):
                aliases = self.aliases(shell)
                for name in ("vi", "vim", "c", "c.", "cat", "grep", "ls", "l", "ll", "g", "_"):
                    self.assertNotIn(name, aliases)
                self.assertEqual(aliases[".."], "cd .. ")

    def test_available_tools_enable_aliases(self):
        for name in ("nvim", "code", "bat", "batcat", "gls", "git", "sudo", "grep"):
            self.tool(name)
        for shell in SHELLS:
            with self.subTest(shell=shell):
                aliases = self.aliases(shell)
                for name, value in {"vim": "nvim ", "c.": "code .", "cat": "bat",
                                    "ls": "gls --color=auto ", "ll": "gls --color=auto -la ",
                                    "gstd": "git stash drop", "gf": "git fetch --all --prune",
                                    "_": "sudo ", "grep": "grep --color=auto "}.items():
                    self.assertEqual(aliases[name], value)

    def test_linux_ls_and_batcat(self):
        self.tool("ls")
        self.tool("batcat")
        for shell in SHELLS:
            with self.subTest(shell=shell):
                aliases = self.aliases(shell)
                self.assertEqual(aliases["ls"], "ls --color=auto ")
                self.assertEqual(aliases["cat"], "batcat")
                self.assertEqual(aliases["ll"], "ls -la ")

    def test_tools_without_color_support_keep_plain_commands(self):
        self.tool("ls", 'case "$1" in --color=*) exit 2 ;; esac\nexit 0')
        self.tool("grep", 'case "$1" in --color=*) exit 2 ;; esac\nexit 0')
        for shell in SHELLS:
            with self.subTest(shell=shell):
                aliases = self.aliases(shell)
                self.assertNotIn("ls", aliases)
                self.assertNotIn("grep", aliases)
                self.assertEqual(aliases["ll"], "ls -la ")

    def test_loader_resolves_symlinks_and_paths_with_spaces(self):
        directory = self.root / "shell config"
        directory.mkdir()
        loader = directory / "alias.sh"
        loader.symlink_to(REPO / "shell_config/alias.sh")
        relative_link = directory / "relative.sh"
        relative_link.symlink_to("alias.sh")
        self.tool("batcat")
        for shell in SHELLS:
            with self.subTest(shell=shell):
                self.assertEqual(self.aliases(shell, relative_link)["cat"], "batcat")


if __name__ == "__main__":
    unittest.main()
