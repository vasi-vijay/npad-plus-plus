// NPad++ community plugin: Text Case Converter (MIT)
function words(s) {
  return s.replace(/([a-z0-9])([A-Z])/g, "$1 $2").split(/[^A-Za-z0-9]+/).filter(Boolean);
}
function perLine(text, fn) {
  return text.split("\n").map(fn).join("\n");
}
commands.upper = function (t) { return t.toUpperCase(); };
commands.lower = function (t) { return t.toLowerCase(); };
commands.title = function (t) {
  return t.toLowerCase().replace(/(^|\s)(\S)/g, function (m, a, b) { return a + b.toUpperCase(); });
};
commands.camel = function (t) {
  return perLine(t, function (l) {
    return words(l).map(function (w, i) {
      w = w.toLowerCase();
      return i === 0 ? w : w.charAt(0).toUpperCase() + w.slice(1);
    }).join("");
  });
};
commands.snake = function (t) {
  return perLine(t, function (l) { return words(l).join("_").toLowerCase(); });
};
commands.kebab = function (t) {
  return perLine(t, function (l) { return words(l).join("-").toLowerCase(); });
};
