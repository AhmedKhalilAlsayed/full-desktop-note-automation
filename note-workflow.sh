#! /bin/env bash
# Author: Ahmed Khalil
# Improvements: Copilot


# The directory structure

# sketch
#		notes/docs
#		lec
#			notes/docs


#########################################################
# private functions

_get_sketch_prefix() {
    local full_path="$PWD"
    
    # 1. Check if we are inside a sketch folder hierarchy
    if [[ "$full_path" =~ (.*_sketch)(.*) ]]; then
        local sketch_dir="${BASH_REMATCH[1]}"
        local sub_path="${BASH_REMATCH[2]}"
        
        # Get sketch name (e.g., "linux_sketch" -> "linux")
        local sketch_name=$(basename "$sketch_dir" | sed -E 's/_sketch$//')
        
        # Clean sub-directories (remove dates like 2026-07-21_ and suffixes like _lec, _note)
        local clean_sub=""
        if [ -n "$sub_path" ]; then
            clean_sub=$(echo "$sub_path" | sed -E 's/\/[0-9]{4}-[0-9]{2}-[0-9]{2}_/\//g; s/_(lec|note|sketch)//g; s/^\///; s/\//_/g')
        fi
        
        if [ -n "$clean_sub" ]; then
            echo "${sketch_name}_${clean_sub}_"
        else
            echo "${sketch_name}_"
        fi
    else
        # If run outside a sketch folder, return nothing
        echo ""
    fi
}


######################################################
# Core functions

# make a sketch dir
msketch() {
    # 1. Clean the input name (replace spaces with underscores)
    local topic="${1// /-}"
    local dir="${topic}_sketch"
    
    # 2. Create the directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo ">> Created new sketch: $dir"
    fi
    
    # 3. Move into it safely
    cd "$dir" || return
    
    # 4. Show what is inside (lecs and docs) so you know where you are
    echo ">> Current Sketch: $dir"
    echo ">> Available Lectures & Notes:"
    ls -F --color=auto 2>/dev/null | grep '/'
}


# make a lec in sketch
mlec() {
    local name="${1// /-}"
    local date_prefix="$(date --iso-8601)"
    
    local dir="${date_prefix}_${name}_lec"
    
    # Build full prefix starting from sketch
    local prefix=$(_get_sketch_prefix)
    local file="${prefix}${name}_lec.md"
    
    if [ -d "$dir" ]; then
        cd "$dir" || return
        code -n $(ls *.md 2>/dev/null || echo "$file")
    else
        mkdir -p "$dir" && cd "$dir" || return
        echo -n "- " > "$file"
        code -n "$file"
    fi
    echo ">> Lecture Workspace: $dir"
}


# make a note in sketch dir or lec dir
mnote() {
    local name="${1// /-}"
    local date_prefix="$(date --iso-8601)"
    
    local dir="${date_prefix}_${name}_note"
    
    # Build full prefix starting from sketch
    local prefix=$(_get_sketch_prefix)
    local file="${prefix}${name}_note.md"
    
    if [ -d "$dir" ]; then
        cd "$dir" || return
        code -n $(ls *.md 2>/dev/null || echo "$file") && cd ..
    else
        mkdir -p "$dir" && cd "$dir" || return
        echo -n "- " > "$file"
        code -n "$file" && cd ..
    fi
    
    notify-send -t 5000 "Learning" "Learn&Think Not Memorize. This is not an exam."
}


#####################################################
# spaced-repetition

# Spaced-repetition settings. Edit these values to change the review ranges
# and the maximum number of files selected for each range.
SPACED_REPETITION_RECENT_DAYS=7
SPACED_REPETITION_MEDIUM_MIN_DAYS=20
SPACED_REPETITION_MEDIUM_MAX_DAYS=40
SPACED_REPETITION_LONG_MIN_DAYS=80
SPACED_REPETITION_LONG_MAX_DAYS=100
SPACED_REPETITION_MAX_RECENT=3
SPACED_REPETITION_MAX_MEDIUM=2
SPACED_REPETITION_MAX_LONG=1

gspaced-repetition() {
    local target_dirs=()
    local doc_types=()
    
    # Parse prefixed file-type options first, then treat remaining arguments as directories.
    while [[ $# -gt 0 ]]; do
        case "${1,,}" in
            -md|-pdf|-txt|-doc|-docx|-odt|-rtf|-epub)
                doc_types+=("${1:1}")
                ;;
            -both)
                doc_types+=(md pdf)
                ;;
            -all)
                doc_types=(md pdf txt doc docx odt rtf epub)
                ;;
            -*)
                echo "Usage: gspaced-repetition [-md] [-pdf] [-both] [directory ...]" >&2
                return 2
                ;;
            *)
                target_dirs+=("$1")
                ;;
        esac
        shift
    done
    
    # Default to current directory if no path was provided
    if [ ${#target_dirs[@]} -eq 0 ]; then
        target_dirs=(".")
    fi

    if [ ${#doc_types[@]} -eq 0 ]; then
        doc_types=(md pdf txt doc docx odt rtf epub)
    fi

    local find_name_args=()
    for doc_type in "${doc_types[@]}"; do
        if [ ${#find_name_args[@]} -gt 0 ]; then
            find_name_args+=(-o)
        fi
        find_name_args+=(-iname "*.${doc_type}")
    done
    
    local total_max=$((SPACED_REPETITION_MAX_RECENT + SPACED_REPETITION_MAX_MEDIUM + SPACED_REPETITION_MAX_LONG))
    
    local quotes=(
        # "Recall, don't relearn! Skim headings and move on."
        # "Not an exam! You're refreshing map locations, not memorizing text."
        # "If it's complex, schedule a dedicated session. NOT NOW!"
        "Your notes are your external brain. You only need conceptual awareness."
        # "Don't stare at words without absorbing. Keep it moving!"
        "Focus on fast retrieval, not perfection."
        "For a long, productive career, not a one-day college exam."
        "Not in marathon!!!"
        "التطبيق والشغل بايدك هو الي بيعلم بجد"
        "شوف الشغل واتعلم منه"
        # "Saving your Saturday for real project work!"
    )
    
    local random_quote="${quotes[$RANDOM % ${#quotes[@]}]}"
    
    echo "========================================================="
    echo ">> Spaced Repetition Review Dashboard <<"
    echo "Target Directories:"
    for dir in "${target_dirs[@]}"; do
        echo "  - $(realpath "$dir")"
    done
    echo "Max Review Target  : $total_max files max"
    echo "---------------------------------------------------------"
    echo "💡 REMINDER: $random_quote"
    echo "========================================================="
    
    # 1. Recent Review
    echo -e "\n[!] Fresh Notes (Last $SPACED_REPETITION_RECENT_DAYS days | Max: $SPACED_REPETITION_MAX_RECENT):"
    # echo -e "\n[!] These are new. No problem"
    while IFS= read -r note; do
        _print_terminal_link "$note"
    done < <(find "${target_dirs[@]}" \( "${find_name_args[@]}" \) -mtime -"$SPACED_REPETITION_RECENT_DAYS" 2>/dev/null | shuf -n "$SPACED_REPETITION_MAX_RECENT" | sort)
    
    # 2. Medium-Term Review
    echo -e "\n[!] ~1 Month Ago ($SPACED_REPETITION_MEDIUM_MIN_DAYS-$SPACED_REPETITION_MEDIUM_MAX_DAYS days | Max: $SPACED_REPETITION_MAX_MEDIUM):"
    echo -e "[!] Should be easy?"
    while IFS= read -r note; do
        _print_terminal_link "$note"
    done < <(find "${target_dirs[@]}" \( "${find_name_args[@]}" \) -mtime +"$SPACED_REPETITION_MEDIUM_MIN_DAYS" -mtime -"$SPACED_REPETITION_MEDIUM_MAX_DAYS" 2>/dev/null | shuf -n "$SPACED_REPETITION_MAX_MEDIUM" | sort)
    
    # 3. Long-Term Review
    echo -e "\n[!] ~3 Months Ago ($SPACED_REPETITION_LONG_MIN_DAYS-$SPACED_REPETITION_LONG_MAX_DAYS days | Max: $SPACED_REPETITION_MAX_LONG):"
    while IFS= read -r note; do
        _print_terminal_link "$note"
    done < <(find "${target_dirs[@]}" \( "${find_name_args[@]}" \) -mtime +"$SPACED_REPETITION_LONG_MIN_DAYS" -mtime -"$SPACED_REPETITION_LONG_MAX_DAYS" 2>/dev/null | shuf -n "$SPACED_REPETITION_MAX_LONG" | sort)
}

############################################################

# Print a clickable file:// link when the output is an interactive terminal.
_print_terminal_link() {
    local path="$1"
    local label="${2:-$path}"
    local absolute_path
    local uri

    absolute_path=$(realpath -- "$path") || return 1
    uri=$(printf '%s' "$absolute_path" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/#/%23/g' -e 's/?/%3F/g')
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        printf '\033]8;;file://%s\033\\%s\033]8;;\033\\\n' "$uri" "$label"
    else
        printf '%s\n' "$label"
    fi
}

# Get all document files across one or multiple sketches
gsketch() {
    local target_dirs=()
    local doc_types=()

    for arg in "$@"; do
        case "${arg,,}" in
            -md|-pdf|-txt|-doc|-docx|-odt|-rtf|-epub)
                doc_types+=("${arg:1}")
                ;;
            -both)
                doc_types+=(md pdf)
                ;;
            -all)
                doc_types=(md pdf txt doc docx odt rtf epub)
                ;;
            -*)
                echo "Usage: gsketch-all [-md] [-pdf] [-both] [directory ...]" >&2
                return 2
                ;;
            *)
                target_dirs+=("$arg")
                ;;
        esac
    done

    if [ ${#target_dirs[@]} -eq 0 ]; then
        target_dirs=(".")
    fi

    if [ ${#doc_types[@]} -eq 0 ]; then
        doc_types=(md pdf txt doc docx odt rtf epub)
    fi

    local find_name_args=()
    for doc_type in "${doc_types[@]}"; do
        if [ ${#find_name_args[@]} -gt 0 ]; then
            find_name_args+=(-o)
        fi
        find_name_args+=(-iname "*.${doc_type}")
    done
    
    echo ">> All Documents (Sorted By Last Modified; click a path to open it):"
    while IFS= read -r entry; do
        _print_terminal_link "${entry#* }"
    done < <(find "${target_dirs[@]}" \( "${find_name_args[@]}" \) -printf "%T@ %p\n" 2>/dev/null | sort -n)
}

############################################################

# Get all directories whose names contain "sketch", shown as a tree
gsketches() {
    local target_dirs=("$@")
    if [ ${#target_dirs[@]} -eq 0 ]; then
        target_dirs=(".")
    fi

    echo ">> Sketch Directories (Sorted Tree; click a path to open it):"
    for root in "${target_dirs[@]}"; do
        local root_path
        root_path=$(realpath "$root") || continue
        _print_terminal_link "$root_path" "+-- $(basename "$root_path") [$root_path]"
        while IFS= read -r sketch_dir; do
            local relative_path depth prefix label
            relative_path="${sketch_dir#"$root_path"/}"
            depth=$(awk -F/ '{print NF}' <<< "$relative_path")
            prefix=$(printf '%*s' $((depth * 3)) '')
            label="${prefix}+-- $(basename "$sketch_dir") [$sketch_dir]"
            _print_terminal_link "$sketch_dir" "$label"
        done < <(find "$root_path" -mindepth 1 -type d -iname "*sketch*" -print 2>/dev/null | sort -f -V)
    done
}

################################################################

# to change dir to the parent of md/pdf file
# uses: when you want to open the dir itself of the md/pdf file, use this cdp()
cdp(){
    cd $(dirname $(realpath "$1"));
}