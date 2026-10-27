// NPad++ community plugin: JSON Wrapper (MIT)
// Embeds JSON text in source code as a string literal, using the style of the document's language.

var ALIASES = {
  "java": "java", "python": "python", "c": "c", "c++": "cpp", "cpp": "cpp",
  "c#": "csharp", "csharp": "csharp", "javascript": "javascript", "typescript": "javascript",
  "go": "go", "golang": "go", "rust": "rust", "swift": "swift", "kotlin": "kotlin",
  "php": "php", "ruby": "ruby", "shell": "shell", "bash": "shell", "shell script": "shell",
  "unix shell script": "shell", "sh": "shell", "zsh": "shell"
};
var EXTENSIONS = {
  java: "java", py: "python", c: "c", h: "c", cpp: "cpp", cc: "cpp", cxx: "cpp", hpp: "cpp",
  cs: "csharp", js: "javascript", mjs: "javascript", jsx: "javascript", ts: "javascript", tsx: "javascript",
  go: "go", rs: "rust", swift: "swift", kt: "kotlin", php: "php", rb: "ruby", sh: "shell", bash: "shell", zsh: "shell"
};
var NAMES = {
  java: "Java", python: "Python", c: "C", cpp: "C++", csharp: "C#", javascript: "JavaScript / TypeScript",
  go: "Go", rust: "Rust", swift: "Swift", kotlin: "Kotlin", php: "PHP", ruby: "Ruby", shell: "Shell"
};

function lines(b) { return b.split("\n"); }
function cEscape(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\t/g, "\\t").replace(/\r/g, "\\r");
}
function longestRun(s, re) {
  var best = 0, m;
  while ((m = re.exec(s)) !== null) { if (m[1].length > best) best = m[1].length; }
  return best;
}

var WRAPPERS = {
  java: function (b) {
    var body = b.replace(/\\/g, "\\\\");
    // Quotes are escaped only where they could end the text block early: runs of three or more, or a trailing quote.
    body = body.replace(/"+/g, function (run, offset) {
      var atEnd = offset + run.length === body.length;
      return (run.length >= 3 || atEnd) ? run.replace(/"/g, '\\"') : run;
    });
    var pad = lines(body).map(function (l) { return l === "" ? "" : "    " + l; }).join("\n");
    return 'String json = """\n' + pad + '""";';
  },
  python: function (b) {
    var body = b.replace(/\\/g, "\\\\");
    // Quotes are left alone except where they would end or confuse the triple-quoted literal.
    body = body.replace(/"+/g, function (run, offset) {
      var edge = offset === 0 || offset + run.length === body.length;
      return (run.length >= 3 || edge) ? run.replace(/"/g, '\\"') : run;
    });
    return 'json_text = """' + body + '"""';
  },
  c: function (b) {
    var ls = lines(b);
    if (ls.length === 1) return 'const char *json = "' + cEscape(ls[0]) + '";';
    return "const char *json =\n" + ls.map(function (l, i) {
      return '    "' + cEscape(l) + (i < ls.length - 1 ? "\\n" : "") + '"';
    }).join("\n") + ";";
  },
  cpp: function (b) {
    var tag = "json", n = 0;
    while (b.indexOf(")" + tag + '"') !== -1) { n++; tag = "json" + n; }
    return 'const std::string json = R"' + tag + "(" + b + ")" + tag + '";';
  },
  csharp: function (b) {
    return 'string json = @"' + b.replace(/"/g, '""') + '";';
  },
  javascript: function (b) {
    return "const json = `" + b.replace(/\\/g, "\\\\").replace(/`/g, "\\`").replace(/\$\{/g, "\\${") + "`;";
  },
  go: function (b) {
    return "const jsonText = `" + b.replace(/`/g, '` + "`" + `') + "`";
  },
  rust: function (b) {
    var hashes = new Array(longestRun(b, /"(#*)/g) + 2).join("#");
    return "const JSON: &str = r" + hashes + '"' + b + '"' + hashes + ";";
  },
  swift: function (b) {
    var hashes = new Array(longestRun(b, /(#+)/g) + 2).join("#");
    var pad = lines(b).map(function (l) { return l === "" ? "" : "    " + l; }).join("\n");
    return "let json = " + hashes + '"""\n' + pad + '\n    """' + hashes;
  },
  kotlin: function (b) {
    return 'val json = """' + b.replace(/\$/g, "${'$'}").replace(/"""/g, "${'\"'}${'\"'}${'\"'}") + '"""';
  },
  php: function (b) {
    return "$json = <<<'JSON'\n" + b + "\nJSON;";
  },
  ruby: function (b) {
    return "json = <<-'JSON'.chomp\n" + b + "\nJSON";
  },
  shell: function (b) {
    return "json='" + b.replace(/'/g, "'\\''") + "'";
  }
};

function wrap(text, ctx, target, minify) {
  var value;
  try { value = JSON.parse(text); }
  catch (e) { throw new Error("The text is not valid JSON (" + e.message + ")."); }
  var body = minify ? JSON.stringify(value) : text.replace(/^\s*\n/, "").replace(/\s+$/, "");

  if (!target) {
    ctx = ctx || {};
    target = ALIASES[(ctx.language || "").toLowerCase()] || EXTENSIONS[(ctx.extension || "").toLowerCase()];
  }
  if (!target) {
    throw new Error("Can't tell which language to wrap for. Set the document language (Language menu) to Java, Python, C… or use Plugins ▸ JSON Wrapper ▸ Wrap as…");
  }
  return WRAPPERS[target](body);
}

commands.wrapJson = function (t, ctx) { return wrap(t, ctx, null, false); };
commands.wrapJsonMinified = function (t, ctx) { return wrap(t, ctx, null, true); };
Object.keys(NAMES).forEach(function (target) {
  commands["as_" + target] = function (t, ctx) { return wrap(t, ctx, target, false); };
});
