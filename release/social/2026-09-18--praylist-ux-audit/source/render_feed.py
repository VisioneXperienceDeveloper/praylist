from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "feed"
SHOTS = ROOT / "audit-screenshots"
W, H = 1080, 1350

PAPER = "#F8F6EF"
PAPER_2 = "#EEE9DE"
WHITE = "#FFFFFF"
INK = "#253D32"
FOREST = "#426B55"
MINT = "#DCE8DF"
QUIET = "#6D766E"
LINE = "#D9D8CF"
RED = "#B84C3F"
RED_SOFT = "#F3DDD7"
YELLOW = "#E8B94F"

FONT_PATH = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
SERIF_PATH = "/System/Library/Fonts/NewYork.ttf"


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    indexes = {"light": 8, "regular": 0, "medium": 2, "semibold": 4, "bold": 6, "extrabold": 14}
    return ImageFont.truetype(FONT_PATH, size=size, index=indexes[weight])


def serif(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(SERIF_PATH, size=size)


def canvas() -> Image.Image:
    return Image.new("RGB", (W, H), PAPER)


def rounded(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        if not para:
            lines.append("")
            continue
        line = ""
        for ch in para:
            trial = line + ch
            if line and draw.textlength(trial, font=fnt) > max_width:
                lines.append(line.rstrip())
                line = ch.lstrip()
            else:
                line = trial
        lines.append(line.rstrip())
    return lines


def text_block(draw, xy, text, fnt, fill=INK, max_width=None, line_gap=10, anchor="la"):
    x, y = xy
    lines = text.split("\n") if max_width is None else wrap(draw, text, fnt, max_width)
    bbox = fnt.getbbox("가Ag")
    line_h = bbox[3] - bbox[1]
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill, anchor=anchor)
        y += line_h + line_gap
    return y


def pill(draw, xy, label, fill, text_fill=WHITE, outline=None):
    x, y = xy
    f = font(28, "bold")
    tw = draw.textlength(label, font=f)
    box = (x, y, x + tw + 38, y + 52)
    rounded(draw, box, 26, fill, outline, 2)
    draw.text((x + 19, y + 27), label, font=f, fill=text_fill, anchor="lm")
    return box


def header(draw, page, section="PRAYLIST UX AUDIT"):
    draw.text((70, 66), section, font=font(24, "semibold"), fill=FOREST, anchor="la")
    draw.text((1010, 66), f"{page:02d}/10", font=font(24, "medium"), fill=QUIET, anchor="ra")
    draw.line((70, 103, 1010, 103), fill=LINE, width=2)


def footer(draw, text="2026.09.18 · SELF REVIEW"):
    draw.text((70, 1300), text, font=font(20, "medium"), fill=QUIET, anchor="ls")


def phone_card(base: Image.Image, path: Path, box, crop=None, radius=36, shadow=True):
    src = Image.open(path).convert("RGB")
    if crop is not None:
        src = src.crop(crop)
    x0, y0, x1, y1 = box
    size = (x1 - x0, y1 - y0)
    src.thumbnail(size, Image.Resampling.LANCZOS)
    px = x0 + (size[0] - src.width) // 2
    py = y0 + (size[1] - src.height) // 2
    mask = Image.new("L", src.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, src.width, src.height), radius=radius, fill=255)
    if shadow:
        layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
        sh = Image.new("RGBA", src.size, (0, 0, 0, 90))
        sh.putalpha(mask)
        layer.alpha_composite(sh, (px + 8, py + 16))
        layer = layer.filter(ImageFilter.GaussianBlur(18))
        base.paste(layer, (0, 0), layer)
    base.paste(src, (px, py), mask)
    return (px, py, px + src.width, py + src.height)


def bullet(draw, x, y, text, width, color=INK):
    draw.ellipse((x, y + 12, x + 12, y + 24), fill=FOREST)
    end = text_block(draw, (x + 30, y), text, font(30, "medium"), color, width - 30, 8)
    return end + 18


def save(img: Image.Image, n: int, slug: str):
    path = OUT / f"{n:02d}-{slug}.png"
    img.save(path, optimize=True)
    return path


def slide_1():
    img = canvas(); d = ImageDraw.Draw(img)
    d.ellipse((720, -180, 1220, 420), fill=MINT)
    pill(d, (70, 76), "SELF UX AUDIT", FOREST)
    text_block(d, (70, 184), "내 앱 UX,\n내가 직접 깠습니다", font(78, "extrabold"), INK, 660, 6)
    d.text((72, 422), "Praylist의 잘한 것 3개 · 못한 것 3개", font=font(34, "medium"), fill=QUIET)
    phone_card(img, SHOTS / "03-main-notebook-ko.jpg", (610, 280, 1000, 1128), radius=38)
    rounded(d, (70, 765, 610, 1012), 34, FOREST)
    d.text((110, 824), "감성은 정확하다.", font=font(43, "bold"), fill=WHITE)
    d.text((110, 889), "길 찾기는 부족하다.", font=font(43, "bold"), fill=WHITE)
    d.text((110, 968), "화면과 실제 플로우로만 판정", font=font(24, "regular"), fill="#DCE8DF")
    d.text((70, 1288), "PRAYLIST · HONEST BUILD LOG", font=font(22, "semibold"), fill=QUIET)
    return save(img, 1, "cover")


def slide_2():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 2)
    pill(d, (70, 145), "VERDICT", INK)
    text_block(d, (70, 225), "좋은 노트다.\n아직 좋은 시스템은 아니다.", font(64, "extrabold"), INK, 940, 8)
    rounded(d, (70, 495, 1010, 738), 34, MINT)
    pill(d, (105, 530), "GOOD", FOREST)
    d.text((105, 610), "집중 · 감정 · 기록의 연결", font=font(42, "bold"), fill=INK)
    d.text((105, 673), "사용자가 왜 다시 돌아오는지는 선명하다.", font=font(28, "regular"), fill=QUIET)
    rounded(d, (70, 775, 1010, 1018), 34, RED_SOFT)
    pill(d, (105, 810), "BAD", RED)
    d.text((105, 890), "탐색 · 저장 확신 · 언어 일관성", font=font(42, "bold"), fill=INK)
    d.text((105, 953), "커질수록 어디로 가야 할지가 흐려진다.", font=font(28, "regular"), fill=QUIET)
    rounded(d, (70, 1085, 1010, 1225), 28, WHITE, LINE, 2)
    text_block(d, (105, 1120), "근거: 현재 iPhone 화면과 실제 조작 흐름\n제외: 사용자 인터뷰, 전환율, 장기 사용 데이터", font(25, "medium"), QUIET, 860, 10)
    footer(d)
    return save(img, 2, "verdict")


def slide_3():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 3)
    pill(d, (70, 145), "GOOD 01", FOREST)
    text_block(d, (70, 225), "빈 줄이 곧\n입력창이다", font(66, "extrabold"), INK, 510, 6)
    phone_card(img, SHOTS / "03-main-notebook-ko.jpg", (590, 160, 1000, 1052), radius=38)
    y = 475
    y = bullet(d, 70, y, "첫 행동을 설명 없이 시작", 480)
    y = bullet(d, 70, y, "저장용 화면을 따로 열지 않음", 480)
    y = bullet(d, 70, y, "10칸 구조가 현재 상태를 보여줌", 480)
    rounded(d, (70, 1058, 1010, 1215), 30, INK)
    d.text((105, 1112), "판정", font=font(26, "bold"), fill=YELLOW)
    d.text((105, 1168), "메타포와 행동이 붙어 있다.", font=font(38, "bold"), fill=WHITE, anchor="ls")
    footer(d)
    return save(img, 3, "good-direct-entry")


def slide_4():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 4)
    pill(d, (70, 145), "GOOD 02", FOREST)
    text_block(d, (70, 225), "기도할 때는\n기도만 남긴다", font(66, "extrabold"), INK, 510, 6)
    phone_card(img, SHOTS / "05-prayer-reading.jpg", (590, 160, 1000, 1052), radius=38)
    y = 475
    y = bullet(d, 70, y, "진행률 1/1로 끝을 예고", 480)
    y = bullet(d, 70, y, "읽기 → 완료, 한 방향 흐름", 480)
    y = bullet(d, 70, y, "부드러운 문장이 행동 압박을 낮춤", 480)
    rounded(d, (70, 1058, 1010, 1215), 30, FOREST)
    d.text((105, 1112), "판정", font=font(26, "bold"), fill="#DCE8DF")
    d.text((105, 1168), "앱의 목적이 가장 선명한 화면.", font=font(38, "bold"), fill=WHITE, anchor="ls")
    footer(d)
    return save(img, 4, "good-focus")


def slide_5():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 5)
    pill(d, (70, 145), "GOOD 03", FOREST)
    text_block(d, (70, 225), "달성을 체크가 아니라\n날짜로 남긴다", font(59, "extrabold"), INK, 940, 6)
    phone_card(img, SHOTS / "04-achievement-sheet.jpg", (70, 410, 520, 1125), radius=34)
    phone_card(img, SHOTS / "07-history-calendar.jpg", (560, 410, 1010, 1125), radius=34)
    rounded(d, (125, 1002, 955, 1195), 30, INK)
    d.text((165, 1055), "기록 → 회고", font=font(28, "bold"), fill=YELLOW)
    text_block(d, (165, 1102), "완료의 의미를 붙이고\n다시 볼 이유를 만든다.", font(34, "bold"), WHITE, 720, 5)
    footer(d)
    return save(img, 5, "good-meaningful-history")


def top_strip(img: Image.Image, shot: str, box, label: str, circles: list[tuple[int, int, int, int]]):
    x0, y0, x1, y1 = box
    src = Image.open(SHOTS / shot).convert("RGB").crop((0, 0, 368, 160))
    src = src.resize((x1 - x0, y1 - y0), Image.Resampling.LANCZOS)
    mask = Image.new("L", src.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, src.width, src.height), radius=28, fill=255)
    img.paste(src, (x0, y0), mask)
    dd = ImageDraw.Draw(img)
    for cx0, cy0, cx1, cy1 in circles:
        dd.rounded_rectangle((x0 + cx0, y0 + cy0, x0 + cx1, y0 + cy1), radius=24, outline=RED, width=6)
    dd.text((x0, y1 + 14), label, font=font(23, "semibold"), fill=QUIET)


def slide_6():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 6)
    pill(d, (70, 145), "BAD 01", RED)
    text_block(d, (70, 225), "한국어인데\n핵심 버튼은 영어다", font(66, "extrabold"), INK, 940, 6)
    top_strip(img, "10-settings-ko.jpg", (70, 430, 1010, 650), "설정", [(708, 65, 905, 172)])
    top_strip(img, "06-history-answered.jpg", (70, 720, 1010, 940), "나의 발자취", [(708, 65, 905, 172)])
    top_strip(img, "08-category-management.jpg", (70, 1010, 1010, 1230), "카테고리 관리", [(20, 65, 200, 172), (708, 65, 905, 172)])
    footer(d, "Close · Edit · Cancel · Save → 전부 현지화 필요")
    return save(img, 6, "bad-localization")


def slide_7():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 7)
    pill(d, (70, 145), "BAD 02", RED)
    text_block(d, (70, 225), "페이지 메타포가\n정보 구조를 숨긴다", font(62, "extrabold"), INK, 650, 6)
    phone_card(img, SHOTS / "03-main-notebook-ko.jpg", (665, 155, 1000, 885), radius=32)
    y = 475
    y = bullet(d, 70, y, "1/3은 보이지만 전체 목록은 안 보임", 540, INK)
    y = bullet(d, 70, y, "원하는 카테고리로 바로 갈 수 없음", 540, INK)
    y = bullet(d, 70, y, "관리 화면은 설정 안쪽에 숨어 있음", 540, INK)
    rounded(d, (70, 950, 1010, 1192), 34, RED_SOFT)
    d.text((110, 1005), "적나라한 판정", font=font(28, "bold"), fill=RED)
    text_block(d, (110, 1060), "카테고리 3개일 땐 낭만.\n10개가 되면 노동.", font(45, "extrabold"), INK, 820, 6)
    footer(d)
    return save(img, 7, "bad-navigation")


def slide_8():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 8)
    pill(d, (70, 145), "BAD 03", RED)
    text_block(d, (70, 225), "자동 저장은 편하다.\n그런데 저장됐다는 증거가 없다.", font(58, "extrabold"), INK, 940, 6)
    phone_card(img, SHOTS / "03-main-notebook-ko.jpg", (70, 455, 520, 1130), crop=(0, 120, 368, 640), radius=34)
    rounded(d, (570, 500, 1010, 690), 30, WHITE, LINE, 2)
    d.text((610, 548), "실제 동작", font=font(27, "bold"), fill=FOREST)
    text_block(d, (610, 596), "키보드 ‘완료’ 또는\n다른 곳을 누르면 저장", font(31, "semibold"), INK, 350, 8)
    rounded(d, (570, 735, 1010, 925), 30, RED_SOFT)
    d.text((610, 783), "사용자에게 보이는 것", font=font(27, "bold"), fill=RED)
    text_block(d, (610, 831), "저장됨 표시 0\n되돌리기 0", font(31, "semibold"), INK, 350, 8)
    rounded(d, (570, 970, 1010, 1130), 30, FOREST)
    text_block(d, (610, 1014), "해법: 1초짜리 ‘저장됨’\n+ 편집 직후 실행 취소", font(28, "bold"), WHITE, 350, 7)
    footer(d)
    return save(img, 8, "bad-save-confidence")


def priority(draw, y, code, title, desc, color):
    rounded(draw, (70, y, 1010, y + 205), 30, WHITE, LINE, 2)
    pill(draw, (105, y + 35), code, color)
    draw.text((290, y + 48), title, font=font(38, "bold"), fill=INK)
    text_block(draw, (290, y + 105), desc, font(27, "regular"), QUIET, 660, 6)


def slide_9():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 9)
    pill(d, (70, 145), "FIX ORDER", INK)
    d.text((70, 235), "먼저 고칠 순서", font=font(68, "extrabold"), fill=INK)
    priority(d, 365, "P0", "언어 일관성", "Close / Edit / Cancel / Save를 모두 현지화", RED)
    priority(d, 600, "P1", "카테고리 바로가기", "페이지 표시를 누르면 전체 목록과 현재 위치 노출", FOREST)
    priority(d, 835, "P1", "저장 확신", "가벼운 저장 완료 피드백 + 즉시 실행 취소", FOREST)
    priority(d, 1070, "P2", "안내문 다이어트", "긴 설명은 첫 사용 힌트와 상황별 안내로 분리", QUIET)
    footer(d)
    return save(img, 9, "fix-order")


def slide_10():
    img = canvas(); d = ImageDraw.Draw(img); header(d, 10)
    icon = Image.open(Path(__file__).resolve().parents[4] / "Praylist" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png").convert("RGB")
    icon = icon.resize((230, 230), Image.Resampling.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 230, 230), radius=52, fill=255)
    img.paste(icon, (70, 190), mask)
    d.text((340, 238), "praylist", font=serif(70), fill=INK)
    d.text((344, 330), "UX AUDIT · 2026", font=font(24, "semibold"), fill=FOREST)
    text_block(d, (70, 520), "예쁜 노트는\n이미 됐다.", font(76, "extrabold"), INK, 940, 4)
    text_block(d, (70, 735), "이제 길 잃지 않는\n제품으로.", font(76, "extrabold"), FOREST, 940, 4)
    rounded(d, (70, 1045, 1010, 1208), 34, INK)
    d.text((110, 1093), "당신이라면 무엇부터 고칠까요?", font=font(38, "bold"), fill=WHITE)
    d.text((110, 1155), "언어 · 탐색 · 저장 확신", font=font(27, "regular"), fill="#DCE8DF")
    footer(d, "PRAYLIST · HONEST BUILD LOG")
    return save(img, 10, "closing")


def contact_sheet(paths: list[Path]):
    thumb_w = 270
    thumb_h = int(thumb_w * H / W)
    gap = 20
    sheet = Image.new("RGB", (thumb_w * 5 + gap * 6, thumb_h * 2 + gap * 3), "#D8D5CD")
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGB").resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (i % 5) * (thumb_w + gap)
        y = gap + (i // 5) * (thumb_h + gap)
        sheet.paste(im, (x, y))
    sheet.save(ROOT / "contact-sheet.png", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    paths = [slide_1(), slide_2(), slide_3(), slide_4(), slide_5(), slide_6(), slide_7(), slide_8(), slide_9(), slide_10()]
    contact_sheet(paths)
    print("\n".join(str(p) for p in paths))


if __name__ == "__main__":
    main()
