#!/usr/bin/env python3
"""App Store 크리에이티브 자산(제품 페이지 헤더 · 검색 결과) 생성: HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_creative_assets.py [언어 ...]     (없으면 전부)

자리
  docs/screenshots/creative/<로케일>/header.png   3840x1646  제품 페이지 맨 위
  docs/screenshots/creative/<로케일>/search.png   3840x2560  검색 결과

기기 화면은 AppStore/capture_screenshots.sh 가 찍은 docs/screenshots/raw/<로케일>/*.png 를 쓴다.
검색 결과의 헤드라인 · 보조 문장은 스크린샷 1장(AppStore/compose_screenshots.py 의 COPY 첫 줄)을
그대로 가져온다 — 검색에서 본 말이 페이지에서도 이어지게.

⚠️ 안전 영역 밖은 기기에 따라 잘린다. 글은 **반드시** 안전 영역 안에 둔다(배경 · 기기 그림은 넘쳐도 된다).
   수치는 Apple 공식 PSD 템플릿에서 잰 값이다(https://developer.apple.com/app-store/asset-best-practices/).
⚠️ 가격 · 할인 · 주소(URL) · 수상 · 다른 플랫폼 이름은 넣지 않는다(Apple 가이드).
"""
import importlib.util, html, re, subprocess, sys, pathlib, tempfile, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "creative"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

spec = importlib.util.spec_from_file_location("compose", ROOT / "AppStore" / "compose_screenshots.py")
compose = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compose)

# (가로, 세로, 안전 영역 left, top, right, bottom)
SPEC = {
    "header": (3840, 1646, (1097, 493, 2743, 1154)),
    "search": (3840, 2560, (836, 765, 3004, 1795)),
}

# 검색 결과의 눈썹글 = 그 나라 사람이 검색창에 치는 말.
EYEBROW = {
    "ko": "불안·걱정 정리", "en": "Anxiety relief", "en-GB": "Anxiety relief",
    "zh-Hans": "缓解焦虑", "zh-Hant": "舒緩焦慮", "ja": "不安・心配ごと",
    "ru": "Тревога и сон", "es": "Ansiedad y sueño", "de": "Grübeln stoppen",
    "fr": "Anxiété et sommeil", "it": "Ansia e sonno", "pt-BR": "Ansiedade e sono",
    "th": "คลายความกังวล", "vi": "Giảm lo âu", "cs": "Úzkost a spánek",
    "da": "Angst og søvn", "el": "Άγχος και ύπνος", "fi": "Ahdistus ja uni",
    "id": "Atasi rasa cemas", "nb": "Angst og søvn", "nl": "Stoppen met piekeren",
    "pl": "Lęk i sen", "sv": "Oro och sömn", "tr": "Kaygı ve uyku",
}

# 헤더는 한 가지 약속만: 걱정을 여기 맡기면 오늘 밤은 가벼워진다.
# 눈썹글은 그 언어의 앱 이름(APPSTORE.md). {…} 는 노란 글씨.
HEADER = {
    "ko":      ("걱정 주차장", "걱정은 여기 {맡기고}<br>오늘 밤은 가볍게"),
    "en":      ("Worry Parking", "{Park} the worry.<br>Get your evening back."),
    "en-GB":   ("Worry Parking", "{Park} the worry.<br>Get your evening back."),
    "zh-Hans": ("烦恼停车场", "烦恼先{停}这儿，<br>今晚轻松一点"),
    "zh-Hant": ("煩惱停車場", "煩惱先{停}這裡，<br>今晚輕鬆一點"),
    "ja":      ("心配パーキング", "心配はここに{駐車}。<br>今夜は軽やかに"),
    "ru":      ("Парковка тревог", "{Оставьте} тревогу здесь.<br>Вечер снова ваш."),
    "es":      ("Parking de Preocupaciones", "{Aparca} aquí la preocupación.<br>Recupera tu noche."),
    "de":      ("Sorgen-Parkplatz", "{Stell} die Sorge hier ab.<br>Der Abend gehört dir."),
    "fr":      ("Parking des Soucis", "{Gare} ton souci ici.<br>Ta soirée t'appartient."),
    "it":      ("Parcheggio Preoccupazioni", "{Parcheggia} qui l'ansia.<br>La serata torna tua."),
    "pt-BR":   ("Estacionamento de Preocupações", "{Estacione} a preocupação.<br>A noite volta a ser sua."),
    "th":      ("ที่จอดความกังวล", "{ฝาก}ความกังวลไว้ที่นี่<br>คืนนี้นอนสบายขึ้น"),
    "vi":      ("Bãi đỗ lo âu", "{Gửi} nỗi lo ở đây,<br>tối nay nhẹ nhõm hơn"),
    "cs":      ("Parkoviště starostí", "{Zaparkuj} starost tady.<br>Večer je zase tvůj."),
    "da":      ("Bekymringsparkering", "{Parkér} bekymringen her.<br>Aftenen er din igen."),
    "el":      ("Πάρκινγκ Ανησυχιών", "{Πάρκαρε} εδώ την ανησυχία.<br>Η βραδιά είναι ξανά δική σου."),
    "fi":      ("Huolipysäköinti", "{Pysäköi} huoli tähän.<br>Ilta on taas sinun."),
    "id":      ("Parkir Kekhawatiran", "{Parkir} rasa cemasmu di sini.<br>Malam ini jadi lebih ringan."),
    "nb":      ("Bekymringsparkering", "{Parker} bekymringen her.<br>Kvelden er din igjen."),
    "nl":      ("Zorgenparking", "{Parkeer} je zorg hier.<br>Je avond is weer van jou."),
    "pl":      ("Parking Zmartwień", "{Zaparkuj} tu zmartwienie.<br>Wieczór znów jest twój."),
    "sv":      ("Oroparkeringen", "{Parkera} oron här.<br>Kvällen är din igen."),
    "tr":      ("Endişe Otoparkı", "Endişeni buraya {park et}.<br>Akşamın yine senin."),
}

# 검색 결과 글 칸은 좁아서 긴 낱말 하나가 한 줄을 다 먹는 언어가 있다.
# 그런 언어만 스크린샷 1장과 같은 글을 줄만 다르게 끊는다(글은 바꾸지 않는다).
SEARCH_BREAKS = {
    "es":    "Aparca tus\n{preocupaciones}\npara luego",
    "it":    "Parcheggia le\n{preoccupazioni}\nper dopo",
    "pt-BR": "Estacione suas\n{preocupações}\npara depois",
    "da":    "Parkér dine\n{bekymringer}\ntil senere",
    "el":    "Πάρκαρε τις\n{ανησυχίες}\nγια αργότερα",
    "id":    "Parkirkan\n{kekhawatiran}\nuntuk nanti",
}

# 바탕 · 글자색은 스크린샷(AppStore/compose_screenshots.py)과 같다: 아스팔트 + 주차선 노랑.
BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:linear-gradient(#1c1e23, #101114); position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", "Hiragino Sans", "PingFang SC", "Thonburi", sans-serif; }
.text { position:absolute; display:flex; flex-direction:column; justify-content:center; }
.eyebrow { font-weight:700; color:#ffcc38; letter-spacing:-0.01em; line-height:1.15; }
.headline { font-weight:800; color:#f6f4ee; letter-spacing:-0.03em; line-height:1.12; }
.headline b { color:#ffcc38; font-weight:800; }
.sub { font-weight:500; color:#a0a4ad; letter-spacing:-0.01em; line-height:1.35; text-wrap:balance; }
:lang(th) .headline, :lang(th) .eyebrow, :lang(th) .sub,
:lang(ja) .headline, :lang(zh) .headline { letter-spacing:0; }
:lang(th) .headline { line-height:1.3; }
:lang(ko) .headline, :lang(ko) .sub, :lang(ko) .eyebrow { word-break:keep-all; }
.bay { position:absolute; width:44px; background:rgba(255,204,56,.55); }
.phone { position:absolute; background:#08080a; border:6px solid #4e515a; padding:40px; border-radius:190px;
  box-shadow: 0 60px 160px rgba(0,0,0,.65); }
.phone img { width:100%%; display:block; border-radius:152px; }
"""

# 글이 상자를 넘지 않을 때까지 줄인다. 끝까지 안 맞으면 표시하고 멈춘다.
FIT_JS = """
<script>
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(box, el, max, min) {
  const want = el.querySelectorAll('br').length + 1;
  let size = max;
  el.style.fontSize = size + 'px';
  while (size > min && (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 ||
         lines(el) > want)) {
    size -= 4; el.style.fontSize = size + 'px';
  }
  if (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 || lines(el) > want)
    document.body.dataset.overflow = '1';
}
document.fonts.ready.then(() => {
  const box = document.querySelector('.text');
  const h = document.querySelector('.headline');
  fit(box, h, +h.dataset.max, +h.dataset.min);
  document.body.dataset.done = '1';
});
</script>
"""


def rich(text):
    """'a {b}' → 'a <b>b</b>', with the compose script's \\n turned into <br>."""
    text = html.escape(text, quote=False).replace("\n", "<br>")
    return re.sub(r"\{(.*?)\}", r"<b>\1</b>", text)


def phone(img, left, top, width, rotate=0):
    return (f'<div class="phone" style="left:{left}px;top:{top}px;width:{width}px;'
            f'transform:rotate({rotate}deg)"><img src="{img}"></div>')


def bay(left, top, height):
    return f'<div class="bay" style="left:{left}px;top:{top}px;height:{height}px"></div>'


def search_html(lang):
    W, H, (l, t, r, b) = SPEC["search"]
    shot, headline, sub = compose.COPY[lang][0]
    if lang in SEARCH_BREAKS:
        assert SEARCH_BREAKS[lang].split() == headline.split(), f"SEARCH_BREAKS[{lang}] 가 스크린샷 1장 글과 다르다"
        headline = SEARCH_BREAKS[lang]
    sw, sh = r - l, b - t
    col = int(sw * 0.56)
    ph_w = 1040
    ph_left = l + col + int(sw * 0.06)
    img = (RAW / lang / f"{shot}.png").as_uri()
    # 기기는 주차선 두 줄 사이에 "주차" 돼 있다(스크린샷과 같은 모티프). 왼쪽 선은 글 칸(오른끝 2050) 밖에 둔다.
    return f"""
{bay(ph_left - 90, 900, H - 900)}{bay(ph_left + ph_w + 46, 900, H - 900)}
{phone(img, ph_left, t - 360, ph_w)}
<div class="text" style="left:{l}px;top:{t}px;width:{col}px;height:{sh}px">
  <div class="eyebrow" style="font-size:96px">{html.escape(EYEBROW[lang])}</div>
  <div class="headline" data-max="230" data-min="120" style="margin-top:36px">{rich(headline)}</div>
  <div class="sub" style="font-size:80px;margin-top:52px">{html.escape(sub)}</div>
</div>"""


def header_html(lang):
    W, H, (l, t, r, b) = SPEC["header"]
    eyebrow, headline = HEADER[lang]
    sw, sh = r - l, b - t
    left_img = (RAW / lang / "park.png").as_uri()
    right_img = (RAW / lang / "lot.png").as_uri()
    return f"""
{bay(170, 520, H)}{bay(1010, 520, H)}{bay(2830, 520, H)}{bay(3670, 520, H)}
{phone(left_img, 300, 300, 640, -6)}
{phone(right_img, 2900, 300, 640, 6)}
<div class="text" style="left:{l}px;top:{t}px;width:{sw}px;height:{sh}px;align-items:center;text-align:center">
  <div class="eyebrow" style="font-size:76px">{html.escape(eyebrow)}</div>
  <div class="headline" data-max="190" data-min="96" style="margin-top:22px">{rich(headline).replace('&lt;br&gt;', '<br>')}</div>
</div>"""


def render(lang, kind):
    W, H, _ = SPEC[kind]
    body = search_html(lang) if kind == "search" else header_html(lang)
    page = (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>'
            f'{BASE_CSS % {"W": W, "H": H}}</style></head><body>{body}{FIT_JS}</body></html>')
    html_path = pathlib.Path(tempfile.gettempdir()) / f"worryparking-creative-{lang}-{kind}.html"
    html_path.write_text(page, encoding="utf-8")
    flags = ["--headless=new", f"--window-size={W},{H}", "--force-device-scale-factor=1", "--disable-gpu",
             "--virtual-time-budget=3000", "--allow-file-access-from-files"]
    dom = subprocess.run(["nice", "-n", "19", CHROME, *flags, "--dump-dom", html_path.as_uri()],
                         capture_output=True, text=True, timeout=90).stdout
    if 'data-done="1"' not in dom:
        raise SystemExit(f"글 맞추기가 끝나지 않았다: {lang} {kind}")
    if 'data-overflow="1"' in dom:
        raise SystemExit(f"글이 안전 영역을 넘는다: {lang} {kind} - 문구를 줄일 것")
    out_dir = OUT / lang
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{kind}.png"
    time.sleep(2)
    # Chrome 은 가끔 아무것도 안 그리고 끝나거나 멈춘다. 세 번까지 한다.
    for _ in range(3):
        try:
            r = subprocess.run(["nice", "-n", "19", CHROME, *flags, "--hide-scrollbars",
                                f"--screenshot={out_png}", html_path.as_uri()], capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            continue
        if r.returncode == 0 and out_png.exists():
            break
        time.sleep(3)
    else:
        raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
    html_path.unlink(missing_ok=True)
    print(f"rendered {out_png}")
    time.sleep(2)


if __name__ == "__main__":
    langs = sys.argv[1:] or list(HEADER)
    for lang in langs:
        if lang not in HEADER:
            raise SystemExit(f"모르는 언어: {lang} (아는 것: {', '.join(HEADER)})")
        for kind in ("header", "search"):
            render(lang, kind)
