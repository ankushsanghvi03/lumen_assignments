#!/bin/bash

############################
# Task 01 - Environment Setup
############################

LOG_DIR="./logs"
REPORT_DIR="./reports"
SCRIPT_LOG="./script_logs/script_execution.log"

DATE=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_DIR/report_$DATE.txt"

mkdir -p "$REPORT_DIR"
mkdir -p "./script_logs"

write_log() {
    level="$1"
    message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$SCRIPT_LOG"
}

check_directory() {
    if [ ! -d "$LOG_DIR" ]; then
        write_log "ERROR" "Log directory not found."
        echo "Log directory not found."
        exit 1
    fi

    if ! ls "$LOG_DIR"/*.log >/dev/null 2>&1; then
        write_log "ERROR" "No log files found."
        echo "No log files found."
        exit 1
    fi

    for file in "$LOG_DIR"/*.log; do
        if [ ! -r "$file" ]; then
            write_log "ERROR" "$file is not readable."
            exit 1
        fi
    done

    write_log "INFO" "Input validation successful."
}

clean_line() {
    line="$1"
    echo "$line" | sed 's/[[:space:]]\+/ /g' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'
}

SERVERS=""
INFOS=""
WARNS=""
ERRORS=""
STATUSS=""

process_log_file() {
    logfile="$1"
    server=$(basename "$logfile" .log)

    info_count=$(awk '$3=="INFO"{count++} END{print count+0}' "$logfile")
    warn_count=$(awk '$3=="WARNING"{count++} END{print count+0}' "$logfile")
    error_count=$(awk '$3=="ERROR"{count++} END{print count+0}' "$logfile")

    while IFS= read -r line; do
        cleaned=$(clean_line "$line")
    done < "$logfile"

    if [ "$error_count" -gt 10 ]; then
        status="CRITICAL"
        write_log "WARNING" "High error count in $server"
    elif [ "$warn_count" -gt 20 ]; then
        status="WARNING"
    else
        status="NORMAL"
    fi

    SERVERS+="$server "
    INFOS+="$info_count "
    WARNS+="$warn_count "
    ERRORS+="$error_count "
    STATUSS+="$status "
}

generate_report() {
    echo "Daily Server Health Report" > "$REPORT_FILE"
    echo "Generated : $DATE" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    printf "%-15s %-10s %-10s %-10s %-12s\n" "SERVER" "INFO" "WARNING" "ERROR" "STATUS" >> "$REPORT_FILE"

    read -a s <<< "$SERVERS"
    read -a i <<< "$INFOS"
    read -a w <<< "$WARNS"
    read -a e <<< "$ERRORS"
    read -a st <<< "$STATUSS"

    for ((x=0;x<${#s[@]};x++)); do
        printf "%-15s %-10s %-10s %-10s %-12s\n" \
        "${s[$x]}" "${i[$x]}" "${w[$x]}" "${e[$x]}" "${st[$x]}" >> "$REPORT_FILE"
    done

    write_log "INFO" "Report generated."
    echo "Report created: $REPORT_FILE"
}

show_menu() {
while true; do
    echo
    echo "1. Analyze Logs"
    echo "2. Generate Report"
    echo "3. View Report"
    echo "4. Exit"
    read -p "Enter choice: " choice

    case $choice in
        1)
            write_log "INFO" "Analysis Started"
            check_directory
            SERVERS=""
            INFOS=""
            WARNS=""
            ERRORS=""
            STATUSS=""
            for f in "$LOG_DIR"/*.log; do
                process_log_file "$f"
            done
            echo "Analysis Completed."
            ;;
        2)
            generate_report
            ;;
        3)
            if [ -f "$REPORT_FILE" ]; then
                cat "$REPORT_FILE"
            else
                echo "Report not found."
            fi
            ;;
        4)
            write_log "INFO" "Script completed."
            exit 0
            ;;
        *)
            echo "Invalid Choice"
            ;;
    esac
done
}

write_log "INFO" "Script Started"
show_menu
