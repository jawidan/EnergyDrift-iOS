import io
import json
import random

from flask import Flask, Response, request
from PIL import Image

app = Flask(__name__)

SEED = 42

JSON_SIZES = {
    "small": 1 * 1024,
    "standard": 10 * 1024,
    "large": 100 * 1024,
}

IMAGE_SIZES = {
    "small": 50 * 1024,
    "medium": 200 * 1024,
    "large": 1024 * 1024,
}

IMAGE_DIMENSIONS = {
    "small": (400, 300),
    "medium": (800, 600),
    "large": (1600, 1200),
}


def make_json_bytes(target_size):
    template = {"id": "energydrift", "seed": SEED, "payload": ""}
    base = json.dumps(template).encode("utf-8")
    pad_len = max(0, target_size - len(base))
    template["payload"] = "A" * pad_len
    return json.dumps(template).encode("utf-8")


def make_jpeg_bytes(width, height, target_size, seed):
    rng = random.Random(seed)
    img = Image.new("RGB", (width, height))
    pixels = img.load()
    for y in range(height):
        base_row = (y * 255) // max(height - 1, 1)
        for x in range(width):
            base_col = (x * 255) // max(width - 1, 1)
            r = (base_row + seed) % 256
            g = (base_col + seed) % 256
            b = (base_row + base_col) % 256
            pixels[x, y] = (r, g, b)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=85)
    content = buf.getvalue()

    if len(content) > target_size:
        raise RuntimeError(
            f"generated JPEG ({len(content)} bytes) exceeds target size ({target_size} bytes); "
            "reduce IMAGE_DIMENSIONS or quality"
        )

    pad_len = target_size - len(content)
    return content + (b"\x00" * pad_len)


JSON_PAYLOADS = {name: make_json_bytes(size) for name, size in JSON_SIZES.items()}

IMAGE_PAYLOADS = {
    name: make_jpeg_bytes(*IMAGE_DIMENSIONS[name], size, SEED)
    for name, size in IMAGE_SIZES.items()
}


@app.after_request
def add_no_store(response):
    response.headers["Cache-Control"] = "no-store"
    return response


@app.route("/health")
def health():
    return {"status": "ok"}


@app.route("/json/small")
def json_small():
    return Response(JSON_PAYLOADS["small"], mimetype="application/json")


@app.route("/json/standard")
def json_standard():
    return Response(JSON_PAYLOADS["standard"], mimetype="application/json")


@app.route("/json/large")
def json_large():
    return Response(JSON_PAYLOADS["large"], mimetype="application/json")


@app.route("/image/small")
def image_small():
    return Response(IMAGE_PAYLOADS["small"], mimetype="image/jpeg")


@app.route("/image/medium")
def image_medium():
    return Response(IMAGE_PAYLOADS["medium"], mimetype="image/jpeg")


@app.route("/image/large")
def image_large():
    return Response(IMAGE_PAYLOADS["large"], mimetype="image/jpeg")


@app.route("/post", methods=["POST"])
def post():
    request.get_json(silent=True, force=True)
    return {"ack": True}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
