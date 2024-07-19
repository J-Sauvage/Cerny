#!/usr/bin/env bash

# ------------------------------------------------------------------------------------------------ #
# ---- Logging functions

log(){
    # Basic logger, with 3 levels : INFO  - informational messages
    #                               WARN  - not fatal, but user should still get notified...
    #                               FATAL - Something went very wrong and should get fixed...
    local level message
    read -r level message <<< $(echo $1 $2)
    local reset='\e[97m'
    declare -A levels=([INFO]="\e[32m" [WARN]="\e[33m" [FATAL]="\e[31m")
    local color=${levels["${level}"]}
    level_indicator="[${color}${level}${reset}]"
    echo -e "$level_indicator ${message}"
}

drawline(){
    # Draws a horizontal line of dashes, spanning the entire console length.
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

abort(){
    # Sends a log with FATAL level, accompanied with the line number, exit code and an optional message. 
    # Then, exit.. 
    local exit_code=$?
    local message=$1
    log FATAL "Line ${LINENO}: $message (exit code = ${exit_code})"
    exit $exit_code
}

header(){
   # Calls drawline(), followed by a centered title
   local title=$1
   drawline
   title_len="${#title}"
   COLUMNS=$(tput cols)
   printf "%*s\n" "$(((title_len+COLUMNS)/2))" "$title"
}

# ------------------------------------------------------------------------------------------------ #
# ---- Pattern matching utilities

get_matching_lines(){
    # Get all unique, sorted matching substrings from a given file, using PCRE regex and grep.
    REGEX="$1"
    FILEREPORT="$2"
    grep -oP "${REGEX}" $FILEREPORT | sort -u
}

count_matching_lines(){
    # Apply get_matching_lines() and count the output.
    REGEX="$1"
    FILEREPORT="$2"
    get_matching_lines "$REGEX" "$FILEREPORT" | wc -l
}

get_matching_file_pattern(){
    # Get the sorted, deduplicated list of matches within a directory
    REGEX=$1
    WILDCARDS="${@:2}"
    ls -1 $WILDCARDS | grep -oP $REGEX | sort -u
}

exclude_samples() {
    grep -v -Ff <(cat ${EXCLUDE_FILE} | sed 's/#.*$//' | sed '/^\s*$/d' | sed -e 's/^/\//' -e 's/$/./')
}

# ------------------------------------------------------------------------------------------------ #
# ---- Resource management
WORKERS=0
multithread(){
    # Multithread utility function
    if [[ $WORKERS -ge $THREADS ]]; then
        wait
	WORKERS=0
    fi
    ((WORKERS+=1))
    ${@} &
}

# ------------------------------------------------------------------------------------------------ #
# ---- Download utilities
maybe_download_bam(){
    # Download a URL if it exists in the provided directory. Deletes the output file if wget errors
    # out at some point.
    url=$1
    output_dir=$2
    output_file="${output_dir}/$(basename ${url})"
    if [ ! -f $output_file ]; then
        wget -q -P $output_dir $bam || rm -r "${output_dir}"
    fi 
}

download_filereport(){
    # Simple wrapper to download any bam file matching the provided regex within a filereport
    REGEX="$1"
    FILEREPORT="$2"
    OUTPUT_DIR="$3"
    PROCESSED_BAMS=0
    LINES="$(count_matching_lines $REGEX $FILEREPORT)"
    echo "Downloading bam files matching regex '$REGEX' within $FILEREPORT"
    for bam in $(get_matching_lines $REGEX $FILEREPORT); do
        ((PROCESSED_BAMS+=1))
        echo "[$PROCESSED_BAMS $LINES]: $bam"
	multithread maybe_download_bam $bam "${OUTPUT_DIR}"
    done
    wait
}

