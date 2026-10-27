// NPad++ community plugin: URL & HTML Codec (MIT)
var NAMED = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " " };
commands.urlEncode = function (t) { return encodeURIComponent(t); };
commands.urlDecode = function (t) { return decodeURIComponent(t.replace(/\+/g, " ")); };
commands.htmlEscape = function (t) {
  return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
          .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
};
commands.htmlUnescape = function (t) {
  return t.replace(/&(#x[0-9a-f]+|#[0-9]+|[a-z]+);/gi, function (m, e) {
    if (e.charAt(0) === "#") {
      var code = e.charAt(1).toLowerCase() === "x" ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
      return String.fromCodePoint(code);
    }
    return NAMED.hasOwnProperty(e.toLowerCase()) ? NAMED[e.toLowerCase()] : m;
  });
};
