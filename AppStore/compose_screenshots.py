#!/usr/bin/env python3
"""Compose App Store marketing screenshots (6.5", 1242x2688) from raw simulator captures.

Usage: python3 compose_screenshots.py <raw_dir> <out_dir>
  raw_dir contains <lang>/{lot,park,ticket,gate,log}.png for every language in COPY captured by capture_screenshots.sh
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
    "en-GB": [
        ("lot", "Park your {worries}\nfor later", "You don't have to carry them all night."),
        ("park", "Write it down\n{exactly} as it sounds", "Rate how loud it is. Pick when it comes back."),
        ("ticket", "{Hidden} until\nWorry Time", "Parked worries stay blurred. Not your job right now."),
        ("gate", "Face it for\njust {15 minutes}", "Check what really happened. Let it go or make a plan."),
        ("log", "{78%} of your fears\nnever came true", "Your Exit Log shows how often worries really happen."),
    ],
    "zh-Hans": [
        ("lot", "把烦恼先{停}一停", "不必整晚背着它们。"),
        ("park", "想到什么\n{原样}写下来", "选出它有多响，再定个回来的时间。"),
        ("ticket", "烦恼时间前\n{不用管}它", "停放的烦恼会被遮住。现在不归你管。"),
        ("gate", "只花{15 分钟}\n面对它", "核对实际发生了什么，放它走或做个计划。"),
        ("log", "{78%}的担忧\n从未成真", "出场记录会告诉你烦恼到底有多少真的发生。"),
    ],
    "zh-Hant": [
        ("lot", "把煩惱先{停}一停", "不必整晚揹著它們。"),
        ("park", "想到什麼\n{原樣}寫下來", "選出它有多響，再訂個回來的時間。"),
        ("ticket", "煩惱時間前\n{不用管}它", "停放的煩惱會被遮住。現在不歸你管。"),
        ("gate", "只花{15 分鐘}\n面對它", "確認實際發生了什麼，放它走或擬個計畫。"),
        ("log", "{78%}的擔憂\n從未成真", "出場紀錄會告訴你煩惱到底有多少真的發生。"),
    ],
    "ja": [
        ("lot", "心配は、ひとまず{駐車}", "一晩中、抱えていなくて大丈夫。"),
        ("park", "浮かぶままに\n{そのまま}書く", "どれくらい強く響くか選んで、戻す時間を決めるだけ。"),
        ("ticket", "心配タイムまで\n{見なくて}OK", "駐車した心配は隠れます。今はあなたの仕事じゃない。"),
        ("gate", "たった{15分}だけ\n向き合う", "本当に起きたか確かめて、手放すか計画を立てよう。"),
        ("log", "心配の{78%}は\n起きなかった", "出庫ログで、心配が本当に起きる頻度がわかります。"),
    ],
    "ru": [
        ("lot", "Отложите {тревоги}\nна потом", "Нести их всю ночь не нужно."),
        ("park", "Запишите\n{как есть}", "Отметьте громкость и выберите, когда вернуть."),
        ("ticket", "{Скрыто} до\nвремени тревог", "Припаркованные тревоги размыты. Не ваша забота."),
        ("gate", "Всего {15 минут}\nвнимания", "Проверьте, что было на самом деле, и отпустите."),
        ("log", "{78%} страхов\nне сбылись", "Журнал выездов покажет, как часто тревоги сбываются."),
    ],
    "es": [
        ("lot", "Aparca tus {preocupaciones}\npara luego", "No tienes que cargar con ellas toda la noche."),
        ("park", "Escríbela\n{tal como suena}", "Valora su volumen y elige cuándo vuelve."),
        ("ticket", "{Oculta} hasta la\nhora de preocuparse", "Las preocupaciones aparcadas se difuminan."),
        ("gate", "Solo {15 minutos}\npara afrontarla", "Comprueba qué ocurrió de verdad y suéltala."),
        ("log", "El {78%} de tus miedos\nno se cumplió", "Tu registro de salidas muestra cuántas ocurren."),
    ],
    "de": [
        ("lot", "Parke deine {Sorgen}\nfür später", "Du musst sie nicht die ganze Nacht tragen."),
        ("park", "Schreib sie auf,\n{wie sie klingt}", "Gib an, wie laut sie ist, und wann sie zurückkommt."),
        ("ticket", "{Verborgen} bis zur\nSorgenzeit", "Geparkte Sorgen bleiben unscharf. Gerade nicht dein Job."),
        ("gate", "Nur {15 Minuten}\nhinschauen", "Prüfe, was wirklich passiert ist, und lass los."),
        ("log", "{78 %} deiner Ängste\nsind nie eingetreten", "Dein Ausfahrtsjournal zeigt, wie oft Sorgen eintreten."),
    ],
    "fr": [
        ("lot", "Gare tes {soucis}\npour plus tard", "Tu n'as pas à les porter toute la nuit."),
        ("park", "Écris-le\n{tel qu'il résonne}", "Note sa force et choisis quand il revient."),
        ("ticket", "{Masqué} jusqu'à\nl'heure des soucis", "Les soucis garés restent flous. Pas ton affaire."),
        ("gate", "Seulement {15 minutes}\nd'attention", "Vérifie ce qui s'est passé, puis laisse-le partir."),
        ("log", "{78 %} de tes craintes\nne se sont pas réalisées", "Ton journal montre à quelle fréquence ça arrive."),
    ],
    "it": [
        ("lot", "Parcheggia le {preoccupazioni}\nper dopo", "Non devi portarle con te tutta la notte."),
        ("park", "Scrivila\n{come suona}", "Indica quanto è forte e quando deve tornare."),
        ("ticket", "{Nascosta} fino\nall'Ora delle preoccupazioni", "Le preoccupazioni parcheggiate restano sfocate."),
        ("gate", "Solo {15 minuti}\ndi attenzione", "Verifica cosa è successo davvero e lasciala andare."),
        ("log", "Il {78%} delle tue paure\nnon si è avverato", "Il registro delle uscite mostra quanto spesso succede."),
    ],
    "pt-BR": [
        ("lot", "Estacione suas {preocupações}\npara depois", "Você não precisa carregá-las a noite toda."),
        ("park", "Escreva do jeito\n{que ela soa}", "Diga o quanto está alta e quando volta."),
        ("ticket", "{Oculta} até a\nHora de se preocupar", "As preocupações estacionadas ficam desfocadas."),
        ("gate", "Só {15 minutos}\nde atenção", "Confira o que aconteceu de verdade e deixe ir."),
        ("log", "{78%} dos seus medos\nnão aconteceram", "O registro de saídas mostra com que frequência acontece."),
    ],
    "th": [
        ("lot", "จอด{ความกังวล}ไว้ก่อน", "ไม่ต้องแบกมันไว้ทั้งคืน"),
        ("park", "เขียน{ตามที่ได้ยิน}\nในหัว", "เลือกว่ามันดังแค่ไหน และให้กลับมาตอนไหน"),
        ("ticket", "{ซ่อน}ไว้จนถึง\nเวลากังวล", "ความกังวลที่จอดไว้จะถูกเบลอ ตอนนี้ไม่ใช่หน้าที่คุณ"),
        ("gate", "เผชิญหน้าแค่\n{15 นาที}", "ตรวจดูว่าเกิดอะไรขึ้นจริง แล้วปล่อยไปหรือวางแผน"),
        ("log", "{78%} ของความกังวล\nไม่เคยเกิดขึ้นจริง", "บันทึกการออกบอกว่าความกังวลเกิดขึ้นจริงบ่อยแค่ไหน"),
    ],
    "vi": [
        ("lot", "Đỗ {nỗi lo}\nlại để lo sau", "Bạn không cần mang chúng cả đêm."),
        ("park", "Viết {đúng như}\nnó vang lên", "Chọn độ ồn và giờ nó quay lại."),
        ("ticket", "{Ẩn} đến\nGiờ lo lắng", "Nỗi lo đã đỗ bị làm mờ. Không phải việc của bạn."),
        ("gate", "Chỉ {15 phút}\nđể đối diện", "Xem điều gì thực sự xảy ra, rồi buông đi."),
        ("log", "{78%} nỗi sợ của bạn\nkhông xảy ra", "Nhật ký ra bãi cho thấy nỗi lo xảy ra thường đến đâu."),
    ],
    "cs": [
        ("lot", "Zaparkuj {starosti}\nna později", "Nemusíš je nosit celou noc."),
        ("park", "Napiš to\n{tak, jak to zní}", "Ohodnoť hlasitost a vyber, kdy se vrátí."),
        ("ticket", "{Skryté} do\nČasu na starosti", "Zaparkované starosti zůstanou rozmazané."),
        ("gate", "Jen {15 minut}\npozornosti", "Ověř, co se stalo doopravdy, a nech to odejít."),
        ("log", "{78 %} obav\nse nesplnilo", "Deník výjezdů ukáže, jak často se starosti plní."),
    ],
    "da": [
        ("lot", "Parkér dine {bekymringer}\ntil senere", "Du behøver ikke bære dem hele natten."),
        ("park", "Skriv den ned,\n{som den lyder}", "Vurder, hvor høj den er, og hvornår den vender tilbage."),
        ("ticket", "{Skjult} til\nbekymringstid", "Parkerede bekymringer er slørede. Ikke dit ansvar."),
        ("gate", "Kun {15 minutter}\nmed den", "Tjek, hvad der skete, og lad den gå."),
        ("log", "{78 %} af din frygt\nskete aldrig", "Udkørselsloggen viser, hvor ofte det sker."),
    ],
    "el": [
        ("lot", "Πάρκαρε τις {ανησυχίες}\nγια αργότερα", "Δεν χρειάζεται να τις κουβαλάς όλη νύχτα."),
        ("park", "Γράψ' την\n{όπως ακούγεται}", "Βαθμολόγησε πόσο δυνατή είναι και πότε γυρνά."),
        ("ticket", "{Κρυφή} μέχρι\nτην Ώρα ανησυχίας", "Οι σταθμευμένες ανησυχίες θολώνουν."),
        ("gate", "Μόνο {15 λεπτά}\nπροσοχής", "Έλεγξε τι έγινε πραγματικά και άφησέ την."),
        ("log", "Το {78%} των φόβων σου\nδεν έγινε ποτέ", "Το αρχείο εξόδων δείχνει πόσο συχνά συμβαίνουν."),
    ],
    "fi": [
        ("lot", "Pysäköi {huolesi}\nmyöhemmäksi", "Sinun ei tarvitse kantaa niitä koko yötä."),
        ("park", "Kirjoita se\n{kuten se kuulostaa}", "Arvioi voimakkuus ja valitse paluuaika."),
        ("ticket", "{Piilossa} huoliaikaan\nasti", "Pysäköidyt huolet pysyvät sumeina."),
        ("gate", "Vain {15 minuuttia}\nhuomiota", "Tarkista, mitä tapahtui, ja päästä irti."),
        ("log", "{78 %} peloistasi\nei toteutunut", "Ulosajoloki näyttää, kuinka usein huolet toteutuvat."),
    ],
    "id": [
        ("lot", "Parkirkan {kekhawatiran}\nuntuk nanti", "Kamu tidak perlu membawanya semalaman."),
        ("park", "Tulis {persis seperti}\nsuaranya", "Nilai seberapa keras, lalu pilih kapan kembali."),
        ("ticket", "{Tersembunyi} sampai\nWaktu Khawatir", "Kekhawatiran terparkir diburamkan. Bukan urusanmu."),
        ("gate", "Hanya {15 menit}\nperhatian penuh", "Periksa apa yang terjadi, lalu lepaskan."),
        ("log", "{78%} ketakutanmu\ntidak terjadi", "Catatan keluar menunjukkan seberapa sering terjadi."),
    ],
    "nb": [
        ("lot", "Parker {bekymringene}\ntil senere", "Du trenger ikke bære dem hele natten."),
        ("park", "Skriv den ned\n{slik den høres ut}", "Vurder hvor høy den er og når den kommer tilbake."),
        ("ticket", "{Skjult} til\nbekymringstid", "Parkerte bekymringer er uskarpe. Ikke din jobb nå."),
        ("gate", "Bare {15 minutter}\nmed den", "Sjekk hva som skjedde, og la den gå."),
        ("log", "{78 %} av frykten din\ninntraff aldri", "Utkjøringsloggen viser hvor ofte det skjer."),
    ],
    "nl": [
        ("lot", "Parkeer je {zorgen}\nvoor later", "Je hoeft ze niet de hele nacht te dragen."),
        ("park", "Schrijf op\n{zoals het klinkt}", "Geef de luidheid aan en kies wanneer hij terugkomt."),
        ("ticket", "{Verborgen} tot de\nZorgentijd", "Geparkeerde zorgen blijven wazig. Nu niet jouw taak."),
        ("gate", "Maar {15 minuten}\naandacht", "Controleer wat er echt gebeurde en laat los."),
        ("log", "{78%} van je angsten\nkwam nooit uit", "Je uitritlogboek laat zien hoe vaak zorgen uitkomen."),
    ],
    "pl": [
        ("lot", "Zaparkuj {zmartwienia}\nna później", "Nie musisz ich nosić całą noc."),
        ("park", "Zapisz to\n{tak, jak brzmi}", "Oceń głośność i wybierz, kiedy wróci."),
        ("ticket", "{Ukryte} do Pory\nna zmartwienia", "Zaparkowane zmartwienia są rozmyte."),
        ("gate", "Tylko {15 minut}\nuwagi", "Sprawdź, co się stało, i puść to."),
        ("log", "{78%} twoich obaw\nsię nie spełniło", "Dziennik wyjazdów pokazuje, jak często się sprawdzają."),
    ],
    "sv": [
        ("lot", "Parkera din {oro}\ntill senare", "Du behöver inte bära på den hela natten."),
        ("park", "Skriv ner den\n{som den låter}", "Bedöm hur högljudd den är och när den ska komma tillbaka."),
        ("ticket", "{Dold} till\norotid", "Parkerade oror är suddiga. Inte ditt jobb nu."),
        ("gate", "Bara {15 minuter}\nmed den", "Kolla vad som hände och släpp taget."),
        ("log", "{78 %} av dina farhågor\nhände aldrig", "Utfartsloggen visar hur ofta oron slår in."),
    ],
    "tr": [
        ("lot", "{Endişelerini}\nsonraya park et", "Onları bütün gece taşımak zorunda değilsin."),
        ("park", "Duyulduğu gibi\n{yaz}", "Sesinin yüksekliğini seç, ne zaman döneceğini belirle."),
        ("ticket", "Endişe Saati'ne kadar\n{gizli}", "Park edilen endişeler bulanık kalır."),
        ("gate", "Sadece {15 dakika}\nodaklan", "Gerçekte ne olduğunu kontrol et, bırak gitsin."),
        ("log", "Korkularının {%78}'i\ngerçekleşmedi", "Çıkış Günlüğü endişelerin ne sıklıkla olduğunu gösterir."),
    ],
}


# Script-specific fonts (macOS). Candidates are tried in order; the first that loads wins.
# Latin, Cyrillic, Greek and Vietnamese use SF; Hangul, CJK and Thai need their own faces.
# (path, index when heavy, index when normal) -- check the rendered images on the Mac.
FONTS = {
    "ko": [(SD_GOTHIC, 14, 2)],
    "ja": [("/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc", 0, 0), ("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc", 0, 0)],
    "zh-Hans": [("/System/Library/Fonts/PingFang.ttc", 0, 0)],
    "zh-Hant": [("/System/Library/Fonts/PingFang.ttc", 0, 0)],
    "th": [("/System/Library/Fonts/Supplemental/Thonburi.ttc", 0, 0), ("/System/Library/Fonts/Thonburi.ttc", 0, 0)],
}


def font(lang, size, heavy):
    for path, heavy_index, normal_index in FONTS.get(lang, []):
        try:
            return ImageFont.truetype(path, size, index=heavy_index if heavy else normal_index)
        except OSError:
            continue
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
    head_font = font(lang, px(112 if lang in ("ko", "ja", "zh-Hans", "zh-Hant") else 108), heavy=True)
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
