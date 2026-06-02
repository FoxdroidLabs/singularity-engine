from PIL import Image

sizes = [(48, 48), (32, 32), (16, 16)]
paths = [
    "src/core/window/icon48.raw",
    "src/core/window/icon32.raw",
    "src/core/window/icon16.raw",
]

for (w, h), out in zip(sizes, paths):
    img = Image.open("assets/singularity.png").convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)
    with open(out, "wb") as f:
        f.write(img.tobytes())

print("Done.")
