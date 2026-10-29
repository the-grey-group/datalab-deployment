#!/bin/bash
# Apply local patches to the source submodules before deploying.
#
# Patches live in src/patches/<name>/*.patch and are applied, in filename order,
# to the checkout at src/<name> (e.g. src/patches/datalab/ -> src/datalab).
# Patches that are already applied are skipped, so this is safe to re-run.
#
# Usage:
#   ./apply-patches.sh            apply all patches
#   ./apply-patches.sh --revert   un-apply all patches (in reverse order)
set -e -u -o pipefail

PATCHES_ROOT="src/patches"
revert=false
if [ "${1:-}" = "--revert" ]; then
    revert=true
elif [ -n "${1:-}" ]; then
    echo "Usage: $0 [--revert]"
    exit 1
fi

if [ ! -d "$PATCHES_ROOT" ]; then
    echo "No $PATCHES_ROOT directory found; nothing to do."
    exit 0
fi

for patch_dir in "$PATCHES_ROOT"/*/; do
    name=$(basename "$patch_dir")
    target="src/$name"
    if [ ! -d "$target" ]; then
        echo "Error: patches found for '$name' but $target does not exist."
        exit 1
    fi

    if [ "$revert" = true ]; then
        patches=$(find "$patch_dir" -maxdepth 1 -name '*.patch' | sort -r)
    else
        patches=$(find "$patch_dir" -maxdepth 1 -name '*.patch' | sort)
    fi

    for patch in $patches; do
        patch_path=$(realpath "$patch")
        label="$name/$(basename "$patch")"
        if [ "$revert" = true ]; then
            if git -C "$target" apply --check --reverse "$patch_path" 2>/dev/null; then
                git -C "$target" apply --reverse "$patch_path"
                echo "Reverted  $label"
            else
                echo "Skipping  $label (not applied)"
            fi
        else
            if git -C "$target" apply --check --reverse "$patch_path" 2>/dev/null; then
                echo "Skipping  $label (already applied)"
            elif git -C "$target" apply --check "$patch_path" 2>/dev/null; then
                git -C "$target" apply "$patch_path"
                echo "Applied   $label"
            else
                echo "Error: $label does not apply cleanly to $target:"
                git -C "$target" apply --check "$patch_path" || true
                echo "If files 'already exist', the patch is partially applied (e.g. the checkout was"
                echo "reset or updated but new files were left behind): remove those files and re-run."
                exit 1
            fi
        fi
    done
done
