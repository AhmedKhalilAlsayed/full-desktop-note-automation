#! /bin/env bash
# Author: Ahmed Khalil
# Improvements: Copilot


# The directory structure

# sketch
#       sketch
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
    
    notify-send -t 5000 "Learning" "Learn Not Memorize. This is not an exam."
}


#####################################################
# spaced-repetition

# Spaced-repetition settings. Edit these values to change the review windows
# and the maximum number of files selected for each window.

# Recent: files modified within the last week.
SPACED_REPETITION_RECENT_DAYS=7
# Past: files modified after the recent window, up to this age.
# Use max day count OR "*" to include all older documents.
SPACED_REPETITION_PAST_MAX_DAYS="*" #70
# Maximum number of files selected from each window.
SPACED_REPETITION_MAX_RECENT=3
SPACED_REPETITION_MAX_PAST=2
# local database path
SPACED_REPETITION_DB="${XDG_DATA_HOME:-$HOME/.local/share}/full-desktop-note-automation/repetition.tsv"

gspaced-repetition() {
    local target_dirs=()
    local doc_types=()

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

    mkdir -p "$(dirname "$SPACED_REPETITION_DB")" || {
        echo "Could not create spaced-repetition database directory: $(dirname "$SPACED_REPETITION_DB")" >&2
        return 1
    }
    touch "$SPACED_REPETITION_DB" || {
        echo "Could not open spaced-repetition database: $SPACED_REPETITION_DB" >&2
        return 1
    }

    local now
    now=$(date +%s)
    local recent_candidates past_candidates
    recent_candidates=$(mktemp) || return 1
    past_candidates=$(mktemp) || {
        rm -f "$recent_candidates"
        return 1
    }

    while IFS= read -r note; do
        local path modified age_days rating next_review priority candidate_file
        path=$(realpath -- "$note") || continue
        modified=$(stat -c %Y -- "$path") || continue
        age_days=$(( (now - modified) / 86400 ))
        if (( age_days < SPACED_REPETITION_RECENT_DAYS )); then
            candidate_file="$recent_candidates"
        elif [ "$SPACED_REPETITION_PAST_MAX_DAYS" = "*" ] ||
             (( age_days < SPACED_REPETITION_PAST_MAX_DAYS )); then
            candidate_file="$past_candidates"
        else
            continue
        fi
        IFS=$'\t' read -r rating next_review < <(awk -F '\t' -v path="$path" '$1 == path { print $2 "\t" $4; found=1 } END { if (!found) print "0\t0" }' "$SPACED_REPETITION_DB")
        if [ "$rating" != "0" ] && [ "$next_review" -gt "$now" ]; then
            continue
        fi
        if [ "$rating" = "4" ]; then
            continue
        elif [ "$rating" = "0" ]; then
            priority=0
        elif [ "$next_review" -le "$now" ]; then
            priority=$((1 + rating))
        else
            priority=$((10 + rating))
        fi
        printf '%03d\t%s\n' "$priority" "$path" >> "$candidate_file"
    done < <(find "${target_dirs[@]}" -type f \( "${find_name_args[@]}" \) -print 2>/dev/null | sort -u)

    local -a recent_list past_list review_list
    mapfile -t recent_list < <(sort -n -k1,1 -k2,2 "$recent_candidates" | cut -f2- | awk '!seen[$0]++' | head -n "$SPACED_REPETITION_MAX_RECENT")
    mapfile -t past_list < <(sort -n -k1,1 -k2,2 "$past_candidates" | cut -f2- | awk '!seen[$0]++' | head -n "$SPACED_REPETITION_MAX_PAST")
    rm -f "$recent_candidates" "$past_candidates"
    review_list=("${recent_list[@]}" "${past_list[@]}")
    if [ ${#review_list[@]} -eq 0 ]; then
        echo "No documents are due in the configured review windows."
        return 0
    fi

    while [ ${#review_list[@]} -gt 0 ]; do
        echo "========================================================="
        echo ">> Spaced Repetition Review"
        echo "Choose a document to review (q to quit):"
        local index=1
        local section_note display_path
        if [ ${#recent_list[@]} -gt 0 ]; then
            echo "-- Recent (last $SPACED_REPETITION_RECENT_DAYS days) --"
            for section_note in "${recent_list[@]}"; do
                display_path="${section_note#"$PWD"/}"
                printf '%2d) ' "$index"
                _print_terminal_link "$section_note" "$display_path"
                ((index++))
            done
        fi
        if [ ${#past_list[@]} -gt 0 ]; then
            if [ "$SPACED_REPETITION_PAST_MAX_DAYS" = "*" ]; then
                echo "-- Past ($SPACED_REPETITION_RECENT_DAYS+ days ago) --"
            else
                echo "-- Past ($SPACED_REPETITION_RECENT_DAYS-$SPACED_REPETITION_PAST_MAX_DAYS days ago) --"
            fi
            for section_note in "${past_list[@]}"; do
                display_path="${section_note#"$PWD"/}"
                printf '%2d) ' "$index"
                _print_terminal_link "$section_note" "$display_path"
                ((index++))
            done
        fi
        printf 'Selection: '
        local selection
        read -r selection || break
        [ "$selection" = "q" ] || [ "$selection" = "Q" ] && break
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#review_list[@]} )); then
            echo "Please choose a listed number or q."
            continue
        fi

        local selected="${review_list[$((selection - 1))]}"
        xdg-open "$selected" >/dev/null 2>&1 &
        printf 'Feedback (1=hard/important, 2=good/normal, 3=easy/repeated, 4=skip permanently): '
        local feedback
        read -r feedback || break
        if ! [[ "$feedback" =~ ^[1234]$ ]]; then
            echo "Feedback must be 1, 2, 3, or 4; the document was not recorded."
            continue
        fi

        if [ "$feedback" = "4" ]; then
            local temp_db
            temp_db=$(mktemp) || return 1
            awk -F '\t' -v OFS='\t' -v path="$selected" '$1 != path' "$SPACED_REPETITION_DB" > "$temp_db"
            printf '%s\t4\t%s\t0\t0\n' "$selected" "$now" >> "$temp_db"
            mv "$temp_db" "$SPACED_REPETITION_DB"
            echo "Skipped permanently. It will not appear in future reviews."
            for list_name in recent_list past_list; do
                declare -n current_list="$list_name"
                for list_index in "${!current_list[@]}"; do
                    if [ "${current_list[$list_index]}" = "$selected" ]; then
                        unset "current_list[$list_index]"
                    fi
                done
                current_list=("${current_list[@]}")
            done
            review_list=("${recent_list[@]}" "${past_list[@]}")
            continue
        fi

        local interval_days
        case "$feedback" in
            1) interval_days=1 ;;
            2) interval_days=7 ;;
            3) interval_days=30 ;;
        esac
        local next_review=$((now + interval_days * 86400))
        local temp_db
        temp_db=$(mktemp) || return 1
        awk -F '\t' -v OFS='\t' -v path="$selected" '$1 != path' "$SPACED_REPETITION_DB" > "$temp_db"
        printf '%s\t%s\t%s\t%s\t%s\n' "$selected" "$feedback" "$now" "$next_review" "$interval_days" >> "$temp_db"
        mv "$temp_db" "$SPACED_REPETITION_DB"
        for list_name in recent_list past_list; do
            declare -n current_list="$list_name"
            for list_index in "${!current_list[@]}"; do
                if [ "${current_list[$list_index]}" = "$selected" ]; then
                    unset "current_list[$list_index]"
                fi
            done
            current_list=("${current_list[@]}")
        done
        review_list=("${recent_list[@]}" "${past_list[@]}")
        echo "Recorded feedback $feedback. Next review in $interval_days day(s)."
    done
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
