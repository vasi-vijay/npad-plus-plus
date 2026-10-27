// NPad++ community plugin: Whitespace Cleaner (MIT)
function perLine(text, fn) { return text.split("\n").map(fn).join("\n"); }
commands.trimTrailing = function (t) { return perLine(t, function (l) { return l.replace(/[ \t]+$/, ""); }); };
commands.trimBoth = function (t) { return perLine(t, function (l) { return l.trim(); }); };
commands.removeBlankLines = function (t) {
  return t.split("\n").filter(function (l) { return l.trim() !== ""; }).join("\n");
};
commands.collapseBlankLines = function (t) { return t.replace(/\n{3,}/g, "\n\n"); };
commands.tabsToSpaces = function (t) { return t.replace(/\t/g, "    "); };
