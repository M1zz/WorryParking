// 걱정 주차장 웹 체험: 걱정 하나를 적어 주차하고, 걱정 시간에 꺼내 본다.
// 규칙은 앱과 같다. 걱정 시간 기본값 오후 6시, 30분 안쪽이면 다음 날 (WorryTime.next),
// 칸은 비어 있는 가장 작은 번호 (Worry.nextFreeSpot), 강도는 주차 1~5 · 출차 0~5 (IntensityPicker).
// 글은 이 페이지 안에만 있고 어디에도 저장하거나 보내지 않는다.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const lang = document.documentElement.lang;
  const fill = (s, v) => s.replace("{n}", v.n ?? "").replace("{t}", v.t ?? "");
  const esc = s => s.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

  const SPOTS = 3;
  const state = { step: "write", level: 3, after: 3, fear: null, text: T.sample, spot: 1, parked: [], when: "" };

  function nextWorryTime(after = new Date()) {
    const earliest = new Date(after.getTime() + 30 * 60 * 1000);
    const t = new Date(earliest); t.setHours(18, 0, 0, 0);
    if (t <= earliest) t.setDate(t.getDate() + 1);
    return t;
  }
  // 걱정 시간은 언제나 오늘 아니면 내일이다. 다시 주차하면 다음 날 같은 시각 (앞당김 2시간).
  function describe(date, tomorrow) {
    const time = new Intl.DateTimeFormat(lang, { hour: "numeric", minute: "2-digit" }).format(date);
    return fill(tomorrow || date.getDate() !== new Date().getDate() ? T.tomorrow : T.today, { t: time });
  }
  const freeSpot = () => { let n = 1; while (state.parked.includes(n)) n++; return n; };

  const levels = (from, key) => `<div class="wp-levels" role="radiogroup" aria-label="${esc(key === "level" ? T.loud : T.loudNow)}">
      ${Array.from({ length: 6 - from }, (_, i) => i + from).map(n =>
        `<button type="button" role="radio" aria-checked="${state[key] === n}" data-${key}="${n}">${n}</button>`).join("")}
    </div><p class="muted small wp-level-name">${esc(T.levels[state[key]])}</p>`;

  function lot() {
    return `<div class="wp-lot" aria-hidden="true">${Array.from({ length: SPOTS }, (_, i) => {
      const n = i + 1, here = state.parked.includes(n), open = here && state.step === "gate" && n === state.spot;
      return `<div class="wp-spot${here ? " taken" : ""}"><b>P${n}</b>${here
        ? `<span class="wp-ticket${open ? " open" : ""}">${esc(n === state.spot ? state.text : "")}</span>` : "<i>+</i>"}</div>`;
    }).join("")}</div>`;
  }

  function panel() {
    if (state.step === "write") return `
      <label class="wp-q" for="wp-text">${esc(T.ask)}</label>
      <textarea id="wp-text" rows="3" maxlength="200" placeholder="${esc(T.placeholder)}">${esc(state.text)}</textarea>
      <p class="wp-q">${esc(T.loud)}</p>${levels(1, "level")}
      <button type="button" class="wp-go" data-act="park">${esc(fill(T.park, { n: freeSpot() }))}</button>`;
    if (state.step === "parked") return `
      <p class="wp-big" role="status">${esc(fill(T.parked, { n: state.spot }))}</p>
      <p class="muted">${esc(fill(T.back, { t: state.when }))}</p>
      <button type="button" class="wp-go" data-act="gate">${esc(T.skip)}</button>`;
    if (state.step === "gate") return `
      <p class="wp-gate">${esc(fill(T.gate, { n: state.spot }))}</p>
      <p class="wp-q">${esc(T.fear)}</p>
      <div class="wp-chips">${T.results.map((r, i) =>
        `<button type="button" class="chip" aria-pressed="${state.fear === i}" data-fear="${i}">${esc(r)}</button>`).join("")}</div>
      <p class="wp-q">${esc(T.loudNow)}</p>${levels(0, "after")}
      <p class="muted small">${esc(fill(T.was, { n: state.level }))}</p>
      <div class="wp-row">
        <button type="button" class="wp-go" data-act="letGo"${state.fear === null ? " disabled" : ""}>${esc(T.letGo)}</button>
        <button type="button" class="wp-ghost" data-act="repark">${esc(T.repark)}</button>
      </div>`;
    return `
      <p class="wp-big" role="status">${state.level} → ${state.after}</p>
      <p class="muted small">${esc(T.levels[state.level])} → ${esc(T.levels[state.after])}</p>
      <p class="muted">${esc(T.gone)}</p>
      <button type="button" class="wp-go" data-act="again">${esc(T.again)}</button>`;
  }

  function render(focus) {
    root.innerHTML = `<div class="wp-stage">${lot()}</div>
      <div class="wp-panel">${panel()}<p class="muted small demo-note">${esc(T.note)}</p></div>`;
    const target = focus && root.querySelector(focus);
    if (target) target.focus();
  }

  root.addEventListener("input", e => { if (e.target.id === "wp-text") state.text = e.target.value; });
  root.addEventListener("click", e => {
    const b = e.target.closest("button");
    if (!b || b.disabled) return;
    const box = root.querySelector("#wp-text");
    if (box) state.text = box.value;
    if (b.dataset.level) { state.level = +b.dataset.level; return render(`[data-level="${b.dataset.level}"]`); }
    if (b.dataset.after) { state.after = +b.dataset.after; return render(`[data-after="${b.dataset.after}"]`); }
    if (b.dataset.fear) { state.fear = +b.dataset.fear; return render(`[data-fear="${b.dataset.fear}"]`); }
    const act = b.dataset.act;
    if (act === "park") {
      state.text = state.text.trim();
      if (!state.text) { root.querySelector("#wp-text").focus(); return; }
      state.spot = freeSpot(); state.parked.push(state.spot);
      state.when = describe(nextWorryTime()); state.step = "parked";
    } else if (act === "gate") {
      state.step = "gate"; state.fear = null; state.after = state.level;
    } else if (act === "repark") {
      state.when = describe(nextWorryTime(), true); state.step = "parked";
    } else if (act === "letGo") {
      state.parked = state.parked.filter(n => n !== state.spot); state.step = "done";
    } else if (act === "again") {
      state.step = "write"; state.text = ""; state.level = 3;
      return render("#wp-text");
    }
    render(".wp-panel .wp-go");
  });

  render();
})();
