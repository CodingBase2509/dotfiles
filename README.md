# dotfiles

Persönliches Terminal-Setup für Warp und Starship.

## Setup

Das Repo an einem dauerhaften Ort ablegen und ausführen:

```sh
bash init.sh
```

Der Aufruf funktioniert auch aus einem anderen Arbeitsverzeichnis:

```sh
bash /pfad/zu/dotfiles/init.sh
```

Das Setup installiert fehlende Programme, verlinkt die Konfiguration und ergänzt
die Starship-Initialisierung. Vorhandene Programme werden nicht aktualisiert.
Zum ausschließlichen Einrichten der Konfiguration:

```sh
bash init.sh --skip-install
```

`--skip-install` verändert Konfigurationsdateien; es ist kein Probelauf.
Das gesamte Skript als normaler Benutzer ausführen, nicht mit `sudo`.
Einzelne Installationsschritte können Administratorrechte anfordern.

| System | Installation | Voraussetzung |
| --- | --- | --- |
| macOS | Homebrew zuerst; `starship`, Cask `warp`, `neovim`, `bat`, `coreutils` | Bash und curl (mit macOS vorhanden) |
| Linux | Offizieller Starship-Installer; Warp, `neovim` und `bat` über apt-get, dnf, zypper oder pacman | Bash, curl; x86_64 oder ARM64 für Warp |
| Windows | WinGet: `Starship.Starship`, `Warp.Warp` | Git Bash, WinGet und PowerShell |

Auf macOS wird fehlendes Homebrew mit dem offiziellen Installer eingerichtet.
Dessen Bestätigungen und mögliche Passwortabfragen bleiben erhalten. Vorhandene
Installationen unter `/opt/homebrew` (Apple Silicon) und `/usr/local` (Intel)
werden auch gefunden, wenn `brew` noch nicht im `PATH` steht. `brew shellenv`
aktiviert Homebrew sofort für das Setup und wird für spätere Zsh-Login-Sitzungen
in `${ZDOTDIR:-$HOME}/.zprofile` eingetragen. Bei einer anderen macOS-Shell deren
Homebrew-Initialisierung selbst ergänzen. `--skip-install` überspringt auch die
Homebrew-Einrichtung.

Unter Windows `bash init.sh` in **Git Bash** starten. WSL wird als Linux behandelt
und richtet die Linux-Installation ein, nicht die Windows-App.
Andere Linux-Paketmanager werden nicht automatisch unterstützt: Programme zuerst
manuell installieren und anschließend `--skip-install` verwenden.

## Konfigurationspfade

| Datei | macOS | Linux | Windows |
| --- | --- | --- | --- |
| `starship.toml` | `~/.config/starship.toml` | `~/.config/starship.toml` | `%USERPROFILE%\.config\starship.toml` |
| Warp `keybindings.yaml` | `~/.warp/keybindings.yaml` | `${XDG_CONFIG_HOME:-~/.config}/warp-terminal/keybindings.yaml` | `%LOCALAPPDATA%\warp\Warp\config\keybindings.yaml` |
| Warp `themes/` inklusive Bilder | `~/.warp/themes/` | `${XDG_DATA_HOME:-~/.local/share}/warp-terminal/themes/` | `%APPDATA%\warp\Warp\data\themes\` |

Ein gesetztes `STARSHIP_CONFIG` überschreibt den Starship-Zielpfad. Diese Variable
muss dann auch in späteren Shell-Sitzungen gesetzt sein. Benutzerdefinierte Pfade
müssen absolut sein.

Die Dateien bleiben im Repo und werden einzeln verlinkt. Dadurch wirken sich
Änderungen im Repo direkt aus; das Repo anschließend nicht verschieben oder
löschen. Fremde Themes bleiben erhalten. Abweichende vorhandene Zieldateien,
Verzeichnisse oder kaputte Symlinks erhalten vor dem Ersetzen eine Sicherung
mit dem Suffix `.backup.…` neben ihrem ursprünglichen Pfad.

Unter Windows versucht das Setup native Symlinks. Falls die nötigen Rechte
fehlen, kopiert es die Dateien. In diesem Fall nach Änderungen im Repo erneut
`bash init.sh --skip-install` ausführen. Gleiche Kopien bleiben unverändert.

## Shell und Warp aktivieren

Auf macOS/Linux erkennt das Setup die aufrufende Shell (Bash, Zsh oder Fish).
Wenn diese nicht erkannt wird, verwendet es die Standard-Shell aus `$SHELL`.
Starship wird für diese Shell eingerichtet. Bereits vorhandene RC-Dateien dieser
Shells werden für Starship ebenfalls ergänzt.
`ZDOTDIR` und der Fish-Pfad unter `XDG_CONFIG_HOME` werden berücksichtigt.
Für Bash wird außerdem das wirksame Login-Profil mit `.bashrc` verbunden.
Vor Änderungen werden vorhandene RC-Dateien gesichert. Bereits erkannte
Starship-Initialisierungen werden nicht nochmals angehängt.

Unter Windows werden die `CurrentUserAllHosts`-Profile der installierten
Windows-PowerShell- und PowerShell-7-Editionen eingerichtet. Die PowerShell-
Ausführungsrichtlinie muss lokale Skripte erlauben; das Setup ändert sie nicht.
Das Profil lädt `shell_config/alias.ps1` per Dot-Sourcing direkt aus dem Repo.
Diese Datei enthält Git-, VS-Code- und Navigationskürzel. Git und `code` müssen
im `PATH` verfügbar sein; nur dann werden ihre Kürzel definiert.
Git Bash selbst erhält unter Windows keine Prompt-Konfiguration.

Nach dem Setup:

1. Shell und Warp neu starten, damit neue Programme im `PATH` verfügbar sind.
2. In Warp unter **Settings → Appearance → Input** den Typ **Shell (PS1)** wählen.
3. Unter **Themes** eines der bereitgestellten Themes auswählen.
4. Für die Symbole im Prompt eine Nerd Font installieren und in Warp auswählen.

Für Bash und Zsh ergänzt das Setup zusätzlich einen `source`-Eintrag für
`shell_config/alias.sh` vor der ersten Starship-Initialisierung:

- Bash: `~/.bashrc`.
- Zsh: `${ZDOTDIR:-$HOME}/.zshrc`.

Der Loader ersetzt die frühere Repo-`.zshrc` und lädt alle Dateien unter
`shell_config/aliases/` direkt aus dem Repo. Die persönliche RC-Datei bleibt
erhalten und wird vor Änderungen gesichert. Erneute Setup-Aufrufe fügen den
gleichen Eintrag nicht nochmals hinzu. Die Alias-Einbindung erfolgt nur für
die erkannte Shell. Fish erhält keine Aliase; PowerShell verwendet `alias.ps1`.
Die bisherige `ICLOUD`-Variable wird vom Loader auf macOS mit dem absoluten
Pfad zum iCloud-Drive-Verzeichnis gesetzt.

Zum Einrichten ohne Paketinstallationen `bash init.sh --skip-install` ausführen
und anschließend eine neue Shell öffnen.

## Zusatztools und Aliase

Das Setup installiert Neovim und Bat auf macOS/Linux nur, wenn ihre Befehle fehlen.
Ein vorhandenes `batcat` wird ebenfalls als Bat erkannt. macOS erhält zusätzlich
GNU `ls` (`gls`) aus Homebrews `coreutils`. Unter Linux wird das vorhandene `ls`
verwendet; bei fehlender Unterstützung für `--color=auto` bleiben die einfachen
Kürzel `l` und `ll` verfügbar. Unter Windows bleiben diese Zusatztools optional;
PowerShell erhält ausschließlich die Git-, VS-Code- und Navigationskürzel aus
`alias.ps1`. Die Bash-/Zsh-Alias-Dateien werden dort nicht geladen.

PowerShell unterscheidet Groß- und Kleinschreibung bei Befehlsnamen nicht:
`gbd` löscht einen Branch mit `-d`, `gbdf` erzwingt es mit `-D` (statt `gbD`).
Belegte PowerShell-Kürzel wie `gc`, `gi`, `gl`, `gp` und `gm` werden bei
vorhandenem Git durch die entsprechenden Git-Funktionen ersetzt. Die ursprünglichen
Cmdlets bleiben unter ihren vollständigen Namen verfügbar.

Beim Laden der Alias-Dateien wird die Verfügbarkeit erneut geprüft:

- `vi` / `vim` nur mit `nvim`.
- `cat` nur mit `bat` oder alternativ `batcat`.
- `c` / `c.` nur mit dem VS-Code-Befehl `code`.
- Git-Kürzel nur mit `git`, `_` nur mit `sudo`.
- Farboptionen für `ls` und `grep` nur mit passender Unterstützung.

VS Code und Git werden nicht zusätzlich durch diesen Schritt installiert.
Ohne Zusatztools bleiben die ursprünglichen Systembefehle erhalten. GNU `ls`
wird gezielt per Alias verwendet; die Alias-Dateien verändern `PATH` und
`MANPATH` nicht mehr pauschal für sämtliche GNU-Tools. Nach einer Tool-Installation
eine neue Shell öffnen, damit die Alias-Dateien erneut geladen werden.

## Aufbau

```text
init.sh                         Einstieg und Ablauf
scripts/common.sh               OS-Erkennung, Pfade, Backups und Verlinkung
scripts/homebrew.sh              Homebrew auf macOS installieren und aktivieren
scripts/install.sh              Installation über den jeweiligen Paketmanager
scripts/shell-tools.sh          Fehlende Zusatztools für macOS/Linux installieren
scripts/aliases.sh               Alias-Loader in die passende RC-Datei eintragen
scripts/starship.sh              Starship-Konfiguration und Shell-Anbindung
scripts/powershell-profile.ps1   Native PowerShell-Profile unter Windows
scripts/warp.sh                  Verteilen der Warp-Konfiguration
shell_config/alias.sh            Gemeinsamer Alias-Loader für Bash und Zsh
shell_config/alias.ps1           Git-, VS-Code- und Navigationskürzel für PowerShell
shell_config/aliases/            Alias-Definitionen nach Themen
tests/test_setup.py              Isolierte Tests ohne echte Installation
```

Tests ausführen:

```sh
python3 -B -m unittest discover -s tests -v
```

Die Tests verwenden temporäre Benutzerverzeichnisse und simulierte Programme.
Echte Paketinstallationen sowie Windows-Symlinks und PowerShell müssen zusätzlich
auf den jeweiligen Betriebssystemen geprüft werden.

Referenzen: [Homebrew-Installation](https://docs.brew.sh/Installation),
[Warp-Installation](https://docs.warp.dev/getting-started/quickstart/installation-and-setup/),
[Warp-Dateipfade](https://docs.warp.dev/terminal/settings/file-locations/),
[Warp-Prompt](https://docs.warp.dev/terminal/appearance/prompt/),
[Starship-Setup](https://starship.rs/guide/),
[Starship-Konfiguration](https://starship.rs/config/),
[Neovim-Installation](https://github.com/neovim/neovim/blob/master/INSTALL.md),
[Bat-Installation](https://github.com/sharkdp/bat#installation),
[Homebrew-Coreutils](https://formulae.brew.sh/formula/coreutils).
