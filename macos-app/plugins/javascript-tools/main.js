// NPad++ community plugin: JavaScript & TypeScript Tools (MIT)
function dedent(t) {
  var ls = t.replace(/^\s*\n/, "").replace(/\s+$/, "").split("\n"), min = Infinity;
  ls.forEach(function (l) { if (l.trim()) min = Math.min(min, l.match(/^[ \t]*/)[0].length); });
  if (min === Infinity) min = 0;
  return ls.map(function (l) { return l.slice(min); });
}
function indent(ls, pad) { return ls.map(function (l) { return l.trim() ? pad + l : ""; }).join("\n"); }
function lead(t) { var m = t.replace(/^\s*\n/, "").match(/^[ \t]*/); return m ? m[0] : ""; }

commands.wrapIife = function (t) {
  var pad = lead(t);
  return pad + '(function () {\n' + pad + '    "use strict";\n\n' + indent(dedent(t), pad + "    ") + "\n" + pad + "})();";
};

commands.wrapAsyncMain = function (t) {
  return "async function main() {\n" + indent(dedent(t), "    ") + "\n}\n\nmain().catch((err) => {\n    console.error(err);\n    process.exitCode = 1;\n});";
};

commands.wrapTryCatch = function (t) {
  var pad = lead(t);
  return pad + "try {\n" + indent(dedent(t), pad + "    ") + "\n" + pad + "} catch (err) {\n" + pad + "    console.error(err);\n" + pad + "}";
};

commands.wrapDomReady = function (t) {
  var pad = lead(t);
  return pad + 'document.addEventListener("DOMContentLoaded", () => {\n' + indent(dedent(t), pad + "    ") + "\n" + pad + "});";
};
