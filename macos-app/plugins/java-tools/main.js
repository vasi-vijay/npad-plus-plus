// NPad++ community plugin: Java Tools (MIT)
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

var FIELD = /^\s*(?:(?:private|protected|public|static)\s+)*(final\s+)?([\w<>\[\],.? ]+?)\s+(\w+)\s*(?:=[^;]*)?;/;
function parseFields(t) {
  var fields = [];
  t.split("\n").forEach(function (l) {
    var m = FIELD.exec(l);
    if (m && !/\(/.test(l.split("=")[0])) fields.push({ final: !!m[1], type: m[2].trim(), name: m[3] });
  });
  if (!fields.length) throw new Error("No field declarations found. Select lines such as: private String name;");
  return fields;
}

commands.wrapMain = function (t, ctx) {
  var body = dedent(t);
  var cls = ctx && ctx.extension === "java" ? typeName(ctx, "Main") : "Main";
  return "public class " + cls + " {\n    public static void main(String[] args) {\n" +
    (body.join("").trim() ? indent(body, "        ") + "\n" : "") + "    }\n}";
};

commands.wrapTryCatch = function (t) {
  var pad = lead(t), body = dedent(t);
  return pad + "try {\n" + indent(body, pad + "    ") + "\n" + pad + "} catch (Exception e) {\n" +
    pad + "    e.printStackTrace();\n" + pad + "}";
};

commands.gettersSetters = function (t) {
  var fields = parseFields(t), pad = lead(t), out = [];
  fields.forEach(function (f) {
    var getter = (f.type === "boolean" ? "is" : "get") + cap(f.name);
    out.push(pad + "public " + f.type + " " + getter + "() {\n" + pad + "    return " + f.name + ";\n" + pad + "}");
    if (!f.final) {
      out.push(pad + "public void set" + cap(f.name) + "(" + f.type + " " + f.name + ") {\n" +
        pad + "    this." + f.name + " = " + f.name + ";\n" + pad + "}");
    }
  });
  return t.replace(/\s+$/, "") + "\n\n" + out.join("\n\n");
};

commands.record = function (t, ctx) {
  var fields = parseFields(t);
  return "public record " + typeName(ctx, "Data") + "(" +
    fields.map(function (f) { return f.type + " " + f.name; }).join(", ") + ") {}";
};
