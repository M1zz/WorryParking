// Picks Korean or English from ?lang=, a saved choice, or the browser language.
(function () {
  var root = document.documentElement;
  var params = new URLSearchParams(location.search);
  var saved = null;
  try { saved = localStorage.getItem("lang"); } catch (e) {}
  var lang = params.get("lang") || saved ||
    ((navigator.language || "").toLowerCase().indexOf("ko") === 0 ? "ko" : "en");
  if (lang !== "ko" && lang !== "en") lang = "en";

  function apply(next) {
    root.setAttribute("data-lang", next);
    root.setAttribute("lang", next);
    var titles = { ko: root.getAttribute("data-title-ko"), en: root.getAttribute("data-title-en") };
    if (titles[next]) document.title = titles[next];
    document.querySelectorAll("[data-set-lang]").forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-set-lang") === next));
    });
  }

  apply(lang);
  document.addEventListener("DOMContentLoaded", function () {
    apply(root.getAttribute("data-lang"));
    document.querySelectorAll("[data-set-lang]").forEach(function (button) {
      button.addEventListener("click", function () {
        var next = button.getAttribute("data-set-lang");
        try { localStorage.setItem("lang", next); } catch (e) {}
        apply(next);
      });
    });
  });
})();
