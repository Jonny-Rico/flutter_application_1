/* Persist help language and rewrite peer links */
(function () {
  var path = location.pathname.replace(/\\/g, "/");
  var isRu = /\/ru\//.test(path) || path.endsWith("/ru") || path.endsWith("/ru/index.html");
  var isEn = /\/en\//.test(path) || path.endsWith("/en") || path.endsWith("/en/index.html");
  var lang = isRu ? "ru" : "en";

  try {
    localStorage.setItem("ft_help_lang", lang);
  } catch (e) {}

  document.querySelectorAll("[data-lang-switch]").forEach(function (el) {
    el.addEventListener("click", function () {
      var target = el.getAttribute("data-lang-switch");
      try {
        localStorage.setItem("ft_help_lang", target);
      } catch (e) {}
    });
  });
})();
