#!/bin/bash
set -uo pipefail
shopt -s nullglob

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

if [ $# -eq 0 ]; then
    echo -e "Usage: ${BOLD}$0 <directory> [directory2 ...]${RESET}"
    echo -e "Example: $0 Dreamcast/ PSX/ N64/"
    exit 1
fi

count_archive_entries() {
    local file="$1"
    local ext="${file##*.}"
    case "${ext,,}" in
        zip)
            unzip -l "$file" 2>/dev/null | tail -1 | awk '{print $2}'
            ;;
        7z)
            local count
            count=$(7z l "$file" 2>/dev/null | grep -oP '\d+(?= file)' | tail -1)
            echo "${count:-0}"
            ;;
    esac
}

for ROOT_DIR in "$@"; do
    ROOT_DIR="${ROOT_DIR%/}"

    if [ ! -d "$ROOT_DIR" ]; then
        echo -e "${YELLOW}SKIP${RESET} '$ROOT_DIR' is not a directory"
        continue
    fi

    system="$(basename "$ROOT_DIR")"
    output_dir="$ROOT_DIR/$system"
    logfile="$ROOT_DIR/extract_errors.log"

    archives=()
    for archive in "$ROOT_DIR"/*.zip "$ROOT_DIR"/*.ZIP "$ROOT_DIR"/*.7z "$ROOT_DIR"/*.7Z; do
        [ -f "$archive" ] || continue
        archives+=("$archive")
    done
    for subdir in "$ROOT_DIR"/*/; do
        [ -d "$subdir" ] || continue
        [[ "$(basename "$subdir")" == "$system" ]] && continue
        for archive in "$subdir"/*.zip "$subdir"/*.ZIP "$subdir"/*.7z "$subdir"/*.7Z; do
            [ -f "$archive" ] || continue
            archives+=("$archive")
        done
    done

    total=${#archives[@]}
    if [ "$total" -eq 0 ]; then
        echo -e "${YELLOW}SKIP${RESET} ${BOLD}$ROOT_DIR${RESET} — no archives found"
        continue
    fi

    mkdir -p "$output_dir"
    : > "$logfile"
    echo -e "${BOLD}${CYAN}[$system]${RESET} ${total} archives → ${BOLD}$output_dir/${RESET}"
    current=0
    failed=0

    for archive in "${archives[@]}"; do
        current=$((current + 1))
        bn="$(basename "$archive")"
        name="${bn%.*}"
        pct=$((current * 100 / total))

        printf "\r\033[K  ${DIM}[%3d/%d %3d%%]${RESET} %s" "$current" "$total" "$pct" "$name"

        entries=$(count_archive_entries "$archive")
        ext="${bn##*.}"

        if [ "${entries:-0}" -gt 1 ] 2>/dev/null; then
            target="$output_dir/$name"
            mkdir -p "$target"
        else
            target="$output_dir"
        fi

        errmsg=""
        case "${ext,,}" in
            zip) errmsg=$(unzip -qo "$archive" -d "$target" 2>&1) ;;
            7z)  errmsg=$(7z x "$archive" -o"$target" -y 2>&1) ;;
        esac
        rc=$?

        if [ $rc -eq 0 ]; then
            printf "\r\033[K  ${GREEN}✓${RESET} ${DIM}[%3d/%d]${RESET} %s\n" "$current" "$total" "$name"
        else
            printf "\r\033[K  ${RED}✗${RESET} ${DIM}[%3d/%d]${RESET} %s ${RED}(exit %d)${RESET}\n" "$current" "$total" "$name" "$rc"
            # Show first meaningful error line inline
            reason=$(echo "$errmsg" | grep -iE 'error|cannot|no such|not found|unsupported|corrupt|broken' | head -1)
            if [ -n "$reason" ]; then
                echo -e "    ${DIM}${reason}${RESET}"
            fi
            # Full log to file
            {
                echo "=== FAILED: $bn ==="
                echo "Archive: $archive"
                echo "Target:  $target"
                echo "Exit:    $rc"
                echo "$errmsg"
                echo ""
            } >> "$logfile"
            failed=$((failed + 1))
        fi
    done

    echo -ne "  ${BOLD}${GREEN}Done${RESET} — $((total - failed)) extracted"
    if [ "$failed" -gt 0 ]; then
        echo -ne ", ${RED}${failed} failed${RESET} — see ${BOLD}$logfile${RESET}"
    else
        rm -f "$logfile"
    fi
    echo -e "\n"
done
