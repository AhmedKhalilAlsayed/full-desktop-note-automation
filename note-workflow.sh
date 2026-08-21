#! /bin/env bash


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

mspaced-repetition() {
    local target_dir="${1:-.}"
    local days="${2:-7}"
    local max_short_term="${3:-3}"
    local max_medium_term="${4:-2}"
    local max_long_term="${5:-1}"
    
    local total_max=$((max_short_term + max_medium_term + max_long_term))
    
    # Array of real-world mindset reminders
    local quotes=(
        "Recall, don't relearn! Skim headings and move on."
        "Not an exam! You're refreshing map locations, not memorizing text."
        "If it's complex, schedule a dedicated session. not NOW!"
        "Your notes are your external brain. You only need conceptual awareness."
        "Don't stare at words without absorbing. Keep it moving!"
        "Focus on fast retrieval, not perfection."
        "For a long, productive career, not a one-day college exam."
        "Not in marathon!!!"
        "saving your Saturday for real project work!"
    )
    
    # Pick a random quote for this session
    local random_quote="${quotes[$RANDOM % ${#quotes[@]}]}"
    
    # Trigger desktop notification
    # notify-send -t 6000 "🧠 Spaced Repetition Mode" "$random_quote"
    
    echo "========================================================="
    echo ">> Spaced Repetition Review Dashboard <<"
    echo "Target Directory : $(realpath "$target_dir")"
    echo "Max Review Target: $total_max files max"
    echo "---------------------------------------------------------"
    echo "💡 REMINDER: $random_quote"
    # timer
    # echo -e "\nset ~1h timer"
    echo "========================================================="
    
    # 1. Recent Review (Fresh context)
    echo -e "\n[!] Fresh Notes (Last $days days | Max: $max_short_term):"
    find "$target_dir" -name "*.md" -mtime -"$days" 2>/dev/null | shuf -n "$max_short_term" | sort
    
    # 2. Medium-Term Review (~1 Month ago)
    echo -e "\n[!] ~1 Month Ago (20-40 days | Max: $max_medium_term):"
    find "$target_dir" -name "*.md" -mtime +20 -mtime -40 2>/dev/null | shuf -n "$max_medium_term" | sort
    
    # 3. Long-Term Review (~3 Months ago)
    echo -e "\n[!] ~3 Months Ago (80-100 days | Max: $max_long_term):"
    find "$target_dir" -name "*.md" -mtime +80 -mtime -100 2>/dev/null | shuf -n "$max_long_term" | sort
    
    
}
############################################################

# get all files of the sketch
gsketch() {
    sketch=${1:-.}
    echo ">> All Sketch: (Sorted By Last Modified):";
    find "$sketch" \( -name "*.md" -o -name "*.pdf" \) -printf "%T@ %p\n" | sort -n | cut -d' ' -f2-;
}

# to change dir to the parent of md/pdf file
# uses: when run gsketch-sorted(), you will want to open the dir itself of the md/pdf file, use this cdp()
cdp(){
    cd $(dirname $(realpath "$1"));
}