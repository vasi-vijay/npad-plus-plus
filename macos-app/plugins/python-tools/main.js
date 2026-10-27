// NPad++ community plugin: Python Tools (MIT)
function dedent(t) {
  var ls = t.replace(/^\s*\n/, "").replace(/\s+$/, "").split("\n"), min = Infinity;
  ls.forEach(function (l) { if (l.trim()) min = Math.min(min, l.match(/^[ \t]*/)[0].length); });
  if (min === Infinity) min = 0;
  return ls.map(function (l) { return l.slice(min); });
}
function indent(ls, pad) { return ls.map(function (l) { return l.trim() ? pad + l : ""; }).join("\n"); }
function lead(t) { var m = t.replace(/^\s*\n/, "").match(/^[ \t]*/); return m ? m[0] : ""; }
function body(t, pad) { var ls = dedent(t); return ls.join("").trim() ? indent(ls, pad) : pad + "pass"; }
function typeName(ctx, fallback) {
  var n = ((ctx && ctx.fileName) || "").replace(/\.[^.]*$/, "").replace(/[^A-Za-z0-9]+(.)?/g, function (m, c) { return c ? c.toUpperCase() : ""; });
  return /^[A-Za-z]/.test(n) ? n.charAt(0).toUpperCase() + n.slice(1) : fallback;
}

commands.wrapMain = function (t) {
  return "def main():\n" + body(t, "    ") + '\n\n\nif __name__ == "__main__":\n    main()';
};

commands.wrapTryExcept = function (t) {
  var pad = lead(t);
  return pad + "try:\n" + body(t, pad + "    ") + "\n" + pad + "except Exception as e:\n" + pad + '    print(f"Error: {e}")';
};

commands.wrapFunction = function (t) {
  var pad = lead(t);
  return pad + "def my_function():\n" + body(t, pad + "    ");
};

commands.dataclass = function (t, ctx) {
  var fields = [];
  t.split("\n").forEach(function (l) {
    var s = l.trim();
    if (!s || s.charAt(0) === "#") return;
    if (!/^\w+\s*:\s*[^=]+?(\s*=.*)?$/.test(s)) throw new Error("Expected lines like 'name: str' or 'count: int = 0', got: " + s);
    fields.push(s);
  });
  if (!fields.length) throw new Error("Select field lines such as: name: str");
  return "from dataclasses import dataclass\n\n\n@dataclass\nclass " + typeName(ctx, "Data") + ":\n" +
    fields.map(function (f) { return "    " + f; }).join("\n");
};
