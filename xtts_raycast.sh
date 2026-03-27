#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Piper TTS - Polski
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🎙️
# @raycast.packageName Audio Tools
# @raycast.description Generuje audio z tekstu w schowku (Piper TTS, głosy PL)
# @raycast.argument1 { "type": "dropdown", "title": "Głos", "placeholder": "Wybierz głos", "data": [{"title": "🙍‍♀️ Gosia (żeński)", "value": "gosia"}, {"title": "🙍‍♂️ mc_speech (męski)", "value": "mc_speech"}], "default": "gosia" }
# @raycast.argument2 { "type": "dropdown", "title": "Szybkość", "placeholder": "Szybkość mowy", "data": [{"title": "0.5x", "value": "0.5"}, {"title": "0.6x", "value": "0.6"}, {"title": "0.7x", "value": "0.7"}, {"title": "0.8x", "value": "0.8"}, {"title": "0.9x", "value": "0.9"}, {"title": "1.0x (normalna)", "value": "1.0"}, {"title": "1.1x", "value": "1.1"}, {"title": "1.2x", "value": "1.2"}, {"title": "1.3x", "value": "1.3"}, {"title": "1.4x", "value": "1.4"}, {"title": "1.5x", "value": "1.5"}, {"title": "1.6x", "value": "1.6"}, {"title": "1.7x", "value": "1.7"}, {"title": "1.8x", "value": "1.8"}, {"title": "1.9x", "value": "1.9"}, {"title": "2.0x", "value": "2.0"}], "default": "1.0" }
# @raycast.argument3 { "type": "dropdown", "title": "Format", "placeholder": "Format pliku", "data": [{"title": "AAC (.m4a)", "value": "m4a"}, {"title": "MP3 (.mp3)", "value": "mp3"}, {"title": "WAV (.wav)", "value": "wav"}], "default": "m4a" }

# Documentation:
# @raycast.author marcin
# @raycast.authorURL https://raycast.com/marcin

# ─────────────────────────────────────────────
# KONFIGURACJA
# ─────────────────────────────────────────────

PYTHON_BIN="$HOME/.venv/xtts/bin/python"
VOICES_DIR="$HOME/piper-voices"
OUTPUT_DIR="$HOME/Desktop/TTS_Audio"
OUTPUT_RATE="64000"

VOICE="$1"
SPEED="$2"
EXT="$3"

# Wybór modelu
if [ "$VOICE" = "mc_speech" ]; then
  VOICE_MODEL="$VOICES_DIR/pl_PL-mc_speech-medium.onnx"
  VOICE_LABEL="mc_speech (męski)"
else
  VOICE_MODEL="$VOICES_DIR/pl_PL-gosia-medium.onnx"
  VOICE_LABEL="Gosia (żeński)"
fi

# ─────────────────────────────────────────────
# SPRAWDZENIA
# ─────────────────────────────────────────────

TEXT=$(pbpaste)

if [ -z "$TEXT" ]; then
  echo "❌ Schowek jest pusty. Skopiuj tekst przed uruchomieniem."
  exit 1
fi

if [ ! -f "$PYTHON_BIN" ]; then
  echo "❌ Nie znaleziono Pythona: $PYTHON_BIN"
  exit 1
fi

if [ ! -f "$VOICE_MODEL" ]; then
  echo "❌ Nie znaleziono modelu: $VOICE_MODEL"
  exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
  echo "❌ ffmpeg nie jest zainstalowany. Zainstaluj: brew install ffmpeg"
  exit 1
fi

# ─────────────────────────────────────────────
# NAZWA PLIKU Z PIERWSZEGO ZDANIA
# ─────────────────────────────────────────────

FIRST_SENTENCE=$(echo "$TEXT" | head -1 | sed 's/[.!?].*//' | cut -c1-60)
SAFE_NAME=$(echo "$FIRST_SENTENCE" | tr '/:*?"<>|\\' '_' | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | tr ' ' '_')
if [ -z "$SAFE_NAME" ]; then
  SAFE_NAME="speech_$(date +%Y%m%d_%H%M%S)"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
UNIQUE="${TIMESTAMP}_$$"
WAV_TMP="/tmp/tts_out_${UNIQUE}.wav"
TMPFILE="/tmp/tts_text_${UNIQUE}.txt"
OUTPUT_FILE="$OUTPUT_DIR/${SAFE_NAME}.${EXT}"

mkdir -p "$OUTPUT_DIR"
pbpaste > "$TMPFILE"

CHAR_COUNT=${#TEXT}
echo "📋 Tekst ze schowka (${CHAR_COUNT} znaków)"
echo "────────────────────────────────────────"
echo "${TEXT:0:200}$([ $CHAR_COUNT -gt 200 ] && echo '...')"
echo "────────────────────────────────────────"
echo "🎤 Głos:        $VOICE_LABEL"
echo "⏩ Szybkość:    ${SPEED}x"
echo "📁 Format:      .${EXT} @ ${OUTPUT_RATE} Hz"
echo "💾 Plik:        ${SAFE_NAME}.${EXT}"
echo "🔊 Generowanie audio..."

# ─────────────────────────────────────────────
# NORMALIZACJA TEKSTU (Python)
# ─────────────────────────────────────────────

"$PYTHON_BIN" - <<PYEOF
import sys, re

try:
    from num2words import num2words
except ImportError:
    num2words = None

def normalize_pl(text):
    skroty = {
        r'\bdr\b': 'doktor', r'\bprof\b': 'profesor', r'\bmgr\b': 'magister',
        r'\binż\b': 'inżynier', r'\bnr\b': 'numer', r'\bstr\b': 'strona',
        r'\brozd\b': 'rozdział', r'\broz\b': 'rozdział',
        r'\bitp\.?': 'i tym podobne', r'\bitd\.?': 'i tak dalej',
        r'\btzw\.?': 'tak zwany', r'\btj\.?': 'to jest',
        r'\bm\.in\.?': 'między innymi', r'\bwg\b': 'według',
        r'\bdot\b': 'dotyczy', r'\bzł\b': 'złotych',
        r'\bkm\b': 'kilometrów', r'\bcm\b': 'centymetrów',
        r'\bmm\b': 'milimetrów', r'\bkg\b': 'kilogramów',
        r'\bgodz\b': 'godzina', r'\bmin\b': 'minut', r'\bsek\b': 'sekund',
    }
    for pattern, replacement in skroty.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

    if num2words:
        def ordinal_pl(m):
            try: return num2words(int(m.group(1)), lang='pl', to='ordinal') + ' '
            except: return m.group(0)
        text = re.sub(r'\b(\d+)\.\s', ordinal_pl, text)

        def cardinal_pl(m):
            try: return num2words(int(m.group(0)), lang='pl')
            except: return m.group(0)
        text = re.sub(r'\b\d+\b', cardinal_pl, text)

    text = re.sub(r'[„""«»]', '"', text)
    text = re.sub(r'[–—]', ', ', text)
    text = re.sub(r'\.{2,}', '.', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

with open("$TMPFILE", "r", encoding="utf-8") as f:
    raw = f.read().strip()

normalized = normalize_pl(raw)
print(f"📝 Po normalizacji: {normalized[:200]}")

with open("$TMPFILE", "w", encoding="utf-8") as f:
    f.write(normalized)
PYEOF

# ─────────────────────────────────────────────
# GENEROWANIE WAV przez Piper
# ─────────────────────────────────────────────

cat "$TMPFILE" | "$PYTHON_BIN" -m piper \
  --model "$VOICE_MODEL" \
  --output_file "$WAV_TMP" 2>/dev/null

PIPER_EXIT=$?
rm -f "$TMPFILE"

if [ $PIPER_EXIT -ne 0 ] || [ ! -f "$WAV_TMP" ]; then
  echo "❌ Piper nie wygenerował pliku."
  exit 1
fi

echo "✅ WAV wygenerowany"

# ─────────────────────────────────────────────
# FILTRY FFMPEG — szybkość + sample rate
# ─────────────────────────────────────────────

build_atempo() {
  local speed=$1
  if awk "BEGIN{exit !($speed < 0.5)}"; then
    echo "atempo=0.5,atempo=$(echo "$speed 0.5" | awk '{printf "%.4f", $1/$2}')"
  elif awk "BEGIN{exit !($speed > 2.0)}"; then
    echo "atempo=2.0,atempo=$(echo "$speed 2.0" | awk '{printf "%.4f", $1/$2}')"
  else
    echo "atempo=${speed}"
  fi
}

ATEMPO=$(build_atempo "$SPEED")
FILTER="${ATEMPO},aresample=${OUTPUT_RATE}"

echo "🔄 Konwersja ffmpeg..."

case "$EXT" in
  m4a)
    ffmpeg -y -i "$WAV_TMP" -af "$FILTER" -c:a aac -b:a 128k "$OUTPUT_FILE" -loglevel error
    ;;
  mp3)
    ffmpeg -y -i "$WAV_TMP" -af "$FILTER" -c:a libmp3lame -q:a 2 "$OUTPUT_FILE" -loglevel error
    ;;
  wav)
    ffmpeg -y -i "$WAV_TMP" -af "$FILTER" "$OUTPUT_FILE" -loglevel error
    ;;
esac

FFMPEG_EXIT=$?
rm -f "$WAV_TMP"

if [ $FFMPEG_EXIT -ne 0 ]; then
  echo "❌ Konwersja nie powiodła się."
  exit 1
fi

# ─────────────────────────────────────────────
# ODTWARZANIE
# ─────────────────────────────────────────────

echo "▶️  Odtwarzanie..."
afplay "$OUTPUT_FILE"
echo "🏁 Gotowe! Plik: $OUTPUT_FILE"
