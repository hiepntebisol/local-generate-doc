#!/bin/bash
set -euo pipefail

# ---------------------------
# API docs downloader + merge + build (robust merge for yq v4.x)
# ---------------------------

USER_AGENT="Japanticket-api-request-bot"

echo "🌐 Choose environment:"
echo "1) Local (http://localhost:8082)"
echo "2) Dev   (https://api.dev.japanticket.com)"
read -rp "Enter number [1-2]: " choice

case "$choice" in
  1) BASE_URL="http://localhost:8082" ;;
  2) BASE_URL="https://api.dev.japanticket.com" ;;
  *) echo "❌ Invalid choice"; exit 1 ;;
esac

CONFIG_URL="$BASE_URL/v3/api-docs/swagger-config"

echo "📡 Fetching swagger-config from $CONFIG_URL ..."
CONFIG_JSON=$(curl -sSf -H "user-agent: $USER_AGENT" "$CONFIG_URL")

# Tạo mảng groups[] bằng while-read (tương thích POSIX)
groups=()
while IFS= read -r name; do
    groups+=("$name")
done < <(echo "$CONFIG_JSON" | yq -r '.urls[].name')

if [[ ${#groups[@]} -eq 0 ]]; then
  echo "❌ No groups found!"
  exit 1
fi

echo "✅ Found ${#groups[@]} groups:"
index=0
for group in "${groups[@]}"; do
    echo "$index. $group"
    ((index++))
done

read -p "Enter numbers separated by space or comma [0]: " CHOICES
CHOICES=${CHOICES:-0}

# normalize: replace commas with spaces and trim repeated spaces
CHOICES=$(echo "$CHOICES" | tr ',' ' ' | xargs)
IFS=' ' read -ra SELECTED <<< "$CHOICES"

# validate selections
for c in "${SELECTED[@]}"; do
    if ! [[ "$c" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice: $c"
        exit 1
    fi
    if (( c < 0 || c >= ${#groups[@]} )); then
        echo "Choice out of range: $c"
        exit 1
    fi
done

TMP_FILES=()
OUTPUT_NAME=""

# Download & convert
for choice in "${SELECTED[@]}"; do
    GROUP="${groups[$choice]}"
    echo "You selected: $GROUP"

    BASE_NAME=$(echo "$GROUP" | sed 's/^[0-9]\+-//')
    OUTPUT_JSON="${BASE_NAME}.json"
    OUTPUT_YAML="${BASE_NAME}.yaml"

    API_URL="$BASE_URL/v3/api-docs/${GROUP}"
    echo "📥 Downloading API JSON from $API_URL ..."
    curl -sSf -o "$OUTPUT_JSON" "$API_URL" -H "user-agent: $USER_AGENT"

    echo "🔄 Converting JSON → YAML ..."
    yq -P '.' "$OUTPUT_JSON" | sed 's/\/external\/v2//g' | sed 's/\/\/api\./\/\/openapi\./g' > "$OUTPUT_YAML"
    rm -f "$OUTPUT_JSON"

    TMP_FILES+=("$OUTPUT_YAML")
    OUTPUT_NAME="${OUTPUT_NAME:+$OUTPUT_NAME-}$BASE_NAME"
done

if (( ${#TMP_FILES[@]} == 0 )); then
    echo "No YAML files to process."
    exit 1
fi

# Merge if needed
if (( ${#TMP_FILES[@]} > 1 )); then
    MERGED_YAML="${OUTPUT_NAME}.merged.yaml"
    echo "🔗 Merging ${#TMP_FILES[@]} YAML files into $MERGED_YAML ..."
    cp "${TMP_FILES[0]}" "$MERGED_YAML"
    for ((i = 1; i < ${#TMP_FILES[@]}; i++)); do
        NEXT="${TMP_FILES[$i]}"
        TMP_OUT="${MERGED_YAML}.tmp"
        yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$MERGED_YAML" "$NEXT" > "$TMP_OUT"
        mv "$TMP_OUT" "$MERGED_YAML"
    done
    FINAL_YAML="$MERGED_YAML"
else
    FINAL_YAML="${TMP_FILES[0]}"
fi

OUTPUT_HTML="${OUTPUT_NAME}.html"
echo "📚 Building documentation with Redocly ..."
npx @redocly/cli build-docs "$FINAL_YAML" -o "$OUTPUT_HTML"

echo "✅ Done! Output file: $OUTPUT_HTML"

# 🧹 Remove temp files
for f in "${TMP_FILES[@]}"; do
    rm -f "$f"
done
# Remove merged YAML too (keep only HTML)
if [[ "$FINAL_YAML" == *".merged.yaml" ]]; then
    rm -f "$FINAL_YAML"
fi

# Open HTML file
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$OUTPUT_HTML" || true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "$OUTPUT_HTML" || true
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  start "$OUTPUT_HTML" || true
else
  echo "📄 HTML file created: $OUTPUT_HTML"
fi
