// NPad++ community plugin: C Tools (MIT)
function dedent(t) {
  var ls = t.replace(/^\s*\n/, "").replace(/\s+$/, "").split("\n"), min = Infinity;
  ls.forEach(function (l) { if (l.trim()) min = Math.min(min, l.match(/^[ \t]*/)[0].length); });
  if (min === Infinity) min = 0;
  return ls.map(function (l) { return l.slice(min); });
}
function indent(ls, pad) { return ls.map(function (l) { return l.trim() ? pad + l : ""; }).join("\n"); }
function typeName(ctx, fallback) {
  var n = ((ctx && ctx.fileName) || "").replace(/\.[^.]*$/, "").replace(/[^A-Za-z0-9]+(.)?/g, function (m, c) { return c ? c.toUpperCase() : ""; });
  return /^[A-Za-z]/.test(n) ? n.charAt(0).toUpperCase() + n.slice(1) : fallback;
}

commands.wrapMain = function (t) {
  var body = dedent(t);
  return "#include <stdio.h>\n\nint main(void) {\n" + (body.join("").trim() ? indent(body, "    ") + "\n" : "") +
    "    return 0;\n}";
};

commands.includeGuard = function (t, ctx) {
  var base = ((ctx && ctx.fileName) || "").replace(/[^A-Za-z0-9]+/g, "_").replace(/^_+|_+$/g, "").toUpperCase();
  if (!base || /^[0-9]/.test(base)) base = "INCLUDE_GUARD_H";
  if (!/_H(PP|H|XX)?$/.test(base)) base += "_H";
  return "#ifndef " + base + "\n#define " + base + "\n\n" + t.replace(/^\s*\n/, "").replace(/\s+$/, "") + "\n\n#endif /* " + base + " */";
};

commands.structFromFields = function (t, ctx) {
  var fields = [];
  t.split("\n").forEach(function (l) {
    var s = l.trim();
    if (!s) return;
    if (!/^[\w\s\*\[\]]+;$/.test(s)) throw new Error("Expected field declarations such as 'int x;', got: " + s);
    fields.push(s);
  });
  if (!fields.length) throw new Error("Select field lines such as: int x;");
  return "typedef struct {\n" + fields.map(function (f) { return "    " + f; }).join("\n") + "\n} " + typeName(ctx, "Data") + ";";
};

commands.externC = function (t) {
  return "#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n" + t.replace(/^\s*\n/, "").replace(/\s+$/, "") +
    "\n\n#ifdef __cplusplus\n}\n#endif";
};
