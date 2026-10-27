// NPad++ community plugin: C++ Tools (MIT)
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
function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1); }

commands.wrapMain = function (t) {
  var body = dedent(t);
  return "#include <iostream>\n\nint main() {\n" + (body.join("").trim() ? indent(body, "    ") + "\n" : "") +
    "    return 0;\n}";
};

commands.wrapTryCatch = function (t) {
  var pad = lead(t);
  return pad + "try {\n" + indent(dedent(t), pad + "    ") + "\n" + pad + "} catch (const std::exception& e) {\n" +
    pad + "    std::cerr << e.what() << std::endl;\n" + pad + "}";
};

commands.wrapNamespace = function (t) {
  return "namespace app {\n\n" + t.replace(/^\s*\n/, "").replace(/\s+$/, "") + "\n\n}  // namespace app";
};

commands.classFromFields = function (t, ctx) {
  var fields = [];
  t.split("\n").forEach(function (l) {
    var s = l.trim();
    if (!s) return;
    var m = /^([\w:<>,\s\*&]+?[\s\*&])(\w+)\s*;$/.exec(s);
    if (!m) throw new Error("Expected member declarations such as 'int x;' or 'std::string name;', got: " + s);
    fields.push({ type: m[1].trim(), name: m[2] });
  });
  if (!fields.length) throw new Error("Select member lines such as: int x;");
  var cls = typeName(ctx, "Data");
  function decl(f) { return /[\*&]$/.test(f.type) ? f.type + f.name : f.type + " " + f.name; }
  var out = "class " + cls + " {\npublic:\n";
  out += "    " + cls + "(" + fields.map(decl).join(", ") + ")\n        : " +
    fields.map(function (f) { return f.name + "_(" + f.name + ")"; }).join(", ") + " {}\n\n";
  fields.forEach(function (f) { out += "    " + f.type + " get" + cap(f.name) + "() const { return " + f.name + "_; }\n"; });
  out += "\nprivate:\n" + fields.map(function (f) { return "    " + decl({ type: f.type, name: f.name + "_" }) + ";"; }).join("\n") + "\n};";
  return out;
};
