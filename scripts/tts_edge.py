import argparse
import asyncio
import edge_tts

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--text_file", required=True)
    p.add_argument("--voice", required=True)
    p.add_argument("--out_mp3", required=True)
    return p.parse_args()

async def main():
    args = parse_args()
    with open(args.text_file, "r", encoding="utf-8") as f:
        text = f.read().strip()
    if not text:
        raise SystemExit("Empty transcript")

    communicate = edge_tts.Communicate(text=text, voice=args.voice)
    await communicate.save(args.out_mp3)

if __name__ == "__main__":
    asyncio.run(main())
