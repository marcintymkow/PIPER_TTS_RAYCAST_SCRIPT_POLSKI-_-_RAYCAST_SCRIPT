Piper TTS — Raycast Script (English)

A Raycast script for generating audio files from text copied to the clipboard. Works **100% locally** — no data is sent to the internet. Uses the [Piper TTS](https://github.com/rhasspy/piper) engine with Polish voices.

---

## ✅ Requirements

| Tool | Installation |
|---|---|
| [Raycast](https://raycast.com) | Download from website |
| Python 3.11 | `brew install python@3.11` |
| ffmpeg | `brew install ffmpeg` |
| Homebrew | [brew.sh](https://brew.sh) |

---

## 🚀 Step-by-step Installation

### 1. Create a Python 3.11 virtual environment

```bash
/opt/homebrew/bin/python3.11 -m venv ~/.venv/xtts
source ~/.venv/xtts/bin/activate
pip install --upgrade pip
pip install piper-tts pathvalidate num2words
```

### 2. Download Polish voice models

```bash
mkdir -p ~/piper-voices
cd ~/piper-voices

# Female voice — Gosia
curl -L -o pl_PL-gosia-medium.onnx \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/pl/pl_PL/gosia/medium/pl_PL-gosia-medium.onnx"
curl -L -o pl_PL-gosia-medium.onnx.json \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/pl/pl_PL/gosia/medium/pl_PL-gosia-medium.onnx.json"

# Male voice — mc_speech
curl -L -o pl_PL-mc_speech-medium.onnx \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/pl/pl_PL/mc_speech/medium/pl_PL-mc_speech-medium.onnx"
curl -L -o pl_PL-mc_speech-medium.onnx.json \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/pl/pl_PL/mc_speech/medium/pl_PL-mc_speech-medium.onnx.json"
```

### 3. Add the script to Raycast

```bash
# Copy script to your Raycast scripts directory
cp xtts-raycast.sh "/Users/YOUR_USER/Documents/Raycast Script/"
chmod +x "/Users/YOUR_USER/Documents/Raycast Script/xtts-raycast.sh"
```

In Raycast: **Settings → Extensions → Script Commands → Add Directories**, select the folder containing the script, then click ⟳ to reload.

### 4. Test the voices

```bash
echo "Witaj, jestem Gosia" | ~/.venv/xtts/bin/python -m piper \
  --model ~/piper-voices/pl_PL-gosia-medium.onnx \
  --output_file /tmp/test.wav && afplay /tmp/test.wav
```

---

## 🎛️ Raycast Parameters

When running the **"Piper TTS - Polski"** command, three dropdowns appear:

| Parameter | Options | Default |
|---|---|---|
| **Voice** | 🙍‍♀️ Gosia (female) / 🙍‍♂️ mc_speech (male) | Gosia |
| **Speed** | 0.5x – 2.0x (in steps of 0.1) | 1.0x |
| **Format** | AAC (.m4a) / MP3 (.mp3) / WAV (.wav) | AAC |

Output sample rate: **64,000 Hz**

---

## 📂 File Structure

```
~/.venv/xtts/          ← Python virtual environment with Piper TTS
~/piper-voices/        ← voice model files (.onnx)
~/Desktop/TTS_Audio/   ← generated audio files
/tmp/tts_*             ← temporary files (cleaned up automatically)
```

---

## 🔧 Text Normalization

Before synthesis, the script automatically processes the text:

- **Numbers → words** (`Chapter 4` → `Chapter four`, `1944` → `nineteen forty-four`)
- **Ordinal numbers** → (`3.` → `third`)
- **Abbreviations** → (`dr` → `doktor`, `tzn.` → `to znaczy`, `m.in.` → `między innymi`, `zł` → `złotych`, `km` → `kilometrów` and more)
- **Punctuation** → em dashes `–—` converted to commas, ellipsis converted to period

> Note: normalization is tuned for Polish text. English text will be read as-is by the Polish voice model.

---

## ⚠️ Troubleshooting

**Script not appearing in Raycast**
```bash
chmod +x "/path/to/xtts-raycast.sh"
# Then click ⟳ in Raycast → Extensions → Script Commands
```

**Error: No module named 'pathvalidate'**
```bash
~/.venv/xtts/bin/pip install pathvalidate
```

**Error: ffmpeg not found**
```bash
brew install ffmpeg
```

**Old temporary files blocking generation**
```bash
rm -f /tmp/tts_out_*.wav /tmp/tts_text_*.txt
```

---

## 📝 Notes

- Clipboard text can be of any length, but generation time increases significantly for texts over ~2000 characters
- Audio files are named after the first sentence of the text (up to 60 characters)
- The script works fully offline after the one-time model download
- Both voice models are approximately 60 MB each

## License

MIT

## Author

Marcin Tymków
