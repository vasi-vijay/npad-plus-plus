// NPad++ community plugin: Go Tools (MIT)
function dedent(t) {
  var ls = t.replace(/^\s*\n/, "").replace(/\s+$/, "").split("\n"), min = Infinity;
  ls.forEach(function (l) { if (l.trim()) min = Math.min(min, l.match(/^[ \t]*/)[0].length); });
  if (min === Infinity) min = 0;
  return ls.map(function (l) { return l.slice(min); });
}
function indent(ls, pad) { return ls.map(function (l) { return l.trim() ? pad + l : ""; }).join("\n"); }
function lead(t) { var m = t.replace(/^\s*\n/, "").match(/^[ \t]*/); return m ? m[0] : ""; }
function typeName(ctx, fallback) {
  var n = ((ctx && ctx.fileName) || "").replace(/\.[^.]*$/, "").replace(/[^A-Za-z0-9]+(.)?/g, function (m, c) { return c ? c.toUpperCase() : ""; });
  return /^[A-Za-z]/.test(n) ? n.charAt(0).toUpperCase() + n.slice(1) : fallback;
}
function inner(t) { var ls = dedent(t); return ls.join("").trim() ? indent(ls, "\t") + "\n" : ""; }

commands.wrapMain = function (t) {
  return "package main\n\nfunc main() {\n" + inner(t) + "}";
};

commands.wrapFunc = function (t) {
  return "func myFunction() error {\n" + inner(t) + "\treturn nil\n}";
};

commands.structFromFields = function (t, ctx) {
  var fields = [];
  t.split("\n").forEach(function (l) {
    var s = l.trim();
    if (!s) return;
    if (!/^\w+\s+[\w\[\]\*\.]+(\s+`[^`]*`)?$/.test(s)) throw new Error("Expected lines like 'Name string', got: " + s);
    fields.push(s);
  });
  if (!fields.length) throw new Error("Select field lines such as: Name string");
  return "type " + typeName(ctx, "Data") + " struct {\n" + fields.map(function (f) { return "\t" + f; }).join("\n") + "\n}";
};

commands.wrapGoroutine = function (t) {
  var pad = lead(t);
  return pad + "go func() {\n" + indent(dedent(t), pad + "\t") + "\n" + pad + "}()";
};
