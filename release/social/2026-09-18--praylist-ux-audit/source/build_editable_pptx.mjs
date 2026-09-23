import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const { Presentation, PresentationFile } = await import(pathToFileURL(
  "/Users/cjungwo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs",
).href);

const ROOT = "/Users/cjungwo/Documents/Projects/praylist";
const PACKAGE_DIR = path.join(ROOT, "release/social/2026-09-18--praylist-ux-audit");
const BUILD_DIR = path.join(PACKAGE_DIR, ".codex-pptx-build");
const OUT_DIR = path.join(PACKAGE_DIR, "pptx");
const FINAL_PPTX = path.join(OUT_DIR, "Praylist-UX-Audit-Editable-Template.pptx");
const SKILL_DIR = "/Users/cjungwo/.codex/plugins/cache/openai-primary-runtime/presentations/26.904.11930/skills/presentations";
const RUNTIME_PYTHON = "/Users/cjungwo/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
const FONT = "Apple SD Gothic Neo";

const C = {
  paper: "#F8F6EF",
  paper2: "#EEE9DE",
  white: "#FFFFFF",
  ink: "#253D32",
  forest: "#426B55",
  mint: "#DCE8DF",
  quiet: "#6D766E",
  line: "#D9D8CF",
  red: "#B84C3F",
  redSoft: "#F3DDD7",
  yellow: "#E8B94F",
  charcoal: "#1E3028",
};

const IMG = {
  main: path.join(PACKAGE_DIR, "audit-screenshots/03-main-notebook-ko.jpg"),
  achievement: path.join(PACKAGE_DIR, "audit-screenshots/04-achievement-sheet.jpg"),
  prayer: path.join(PACKAGE_DIR, "audit-screenshots/05-prayer-reading.jpg"),
  history: path.join(PACKAGE_DIR, "audit-screenshots/06-history-answered.jpg"),
  calendar: path.join(PACKAGE_DIR, "audit-screenshots/07-history-calendar.jpg"),
  categories: path.join(PACKAGE_DIR, "audit-screenshots/08-category-management.jpg"),
  settings: path.join(PACKAGE_DIR, "audit-screenshots/10-settings-ko.jpg"),
  icon: path.join(ROOT, "Praylist/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"),
};

const presentation = Presentation.create({ slideSize: { width: 1080, height: 1350 } });

function addShape(slide, name, geometry, x, y, w, h, fill, line = "none", radius = undefined) {
  const item = slide.shapes.add({
    geometry,
    name,
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: line === "none"
      ? { style: "solid", fill: "none", width: 0 }
      : { style: "solid", fill: line, width: 2 },
    ...(radius ? { borderRadius: radius } : {}),
  });
  return item;
}

function addText(slide, name, text, x, y, w, h, size = 32, color = C.ink, opts = {}) {
  const item = slide.shapes.add({
    geometry: "textbox",
    name,
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  item.text = text;
  item.text.style = {
    typeface: FONT,
    fontSize: size,
    color,
    bold: opts.bold ?? false,
    italic: opts.italic ?? false,
    alignment: opts.align ?? "left",
    verticalAlignment: opts.valign ?? "top",
    autoFit: opts.autoFit ?? "shrinkText",
    wrap: "square",
    insets: opts.insets ?? { left: 0, right: 0, top: 0, bottom: 0 },
  };
  return item;
}

function addPill(slide, name, label, x, y, w, fill = C.mint, color = C.forest) {
  addShape(slide, `${name}-bg`, "roundRect", x, y, w, 44, fill, "none", "rounded-2xl");
  addText(slide, `${name}-text`, label, x, y + 2, w, 40, 19, color, {
    bold: true,
    align: "center",
    valign: "middle",
  });
}

function addHeader(slide, number, template = false) {
  addText(slide, "Header", template ? "PRAYLIST FEED TEMPLATE" : "PRAYLIST · UX AUDIT", 64, 42, 410, 34, 19, C.forest, { bold: true });
  addText(slide, "Page number", `${template ? "T" : ""}${String(number).padStart(2, "0")}/10`, 906, 42, 110, 34, 19, C.quiet, { bold: true, align: "right" });
  addShape(slide, "Header rule", "rect", 64, 90, 952, 2, C.line);
}

function addFooter(slide, text = "PRAYLIST · HONEST BUILD LOG") {
  addText(slide, "Footer", text, 64, 1280, 952, 28, 18, C.quiet, { bold: true });
}

function addDotBullet(slide, name, text, x, y, width, color = C.forest, size = 28) {
  addShape(slide, `${name}-dot`, "ellipse", x, y + 11, 13, 13, color);
  addText(slide, `${name}-text`, text, x + 30, y, width - 30, 52, size, C.ink, { bold: true });
}

async function addImage(slide, name, file, x, y, w, h, opts = {}) {
  if (opts.backplate !== false) {
    addShape(slide, `${name}-shadow`, "roundRect", x + 9, y + 12, w, h, "#D8D4CA", "none", "rounded-2xl");
  }
  const contentType = file.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
  const item = slide.images.add({
    name,
    blob: await fs.readFile(file),
    contentType,
    alt: opts.alt ?? "Praylist application screenshot",
    fit: opts.fit ?? "cover",
    position: { left: x, top: y, width: w, height: h },
    geometry: "roundRect",
    borderRadius: opts.radius ?? "rounded-2xl",
  });
  if (opts.template) addPill(slide, `${name}-replace`, "이미지 교체", x + 16, y + 16, 116, C.white, C.forest);
  return item;
}

function addCard(slide, name, x, y, w, h, fill = C.white, line = "none") {
  return addShape(slide, name, "roundRect", x, y, w, h, fill, line, "rounded-2xl");
}

function addSectionLabel(slide, prefix, index, label, good = true, template = false) {
  const color = good ? C.forest : C.red;
  addText(slide, `${prefix}-index`, template ? `[${index}]` : index, 64, 132, 150, 30, 20, color, { bold: true });
  addText(slide, `${prefix}-label`, template ? `[${label}]` : label, 205, 132, 330, 30, 20, color, { bold: true });
}

function notes(template = false) {
  return template
    ? "템플릿 슬라이드입니다. 텍스트 요소는 직접 수정할 수 있습니다. 이미지 요소를 선택한 뒤 그림 변경으로 교체하세요."
    : "편집 가능한 슬라이드입니다. 텍스트, 라벨, 카드와 강조 도형은 모두 PowerPoint에서 수정할 수 있습니다. 이미지 요소는 선택 후 그림 변경으로 교체할 수 있습니다.";
}

async function slideCover(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 1, template);
  addPill(slide, "Audit pill", template ? "[시리즈 라벨]" : "SELF UX AUDIT", 64, 134, 214);
  addText(slide, "Main title", template ? "[메인 제목을\n입력하세요]" : "내 앱 UX,\n내가 직접 깠습니다", 64, 210, 575, 210, 68, C.ink, { bold: true });
  addText(slide, "Subtitle", template ? "[부제목 또는 핵심 요약]" : "Praylist의 잘한 것 3개 · 못한 것 3개", 64, 438, 560, 52, 28, C.quiet, { bold: true });
  await addImage(slide, "Hero screenshot", IMG.main, 620, 155, 370, 744, { template, alt: "Praylist main notebook screenshot" });
  addCard(slide, "Quote card", 64, 790, 540, 333, C.forest);
  addText(slide, "Quote", template ? "[핵심 문장을\n입력하세요]" : "감성은 정확하다.\n길 찾기는 부족하다.", 104, 842, 460, 132, 43, C.white, { bold: true });
  addText(slide, "Evidence line", template ? "[판정 기준 또는 근거]" : "화면과 실제 플로우로만 판정", 104, 1025, 455, 42, 24, C.mint, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideVerdict(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 2, template);
  addPill(slide, "Verdict pill", template ? "[섹션 라벨]" : "VERDICT", 64, 134, 160, C.ink, C.white);
  addText(slide, "Main title", template ? "[한 줄 총평을\n입력하세요]" : "좋은 노트다.\n아직 좋은 시스템은 아니다.", 64, 210, 900, 180, 61, C.ink, { bold: true });
  addCard(slide, "Good card", 64, 438, 952, 238, C.mint);
  addPill(slide, "Good label", template ? "[강점]" : "GOOD", 96, 474, 128, C.forest, C.white);
  addText(slide, "Good headline", template ? "[잘한 점을 한 문장으로]" : "집중 · 감정 · 기록의 연결", 96, 542, 830, 54, 37, C.ink, { bold: true });
  addText(slide, "Good detail", template ? "[근거와 사용자 효과를 입력하세요]" : "입력부터 기도, 회고까지 제품의 감정선은 일관된다.", 96, 610, 830, 40, 25, C.forest, { bold: true });
  addCard(slide, "Bad card", 64, 704, 952, 238, C.redSoft);
  addPill(slide, "Bad label", template ? "[약점]" : "BAD", 96, 740, 128, C.red, C.white);
  addText(slide, "Bad headline", template ? "[못한 점을 한 문장으로]" : "탐색 · 저장 확신 · 언어 일관성", 96, 808, 830, 54, 37, C.ink, { bold: true });
  addText(slide, "Bad detail", template ? "[근거와 사용자 비용을 입력하세요]" : "예쁜 화면 뒤에서 사용자는 현재 위치와 결과를 추측한다.", 96, 876, 830, 40, 25, C.red, { bold: true });
  addCard(slide, "Evidence card", 64, 975, 952, 196, C.white, C.line);
  addText(slide, "Evidence", template ? "근거: [검토한 화면과 플로우]\n제외: [이번 평가에서 다루지 않은 데이터]" : "근거: 현재 iPhone 화면과 실제 조작 흐름\n제외: 사용자 인터뷰, 전환율, 장기 사용 데이터", 96, 1016, 840, 102, 26, C.quiet, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideGoodOne(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 3, template);
  addSectionLabel(slide, "Good section", "GOOD 01", "DIRECT ENTRY", true, template);
  addText(slide, "Main title", template ? "[좋았던 UX를\n두 줄로 요약]" : "빈 줄이 곧\n입력창이다", 64, 205, 500, 160, 61, C.ink, { bold: true });
  addDotBullet(slide, "Bullet 1", template ? "[근거 1]" : "첫 행동을 설명 없이 시작", 64, 435, 470);
  addDotBullet(slide, "Bullet 2", template ? "[근거 2]" : "저장용 화면을 따로 열지 않음", 64, 515, 470);
  addDotBullet(slide, "Bullet 3", template ? "[근거 3]" : "10칸 구조가 현재 상태를 보여줌", 64, 595, 470);
  await addImage(slide, "Evidence screenshot", IMG.main, 585, 205, 390, 780, { template, alt: "Praylist direct entry interface" });
  addCard(slide, "Verdict card", 64, 770, 480, 248, C.ink);
  addText(slide, "Verdict label", template ? "[판정 라벨]" : "판정", 100, 812, 390, 35, 22, C.mint, { bold: true });
  addText(slide, "Verdict", template ? "[판정 문장을 입력하세요]" : "메타포와 행동이\n붙어 있다.", 100, 872, 390, 92, 37, C.white, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideGoodTwo(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 4, template);
  addSectionLabel(slide, "Good section", "GOOD 02", "FOCUS", true, template);
  addText(slide, "Main title", template ? "[집중 경험을\n두 줄로 요약]" : "기도할 때는\n기도만 남긴다", 64, 205, 500, 160, 61, C.ink, { bold: true });
  addDotBullet(slide, "Bullet 1", template ? "[근거 1]" : "진행률 1/1로 끝을 예고", 64, 435, 470);
  addDotBullet(slide, "Bullet 2", template ? "[근거 2]" : "읽기 → 완료, 한 방향 흐름", 64, 515, 470);
  addDotBullet(slide, "Bullet 3", template ? "[근거 3]" : "부드러운 문장이 행동 압박을 낮춤", 64, 595, 470);
  await addImage(slide, "Evidence screenshot", IMG.prayer, 585, 205, 390, 780, { template, alt: "Praylist prayer reading screen" });
  addCard(slide, "Verdict card", 64, 770, 480, 248, C.forest);
  addText(slide, "Verdict label", template ? "[판정 라벨]" : "판정", 100, 812, 390, 35, 22, C.mint, { bold: true });
  addText(slide, "Verdict", template ? "[판정 문장을 입력하세요]" : "앱의 목적이 가장\n선명한 화면.", 100, 872, 390, 92, 37, C.white, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideGoodThree(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 5, template);
  addSectionLabel(slide, "Good section", "GOOD 03", "MEANINGFUL HISTORY", true, template);
  addText(slide, "Main title", template ? "[가치 있는 기록을\n두 줄로 요약]" : "달성을 체크가 아니라\n날짜로 남긴다", 64, 205, 900, 160, 61, C.ink, { bold: true });
  await addImage(slide, "Left screenshot", IMG.achievement, 64, 430, 426, 700, { template, alt: "Praylist achievement sheet" });
  await addImage(slide, "Right screenshot", IMG.calendar, 555, 430, 426, 700, { template, alt: "Praylist history calendar" });
  addCard(slide, "Meaning card", 180, 850, 720, 252, C.ink);
  addText(slide, "Meaning label", template ? "[변화 라벨]" : "기록 → 회고", 225, 894, 630, 38, 23, C.mint, { bold: true });
  addText(slide, "Meaning", template ? "[기능이 만든 의미와\n재방문 이유를 입력하세요]" : "완료의 의미를 붙이고\n다시 볼 이유를 만든다.", 225, 958, 630, 104, 39, C.white, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideBadOne(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 6, template);
  addSectionLabel(slide, "Bad section", "BAD 01", "LOCALIZATION", false, template);
  addText(slide, "Main title", template ? "[일관성 문제를\n두 줄로 요약]" : "한국어인데\n핵심 버튼은 영어다", 64, 205, 900, 160, 61, C.ink, { bold: true });
  const cards = [
    [IMG.settings, "설정", "Close", 64],
    [IMG.history, "나의 발자취", "Edit", 376],
    [IMG.categories, "카테고리 관리", "Edit", 688],
  ];
  for (let i = 0; i < cards.length; i++) {
    const [file, label, issue, x] = cards[i];
    addCard(slide, `Example ${i + 1} card`, x, 455, 286, 484, C.white, C.line);
    await addImage(slide, `Example ${i + 1} screenshot`, file, x + 18, 482, 250, 318, { template, backplate: false, alt: `${label} screenshot` });
    addText(slide, `Example ${i + 1} label`, template ? `[화면 ${i + 1}]` : label, x + 18, 825, 250, 32, 20, C.quiet, { bold: true });
    addShape(slide, `Example ${i + 1} issue box`, "roundRect", x + 54, 866, 178, 50, "none", C.red, "rounded-2xl");
    addText(slide, `Example ${i + 1} issue`, template ? "[영문 버튼]" : issue, x + 54, 870, 178, 40, 22, C.red, { bold: true, align: "center", valign: "middle" });
  }
  addCard(slide, "Conclusion card", 64, 982, 952, 166, C.redSoft);
  addText(slide, "Conclusion", template ? "[교체해야 할 용어와 원칙을 입력하세요]" : "Close · Edit · Cancel · Save: 전부 현지화 필요", 96, 1030, 840, 60, 30, C.red, { bold: true, align: "center", valign: "middle" });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideBadTwo(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 7, template);
  addSectionLabel(slide, "Bad section", "BAD 02", "NAVIGATION", false, template);
  addText(slide, "Main title", template ? "[탐색 문제를\n두 줄로 요약]" : "페이지 메타포가\n정보 구조를 숨긴다", 64, 205, 520, 160, 61, C.ink, { bold: true });
  addDotBullet(slide, "Bullet 1", template ? "[문제 근거 1]" : "1/3은 보이지만 전체 목록은 안 보임", 64, 435, 490, C.red, 26);
  addDotBullet(slide, "Bullet 2", template ? "[문제 근거 2]" : "원하는 카테고리로 바로 갈 수 없음", 64, 515, 490, C.red, 26);
  addDotBullet(slide, "Bullet 3", template ? "[문제 근거 3]" : "관리 화면은 설정 안쪽에 숨어 있음", 64, 595, 490, C.red, 26);
  await addImage(slide, "Evidence screenshot", IMG.main, 590, 205, 390, 780, { template, alt: "Praylist page navigation" });
  addCard(slide, "Verdict card", 64, 765, 490, 270, C.redSoft);
  addText(slide, "Verdict label", template ? "[판정 라벨]" : "적나라한 판정", 100, 810, 390, 34, 21, C.red, { bold: true });
  addText(slide, "Verdict", template ? "[현재 규모와 미래 규모의\n비용을 비교하세요]" : "카테고리 3개일 땐 낭만.\n10개가 되면 노동.", 100, 872, 400, 108, 36, C.ink, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideBadThree(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 8, template);
  addSectionLabel(slide, "Bad section", "BAD 03", "SAVE CONFIDENCE", false, template);
  addText(slide, "Main title", template ? "[피드백 문제를\n두 줄로 요약]" : "자동 저장은 편하다.\n그런데 저장됐다는 증거가 없다.", 64, 205, 900, 160, 55, C.ink, { bold: true });
  await addImage(slide, "Evidence screenshot", IMG.main, 64, 420, 402, 690, { template, alt: "Praylist note entry screen" });
  addCard(slide, "Behavior card", 505, 420, 510, 205, C.white, C.line);
  addText(slide, "Behavior label", template ? "[실제 동작]" : "실제 동작", 545, 457, 420, 32, 21, C.forest, { bold: true });
  addText(slide, "Behavior", template ? "[시스템이 실제로\n수행하는 동작]" : "키보드 ‘완료’ 또는\n다른 곳을 누르면 저장", 545, 513, 420, 82, 32, C.ink, { bold: true });
  addCard(slide, "Visible card", 505, 652, 510, 205, C.redSoft);
  addText(slide, "Visible label", template ? "[사용자가 보는 것]" : "사용자에게 보이는 것", 545, 689, 420, 32, 21, C.red, { bold: true });
  addText(slide, "Visible", template ? "[피드백 0]\n[복구 수단 0]" : "저장됨 표시 0\n되돌리기 0", 545, 745, 420, 82, 32, C.ink, { bold: true });
  addCard(slide, "Solution card", 505, 884, 510, 226, C.forest);
  addText(slide, "Solution", template ? "해법: [짧은 피드백]\n+ [복구 수단]" : "해법: 1초짜리 ‘저장됨’\n+ 편집 직후 실행 취소", 545, 937, 420, 110, 31, C.white, { bold: true });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideFixOrder(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 9, template);
  addPill(slide, "Fix order pill", template ? "[섹션 라벨]" : "FIX ORDER", 64, 134, 180, C.ink, C.white);
  addText(slide, "Main title", template ? "[우선순위 제목]" : "먼저 고칠 순서", 64, 210, 900, 90, 62, C.ink, { bold: true });
  const rows = template
    ? [
        ["P0", "[가장 시급한 문제]", "[작고 명확한 수정 범위]", C.red],
        ["P1", "[중요한 문제 1]", "[사용자 흐름을 개선할 수정]", C.forest],
        ["P1", "[중요한 문제 2]", "[피드백과 복구 수단]", C.forest],
        ["P2", "[후속 개선]", "[다음 반복에서 다룰 범위]", C.quiet],
      ]
    : [
        ["P0", "언어 일관성", "Close / Edit / Cancel / Save를 모두 현지화", C.red],
        ["P1", "카테고리 바로가기", "페이지 표시를 누르면 전체 목록과 현재 위치 노출", C.forest],
        ["P1", "저장 확신", "가벼운 저장 완료 피드백 + 즉시 실행 취소", C.forest],
        ["P2", "안내문 다이어트", "긴 설명은 첫 사용 힌트와 상황별 안내로 분리", C.quiet],
      ];
  rows.forEach((row, i) => {
    const y = 350 + i * 205;
    addCard(slide, `Priority ${i + 1} card`, 64, y, 952, 172, C.white, C.line);
    addPill(slide, `Priority ${i + 1} badge`, row[0], 94, y + 50, 92, row[3], C.white);
    addText(slide, `Priority ${i + 1} title`, row[1], 230, y + 35, 690, 48, 32, C.ink, { bold: true });
    addText(slide, `Priority ${i + 1} detail`, row[2], 230, y + 94, 700, 45, 24, C.quiet, { bold: true });
  });
  addFooter(slide);
  slide.speakerNotes.textFrame.setText(notes(template));
}

async function slideClosing(template = false) {
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  addHeader(slide, 10, template);
  await addImage(slide, "App icon", IMG.icon, 64, 142, 116, 116, { template, fit: "contain", backplate: false, alt: "Praylist app icon" });
  addText(slide, "Product name", template ? "[제품명]" : "praylist", 210, 154, 400, 42, 31, C.ink, { bold: true });
  addText(slide, "Series meta", template ? "[콘텐츠 유형 · 날짜]" : "UX AUDIT · 2026", 210, 205, 400, 30, 19, C.quiet, { bold: true });
  addText(slide, "Closing title dark", template ? "[현재까지의\n성과를 입력하세요]" : "예쁜 노트는\n이미 됐다.", 64, 350, 850, 170, 67, C.ink, { bold: true });
  addText(slide, "Closing title green", template ? "[다음 목표를\n입력하세요]" : "이제 길 잃지 않는\n제품으로.", 64, 545, 850, 170, 67, C.forest, { bold: true });
  addCard(slide, "CTA card", 64, 800, 952, 292, C.ink);
  addText(slide, "CTA question", template ? "[독자에게 던질 질문]" : "당신이라면 무엇부터 고칠까요?", 110, 854, 860, 62, 40, C.white, { bold: true, align: "center" });
  addText(slide, "CTA options", template ? "[선택지 1 · 선택지 2 · 선택지 3]" : "언어 · 탐색 · 저장 확신", 110, 956, 860, 50, 28, C.mint, { bold: true, align: "center" });
  addFooter(slide, template ? "[브랜드 · 시리즈명]" : "PRAYLIST · HONEST BUILD LOG");
  slide.speakerNotes.textFrame.setText(notes(template));
}

for (const isTemplate of [false, true]) {
  await slideCover(isTemplate);
  await slideVerdict(isTemplate);
  await slideGoodOne(isTemplate);
  await slideGoodTwo(isTemplate);
  await slideGoodThree(isTemplate);
  await slideBadOne(isTemplate);
  await slideBadTwo(isTemplate);
  await slideBadThree(isTemplate);
  await slideFixOrder(isTemplate);
  await slideClosing(isTemplate);
}

await fs.mkdir(BUILD_DIR, { recursive: true });
await fs.mkdir(OUT_DIR, { recursive: true });

const stagingDir = path.join(BUILD_DIR, ".codex-finalizer");
await fs.mkdir(stagingDir, { recursive: true });
const candidatePath = path.join(stagingDir, "candidate.pptx");
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);

const { finalizePresentation } = await import(pathToFileURL(
  path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs"),
).href);

const result = await finalizePresentation({
  explicitTotalSlideCount: 20,
  workspaceDir: ROOT,
  candidatePath,
  finalPath: FINAL_PPTX,
  pythonExecutable: RUNTIME_PYTHON,
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: [
    "--expected-slide-size-emu", "10287000,12858750",
    "--validate-bullet-geometry",
    "--validate-heading-fit",
  ],
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  fontPolicy: { basis: "design", families: [FONT] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(stagingDir, `${path.basename(FINAL_PPTX)}.validation.json`),
});

console.log(JSON.stringify({ finalPath: FINAL_PPTX, result }, null, 2));
