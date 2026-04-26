{ lib, pkgs, ... }:

let
  launcherShortcuts = {
    "Alacritty.desktop" = {
      key = "_launch";
      shortcut = "Ctrl+Alt+T";
      description = "Launch Alacritty";
    };

    # Clear Plasma's usual terminal shortcut so Alacritty can own it.
    "org.kde.konsole.desktop" = {
      key = "_launch";
      shortcut = "none";
      description = "Launch Konsole";
    };
  };

  setIniEntry = ''
    set_ini_entry() {
      local file="$1"
      local section="$2"
      local key="$3"
      local value="$4"
      local tmp

      tmp="$(mktemp)"

      ${lib.getExe pkgs.gawk} \
        -v section="$section" \
        -v key="$key" \
        -v value="$value" \
        '
          BEGIN {
            in_section = 0
            section_found = 0
            key_written = 0
          }

          function write_key() {
            if (!key_written) {
              print key "=" value
              key_written = 1
            }
          }

          /^\[/ {
            if (in_section && !key_written) {
              write_key()
            }

            in_section = ($0 == "[" section "]")
            if (in_section) {
              section_found = 1
            }
          }

          {
            if (in_section && $0 ~ ("^" key "=")) {
              if (!key_written) {
                print key "=" value
                key_written = 1
              }
              next
            }

            print
          }

          END {
            if (in_section && !key_written) {
              write_key()
            }

            if (!section_found) {
              print ""
              print "[" section "]"
              print key "=" value
            }
          }
        ' "$file" > "$tmp"

      mv "$tmp" "$file"
    }
  '';
in
{
  home.packages = [ pkgs.sxhkd ];

  home.activation.configurePlasmaKeybinds = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setIniEntry}

    config_file="$HOME/.config/kglobalshortcutsrc"
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        section: entry:
        let
          value = "${entry.shortcut},${entry.shortcut},${entry.description}";
        in
        ''
          set_ini_entry \
            "$config_file" \
            "${section}" \
            "${entry.key}" \
            '${value}'
        ''
      ) launcherShortcuts
    )}
  '';
}
