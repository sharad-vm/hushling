from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import anthropic
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Hushling API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DURATION_MAP = {
    "short":  "150–200 words",
    "medium": "300–350 words",
    "long":   "500–550 words",
}


class StoryRequest(BaseModel):
    characters: str
    moral: str
    duration: str


class StoryResponse(BaseModel):
    story: str


@app.post("/generate-story", response_model=StoryResponse)
async def generate_story(req: StoryRequest):
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="ANTHROPIC_API_KEY not set in .env")

    word_count = DURATION_MAP.get(req.duration, DURATION_MAP["medium"])

    prompt = f"""You are a gentle, imaginative storyteller who specializes in soothing bedtime stories for babies and toddlers (ages 0–5).

Write a bedtime story with the following details:
- Main character(s): {req.characters}
- Moral or lesson: {req.moral}
- Length: {word_count}

Guidelines:
- Use simple, soft, rhythmic language that soothes and calms
- Include gentle sensory details (soft breeze, warm blankets, twinkling stars, cozy nests)
- Build toward a peaceful, sleepy ending where the character(s) drift off to sleep
- Weave the moral naturally into the story — never preachy, always felt
- Use gentle repetition or soft rhymes sparingly to create a lullaby-like rhythm
- Avoid anything scary, exciting, or stimulating
- Written for a parent to read aloud slowly and lovingly at bedtime

Begin the story directly — no title, no preamble, no commentary afterward."""

    try:
        client = anthropic.Anthropic(api_key=api_key)
        message = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}],
        )
        story = message.content[0].text.strip()
        return StoryResponse(story=story)
    except anthropic.APIError as e:
        raise HTTPException(status_code=502, detail=f"Claude API error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def preview():
    html = Path(__file__).parent.parent / "app" / "preview.html"
    return FileResponse(str(html), media_type="text/html")
