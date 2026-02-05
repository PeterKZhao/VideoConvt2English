#!/usr/bin/env bash
set -euo pipefail

URL="${VIDEO_URL:?VIDEO_URL is required}"
MODEL="${WHISPER_MODEL:-small}"
VOICE="${TTS_VOICE:-en-US-JennyNeural}"

rm -rf out
mkdir -p out

echo "== Downloading video =="
yt-dlp --no-playlist -f "bv*+ba/b" --merge-output-format mp4 -o "out/input.%(ext)s" "$URL"

# 找到下载后的 mp4（有些站点可能是 mkv/webm；这里做个兜底）
VIDEO_FILE="$(ls -1 out/input.* | head -n 1)"
echo "Video: $VIDEO_FILE"

echo "== Extracting audio (16k mono wav) =="
ffmpeg -y -i "$VIDEO_FILE" -vn -ac 1 -ar 16000 -c:a pcm_s16le out/audio.wav

echo "== Whisper translate to English text (TXT) =="
# 输出文件会是 out/audio.txt
whisper out/audio.wav \
  --model "$MODEL" \
  --task translate \
  --language Chinese \
  --output_dir out \
  --output_format txt

echo "== TTS (edge-tts) to MP3 =="
python scripts/tts_edge.py --text_file out/audio.txt --voice "$VOICE" --out_mp3 out/en.mp3

echo "== Mux English audio back into video =="
# 将画面取自原视频、音轨取自英文 mp3；视频流 copy，音频转 AAC，长度以最短为准
ffmpeg -y \
  -i "$VIDEO_FILE" -i out/en.mp3 \
  -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -shortest \
  out/output_en.mp4

echo "== Also export English audio only =="
ffmpeg -y -i out/en.mp3 out/en.wav

echo "Done. Outputs are in out/"
ls -lah out
