#!/usr/bin/env bash

configure_warp() {
    local source_file relative_path destination
    # Link files individually so unrelated user themes and settings survive.
    while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$REPO_ROOT/warp_config/"}"
        case "$relative_path" in
            themes/*|workflows/*|tab_configs/*|default_tab_configs/*|launch_configurations/*)
                destination="$WARP_DATA_DIR/$relative_path"
                ;;
            *) destination="$WARP_CONFIG_DIR/$relative_path" ;;
        esac
        link_file "$source_file" "$destination"
    done < <(find "$REPO_ROOT/warp_config" -type f ! -name .DS_Store -print0)
}
