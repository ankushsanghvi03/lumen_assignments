#!/bin/bash

ORDER_DIR="./orders"
REPORT_DIR="./reports"
ALERT_DIR="./alert_logs"
DATE=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_DIR/sales_$DATE.csv"
ALERT_LOG="$ALERT_DIR/alert_log.txt"

mkdir -p "$REPORT_DIR" "$ALERT_DIR"

write_alert() {
    echo "$(date '+%F %T') : $1" >> "$ALERT_LOG"
}

validate_files() {
    [ -d "$ORDER_DIR" ] || { write_alert "ERROR: ORDER_DIR missing"; exit 1; }

    ls "$ORDER_DIR"/*.csv >/dev/null 2>&1 || {
        write_alert "ERROR: No CSV files found"
        exit 1
    }

    for file in "$ORDER_DIR"/*.csv; do
        [ -s "$file" ] || {
            write_alert "ERROR: Empty file $file"
            exit 1
        }
    done
}

generate_csv() {
    echo "Store/Category,Revenue,Orders,Failed,Status" > "$REPORT_FILE"

    for csv_file in "$ORDER_DIR"/*.csv; do

        failed_count=$(grep -c ",FAILED," "$csv_file")
        pending_count=$(grep -c ",PENDING," "$csv_file")
        refund_count=$(grep -c ",REFUNDED," "$csv_file")

        echo "Failed: $failed_count | Pending: $pending_count | Refunded: $refund_count"

        top_orders=$(grep ",COMPLETED," "$csv_file" | cut -d',' -f5 | sort -nr | head -5)
        echo "$top_orders" >/dev/null

        revenue=$(awk -F',' '$3=="COMPLETED"{sum+=$5} END{printf "%.2f",sum}' "$csv_file")
        total=$(awk 'END{print NR-1}' "$csv_file")
        avg=$(awk -F',' '$3=="COMPLETED"{sum+=$5;c++} END{if(c>0) printf "%.2f",sum/c; else print 0}' "$csv_file")

        if [ "$failed_count" -gt 30 ]; then
            status="CRITICAL"
            write_alert "$(basename "$csv_file"): CRITICAL"
        elif [ "$refund_count" -gt 20 ]; then
            status="WARNING"
            write_alert "$(basename "$csv_file"): WARNING"
        else
            status="OK"
            write_alert "$(basename "$csv_file"): OK"
        fi

        category=$(basename "$csv_file" .csv)

        echo "$category,$revenue,$total,$failed_count,$status" >> "$REPORT_FILE"

        echo "Processed: $category | Revenue=$revenue | Avg=$avg"
    done
}

show_menu() {
    while true; do
        echo "1. Process today's orders"
        echo "2. Generate CSV report"
        echo "3. View alert log"
        echo "4. Exit"
        read -p "Select [1-4]: " choice

        case $choice in
            1) validate_files; generate_csv ;;
            2) generate_csv ;;
            3) cat "$ALERT_LOG" ;;
            4) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    done
}

show_menu
