// NPad++ community plugin: Comment Wrapper (MIT)
// Comments code out using the syntax of the document's language.

var SLASH = ["java", "c", "c++", "c#", "javascript", "typescript", "go", "rust", "swift", "kotlin", "php", "objective-c", "scala", "dart", "groovy", "glsl"];
var HASH = ["python", "ruby", "shell", "bash", "shell script", "unix shell script", "perl", "yaml", "toml", "makefile", "r", "powershell", "cmake", "dockerfile", "coffeescript", "julia", "nim", "elixir"];
var DASH = ["sql", "lua", "haskell", "ada", "vhdl"];
var SEMI = ["lisp", "scheme", "clojure", "assembly", "ini", "autohotkey"];
var PERCENT = ["latex", "tex", "matlab", "erlang"];
var QUOTE = ["vb", "visual basic", "vbscript"];
var BLOCK_C = ["java", "c", "c++", "c#", "javascript", "typescript", "go", "rust", "swift", "kotlin", "php", "objective-c", "scala", "dart", "groovy", "css", "sql", "glsl"];
var EXT = { java: "java", py: "python", c: "c", h: "c", cpp: "c++", cc: "c++", hpp: "c++", cs: "c#", js: "javascript", ts: "typescript",
  go: "go", rs: "rust", swift: "swift", kt: "kotlin", php: "php", rb: "ruby", sh: "shell", sql: "sql", lua: "lua", css: "css", html: "html", xml: "xml", yml: "yaml", yaml: "yaml" };

function language(ctx) {
  var l = ((ctx && ctx.language) || "").toLowerCase();
  if (l && l !== "plain text") return l;
  var e = EXT[((ctx && ctx.extension) || "").toLowerCase()];
  if (e) return e;
  throw new Error("Can't tell which language this is. Set the document language from the Language menu.");
}
function lineMarker(l) {
  if (SLASH.indexOf(l) >= 0) return "//";
  if (HASH.indexOf(l) >= 0) return "#";
  if (DASH.indexOf(l) >= 0) return "--";
  if (SEMI.indexOf(l) >= 0) return ";";
  if (PERCENT.indexOf(l) >= 0) return "%";
  if (QUOTE.indexOf(l) >= 0) return "'";
  return null;
}
function esc(s) { return s.replace(/[.*+?^${}()|[\]\\\/-]/g, "\\$&"); }
function body(t) { return t.replace(/^\s*\n/, "").replace(/\s+$/, ""); }

commands.commentLines = function (t, ctx) {
  var l = language(ctx), m = lineMarker(l);
  if (!m) throw new Error(ctx.language + " has no single-line comment marker. Use Block Comment instead.");
  var ls = body(t).split("\n"), min = Infinity;
  ls.forEach(function (x) { if (x.trim()) min = Math.min(min, x.match(/^[ \t]*/)[0].length); });
  if (min === Infinity) min = 0;
  return ls.map(function (x) { return x.trim() ? x.slice(0, min) + m + " " + x.slice(min) : x; }).join("\n");
};

commands.uncommentLines = function (t, ctx) {
  var m = lineMarker(language(ctx));
  if (!m) throw new Error(ctx.language + " has no single-line comment marker.");
  var re = new RegExp("^([ \\t]*)" + esc(m) + " ?");
  return body(t).split("\n").map(function (x) { return x.replace(re, "$1"); }).join("\n");
};

commands.blockComment = function (t, ctx) {
  var l = language(ctx), b = body(t);
  if (BLOCK_C.indexOf(l) >= 0) return "/*\n" + b + "\n*/";
  if (l === "html" || l === "xml") return "<!--\n" + b + "\n-->";
  if (l === "ruby") return "=begin\n" + b + "\n=end";
  if (l === "lua") return "--[[\n" + b + "\n]]";
  if (l === "haskell") return "{-\n" + b + "\n-}";
  throw new Error(ctx.language + " has no block comment syntax. Use Comment Lines instead.");
};

commands.docComment = function (t, ctx) {
  var l = language(ctx), ls = body(t).split("\n");
  if (["java", "c", "c++", "c#", "javascript", "typescript", "php", "kotlin", "scala", "dart", "groovy", "objective-c"].indexOf(l) >= 0) {
    return "/**\n" + ls.map(function (x) { return x ? " * " + x : " *"; }).join("\n") + "\n */";
  }
  if (l === "python") return '"""' + (ls.length > 1 ? "\n" + ls.join("\n") + "\n" : ls[0]) + '"""';
  if (l === "rust" || l === "swift") return ls.map(function (x) { return x ? "/// " + x : "///"; }).join("\n");
  if (l === "go") return ls.map(function (x) { return x ? "// " + x : "//"; }).join("\n");
  throw new Error("Doc comments aren't supported for " + ctx.language + ".");
};
