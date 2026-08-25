#!/bin/bash

# Rebuild ever-held union from all 11 weekly snapshots + pre-announcement

PRE="./omnom-snapshot-pre-announcement.csv"
WEEKLY_DIR="./weekly"
OUTPUT="./omnom-snapshot-ever-held.csv"
TEMP=$(mktemp)

echo "Rebuilding ever-held union..."

# Get header from pre-announcement
head -1 "$PRE" > "$OUTPUT"

# Build temporary file with all wallets from all sources
cat "$PRE" | tail -n +2 >> "$TEMP"
for f in weekly-2026-*.csv; do
    echo "Adding $f..."
    cat "$f" | tail -n +2 >> "$TEMP"
done

# Remove duplicates based on address (column 2), keeping max balance
# Format: rank,address,balance_raw,balance_formatted,percentage
# We need to re-rank after deduplication

echo "Deduplicating and re-ranking..."

awk -F',' '
BEGIN { OFS="," }
{
    addr = tolower($2)
    bal_raw = $3
    bal_fmt = $4
    pct = $5
    
    if (addr in seen) {
        # Keep the one with higher balance
        if (bal_raw > seen[addr]) {
            seen[addr] = bal_raw
            data[addr] = bal_raw "," bal_fmt "," pct
        }
    } else {
        seen[addr] = bal_raw
        data[addr] = bal_raw "," bal_fmt "," pct
    }
}
END {
    # Collect all addresses with their max data
    for (addr in seen) {
        print seen[addr] "," addr "," data[addr]
    }
}
' "$TEMP" | sort -t',' -k1,1rn | awk -F',' '
BEGIN { OFS=","; rank = 0 }
{
    rank++
    print rank "," $2 "," $3 "," $4 "," $5
}
' >> "$OUTPUT"

rm "$TEMP"

echo "Done. Count:"
tail -n +2 "$OUTPUT" | wc -l
