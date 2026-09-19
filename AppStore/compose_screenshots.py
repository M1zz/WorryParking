#!/usr/bin/env python3
"""Compose App Store marketing screenshots (6.5", 1242x2688) from raw simulator captures.

Usage: python3 compose_screenshots.py <raw_dir> <out_dir>
  raw_dir contains {ko,en}/{lot,park,ticket,gate,log}.png captured by capture_screenshots.sh
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1242, 2688
S = W / 1320  # layout below is designed at 1320 wide


def px(value):
    return round(value * S)


ASPHALT_TOP = (28, 30, 35)
ASPHALT_BOTTOM = (16, 17, 20)
YELLOW = (255, 204, 56)
WHITE = (246, 244, 238)
GRAY = (160, 164, 173)

SD_GOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
SF = "/System/Library/Fonts/SFNS.ttf"

# {text} is drawn in yellow.
COPY = {
    "ko": [
        ("lot", "걱정은 잠시\n{주차}해 두세요", "밤새 싣고 다니지 않아도 괜찮아요"),
        ("park", "머릿속 걱정을\n{그대로} 적어요", "얼마나 시끄러운지, 언제 다시 볼지만 정하면 끝"),
        ("ticket", "걱정 시간 전까지\n{안 봐도} 돼요", "주차된 걱정은 가려져요. 지금은 네 일이 아니야."),
        ("gate", "걱정 시간에만\n{15분} 마주하기", "정말 일어났는지 확인하고, 보내주거나 계획을 세워요"),
        ("log", "걱정의 {78%}는\n일어나지 않았어요", "출차 기록이 쌓이면 내 걱정의 패턴이 보여요"),
    ],
    "en": [
        ("lot", "Park your {worries}\nfor later", "You don't have to carry them all night."),
        ("park", "Write it down\n{exactly} as it sounds", "Rate how loud it is. Pick when it comes back."),
        ("ticket", "{Hidden} until\nWorry Time", "Parked worries stay blurred. Not your job right now."),
        ("gate", "Face it for\njust {15 minutes}", "Check what really happened. Let it go or make a plan."),
        ("log", "{78%} of your fears\nnever came true", "Your Exit Log shows how often worries really happen."),
    ],
}


def font(lang, size, heavy):
    if lang == "ko":
        return ImageFont.truetype(SD_GOTHIC, size, index=14 if heavy else 2)
    f = ImageFont.truetype(SF, size)
    f.set_variation_by_name("Heavy" if heavy else "Medium")
    return f


def segments(line):
    """Split 'a {b} c' into [(a, False), (b, True), (c, False)]."""
    out, buf, hi = [], "", False
    for ch in line:
        if ch in "{}":
            if buf:
                out.append((buf, hi))
            buf, hi = "", ch == "{"
        else:
            buf += ch
    if buf:
        out.append((buf, hi))
    return out


def draw_centered_rich(draw, y, line, fnt):
    parts = segments(line)
    widths = [draw.textlength(t, font=fnt) for t, _ in parts]
    x = (W - sum(widths)) / 2
    for (text, hi), w in zip(parts, widths):
        draw.text((x, y), text, font=fnt, fill=YELLOW if hi else WHITE)
        x += w


def background():
    bg = Image.new("RGB", (W, H))
    pen = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        pen.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(ASPHALT_TOP, ASPHALT_BOTTOM)))
    return bg


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask


def compose(lang, shot, headline, subtitle, raw_dir):
    img = background()
    draw = ImageDraw.Draw(img)

    # Headline + subtitle
    head_font = font(lang, px(112 if lang == "ko" else 108), heavy=True)
    sub_font = font(lang, px(46), heavy=False)
    y = px(150)
    for line in headline.split("\n"):
        draw_centered_rich(draw, y, line, head_font)
        y += px(140)
    y += px(26)
    sub_w = draw.textlength(subtitle, font=sub_font)
    draw.text(((W - sub_w) / 2, y), subtitle, font=sub_font, fill=GRAY)

    # Phone geometry
    raw = Image.open(raw_dir / lang / f"{shot}.png").convert("RGB")
    screen_w = px(960)
    screen_h = round(screen_w * raw.height / raw.width)
    bezel = px(24)
    phone_w, phone_h = screen_w + bezel * 2, screen_h + bezel * 2
    px0 = (W - phone_w) // 2
    py0 = H - phone_h - px(90)
    screen_r = px(128)
    phone_r = screen_r + bezel

    # Parking bay: the phone is "parked" between two yellow lines, open at the front.
    bay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bay)
    gap, line_w, top = px(58), px(14), py0 + px(220)
    for x in (px0 - gap - line_w, px0 + phone_w + gap):
        bd.rectangle([x, top, x + line_w, H], fill=YELLOW + (150,))
    img.paste(bay, (0, 0), bay)

    # Shadow
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px0, py0 + px(30), px0 + phone_w, py0 + phone_h + px(30)], radius=phone_r, fill=(0, 0, 0, 170)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(px(50)))
    img.paste(shadow, (0, 0), shadow)

    # Frame
    frame = ImageDraw.Draw(img)
    frame.rounded_rectangle([px0, py0, px0 + phone_w, py0 + phone_h], radius=phone_r, fill=(8, 8, 10))
    frame.rounded_rectangle(
        [px0, py0, px0 + phone_w, py0 + phone_h], radius=phone_r, outline=(78, 81, 90), width=px(4)
    )

    # Screen
    screen = raw.resize((screen_w, screen_h), Image.LANCZOS)
    img.paste(screen, (px0 + bezel, py0 + bezel), rounded_mask((screen_w, screen_h), screen_r))
    return img


def main():
    raw_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    for lang, items in COPY.items():
        (out_dir / lang).mkdir(parents=True, exist_ok=True)
        for index, (shot, headline, subtitle) in enumerate(items, start=1):
            path = out_dir / lang / f"{index:02d}_{shot}.png"
            compose(lang, shot, headline, subtitle, raw_dir).save(path, optimize=True)
            print(path)


if __name__ == "__main__":
    main()
