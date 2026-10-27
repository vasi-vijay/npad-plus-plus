#!/usr/bin/env python3
"""Tests every community plugin through the app's own JSPluginRunner and, where a toolchain is installed,
compiles/executes the generated code to prove it is valid.

    ./build_runner.sh && ./test_plugins.py
"""
import hashlib, json, os, pathlib, re, shutil, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
PLUGINS = HERE.parent
RUNNER = HERE / "build" / "plugin-runner"
TOOLS = {t: shutil.which(t) for t in ["python3", "node", "javac", "java", "cc", "g++", "ruby", "bash", "swiftc"]}

passed, failed, skipped = 0, [], []


def run(plugin, command, text, lang="Plain Text", file="Untitled"):
    p = subprocess.run([str(RUNNER), str(PLUGINS / plugin), command, lang, file], input=text.encode(),
                       capture_output=True, timeout=30)
    return p.returncode, p.stdout.decode(), p.stderr.decode().strip()


def out(plugin, command, text, lang="Plain Text", file="Untitled"):
    rc, so, se = run(plugin, command, text, lang, file)
    if rc != 0:
        raise AssertionError(f"{plugin}.{command} failed: {se}")
    return so


def check(name, fn):
    global passed
    try:
        fn()
        passed += 1
        print(f"PASS  {name}")
    except Skip as s:
        skipped.append(name)
        print(f"SKIP  {name} ({s})")
    except Exception as e:  # noqa: BLE001
        failed.append(name)
        print(f"FAIL  {name}: {e}")


class Skip(Exception):
    pass


def need(*tools):
    missing = [t for t in tools if not TOOLS[t]]
    if missing:
        raise Skip("needs " + ", ".join(missing))


def sh(args, cwd=None, input=None):
    p = subprocess.run(args, cwd=cwd, capture_output=True, input=input, timeout=120)
    if p.returncode != 0:
        raise AssertionError(f"{' '.join(map(str, args))}\n{p.stderr.decode()}{p.stdout.decode()}")
    return p.stdout.decode()


def tmp():
    return pathlib.Path(tempfile.mkdtemp(prefix="npadplug-"))


def eq(actual, expected):
    if actual != expected:
        raise AssertionError(f"\n--- expected ---\n{expected}\n--- actual ---\n{actual}")


def contains(actual, *needles):
    for n in needles:
        if n not in actual:
            raise AssertionError(f"missing {n!r} in:\n{actual}")


def fails_with(plugin, command, text, fragment, lang="Plain Text", file="Untitled"):
    rc, _, se = run(plugin, command, text, lang, file)
    if rc == 0:
        raise AssertionError("expected an error but it succeeded")
    contains(se, fragment)


# ---------------------------------------------------------------- catalog integrity
def test_catalog():
    cat = json.loads((PLUGINS / "catalog.json").read_text())["plugins"]
    ids = [p["id"] for p in cat]
    assert len(ids) == len(set(ids)), "duplicate ids"
    folders = sorted(p.parent.name for p in PLUGINS.glob("*/manifest.json"))
    eq(sorted(ids), folders)
    for p in cat:
        assert re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,63}", p["id"]), p["id"]
        script = (PLUGINS / p["id"] / "main.js").read_bytes()
        assert len(script) <= 256 * 1024
        eq(p["sha256"], hashlib.sha256(script).hexdigest())
        assert p["license"] and p["commands"], p["id"]
        assert p["downloadURL"].startswith("https://raw.githubusercontent.com/"), p["id"]


def test_every_manifest_command_exists():
    # Each declared command must be defined in the script: a missing one reports "does not define".
    for p in json.loads((PLUGINS / "catalog.json").read_text())["plugins"]:
        for c in p["commands"]:
            rc, _, se = run(p["id"], c["id"], "x", "Java", "Main.java")
            assert "does not define" not in se, f"{p['id']}.{c['id']} is declared but missing"


check("catalog: ids, checksums, licenses, URLs", test_catalog)
check("catalog: every declared command exists in its script", test_every_manifest_command_exists)

# ---------------------------------------------------------------- JSON Wrapper
SAMPLE = '''{
  "name": "Ada \\"The\\" Lovelace",
  "path": "C:\\\\temp\\\\x",
  "tab": "a\\tb",
  "emoji": "h\u00e9llo \U0001F600",
  "list": [1, 2.5, true, null],
  "nested": {"k": "it's $5 and `tick` ${x}"}
}'''
EDGES = {
    "scalar-ends-with-quote": '"he said \\"hi\\""',
    "triple-quotes": '{"q": "\\"\\"\\"x\\"\\"\\"", "r": "\\"\\"\\"\\""}',
    "sample": SAMPLE,
    "one-line": '{"a":1,"b":[1,2]}',
}


def wrapped(target_lang, text, file):
    return out("json-wrapper", "wrapJson", text, target_lang, file)


def run_python_wrapped(text):
    code = wrapped("Python", text, "t.py") + "\nimport sys\nsys.stdout.write(json_text)\n"
    return sh(["python3", "-c", code])


def run_java_wrapped(text):
    d = tmp()
    code = "public class T { public static void main(String[] a) {\n" + wrapped("Java", text, "T.java") + \
           "\nSystem.out.print(json);\n} }"
    (d / "T.java").write_text(code)
    sh(["javac", "-encoding", "UTF-8", "-d", str(d), str(d / "T.java")])
    return sh(["java", "-Dfile.encoding=UTF-8", "-Dstdout.encoding=UTF-8", "-cp", str(d), "T"])


def run_c_wrapped(compiler, lang, text, std):
    d = tmp()
    ext = "c" if lang == "C" else "cpp"
    head = "#include <stdio.h>\n" if lang == "C" else "#include <iostream>\n#include <string>\n"
    tail = "fputs(json, stdout);" if lang == "C" else "std::cout << json;"
    (d / f"t.{ext}").write_text(head + "int main(){\n" + wrapped(lang, text, f"t.{ext}") + f"\n{tail}\nreturn 0;}}\n")
    sh([compiler, *std, str(d / f"t.{ext}"), "-o", str(d / "t")])
    return sh([str(d / "t")])


def run_node_wrapped(text):
    return sh(["node", "-e", wrapped("JavaScript", text, "t.js") + "\nprocess.stdout.write(json);"])


def run_ruby_wrapped(text):
    return sh(["ruby", "-e", wrapped("Ruby", text, "t.rb") + "\nprint json"])


def run_shell_wrapped(text):
    return sh(["bash", "-c", wrapped("Shell", text, "t.sh") + '\nprintf %s "$json"'])


def run_swift_wrapped(text):
    d = tmp()
    (d / "main.swift").write_text(wrapped("Swift", text, "main.swift") + '\nprint(json, terminator: "")\n')
    sh(["swiftc", "-o", str(d / "t"), str(d / "main.swift")])
    return sh([str(d / "t")])


ROUND_TRIPS = [
    ("Python", ["python3"], run_python_wrapped),
    ("Java", ["javac", "java"], run_java_wrapped),
    ("C", ["cc"], lambda t: run_c_wrapped("cc", "C", t, ["-std=c11"])),
    ("C++", ["g++"], lambda t: run_c_wrapped("g++", "C++", t, ["-std=c++17"])),
    ("JavaScript", ["node"], run_node_wrapped),
    ("Ruby", ["ruby"], run_ruby_wrapped),
    ("Shell", ["bash"], run_shell_wrapped),
    ("Swift", ["swiftc"], run_swift_wrapped),
]
for lang, tools, runner in ROUND_TRIPS:
    for edge, text in EDGES.items():
        def t(runner=runner, text=text, tools=tools):
            need(*tools)
            eq(runner(text), text)  # the embedded string must equal the original JSON, byte for byte
        check(f"json-wrapper: {lang} round-trips '{edge}' through a real compiler/interpreter", t)

SMALL = '{"a": "x\\\\y"}'  # the JSON text {"a": "x\\y"}: a string holding one backslash
LITERALS = {  # no toolchain here, so assert the exact literal for a small input
    "C#": 'string json = @"{""a"": ""x\\\\y""}";',
    "Go": 'const jsonText = `{"a": "x\\\\y"}`',
    "Rust": 'const JSON: &str = r#"{"a": "x\\\\y"}"#;',
    "Kotlin": 'val json = """{"a": "x\\\\y"}"""',
    "PHP": "$json = <<<'JSON'\n{\"a\": \"x\\\\y\"}\nJSON;",
}
for lang, expected in LITERALS.items():
    check(f"json-wrapper: {lang} literal", lambda lang=lang, expected=expected: eq(wrapped(lang, SMALL, "t"), expected))
check("json-wrapper: Go backtick is spliced", lambda: eq(out("json-wrapper", "as_go", '"a`b"'), 'const jsonText = `"a` + "`" + `b"`'))
check("json-wrapper: Rust raises # count for \"# in content",
      lambda: contains(out("json-wrapper", "as_rust", '"a\\"#b"'), 'r##"'))
check("json-wrapper: C multi-line uses adjacent literals",
      lambda: eq(out("json-wrapper", "as_c", '{\n  "a": 1\n}'), 'const char *json =\n    "{\\n"\n    "  \\"a\\": 1\\n"\n    "}";'))


def test_json_autodetect_and_errors():
    contains(out("json-wrapper", "wrapJson", '{"a":1}', "Java", "X.java"), 'String json = """')
    contains(out("json-wrapper", "wrapJson", '{"a":1}', "C++", "x.cpp"), 'R"json(')
    contains(out("json-wrapper", "wrapJson", '{"a":1}', "TypeScript", "x.ts"), "const json = `")
    contains(out("json-wrapper", "wrapJson", '{"a":1}', "Plain Text", "script.py"), 'json_text = """')  # falls back to extension
    fails_with("json-wrapper", "wrapJson", '{"a":1}', "Can't tell which language", "JSON", "data.json")
    fails_with("json-wrapper", "wrapJson", '{"a":', "not valid JSON", "Java", "X.java")
    fails_with("json-wrapper", "as_python", "not json", "not valid JSON")
    contains(out("json-wrapper", "as_python", '{"a":1}', "JSON", "data.json"), 'json_text = """')  # explicit target works in a .json file


check("json-wrapper: language auto-detect, extension fallback, errors", test_json_autodetect_and_errors)


def test_json_minified():
    need("python3")
    code = out("json-wrapper", "wrapJsonMinified", SAMPLE, "Python", "t.py") + "\nimport sys\nsys.stdout.write(json_text)"
    eq(sh(["python3", "-c", code]), json.dumps(json.loads(SAMPLE), ensure_ascii=False, separators=(",", ":")))
    assert "\n" not in out("json-wrapper", "wrapJsonMinified", SAMPLE, "C", "t.c")


check("json-wrapper: minified variant compacts before wrapping", test_json_minified)

# ---------------------------------------------------------------- Java
def java_compile_run(src, cls):
    d = tmp()
    (d / f"{cls}.java").write_text(src)
    sh(["javac", "-d", str(d), str(d / f"{cls}.java")])
    return d


def t_java_main():
    need("javac", "java")
    r = out("java-tools", "wrapMain", '    System.out.println("hi");\n    int x = 2;\n    System.out.println(x);', "Java", "Hello.java")
    contains(r, "public class Hello")
    d = java_compile_run(r, "Hello")
    eq(sh(["java", "-cp", str(d), "Hello"]), "hi\n2\n")
    r2 = out("java-tools", "wrapMain", 'System.out.println("x");', "Plain Text", "Untitled")
    contains(r2, "public class Main")
    java_compile_run(r2, "Main")


def t_java_try():
    need("javac", "java")
    body = '        int[] a = new int[1];\n        a[3] = 1;'
    r = out("java-tools", "wrapTryCatch", body, "Java", "T.java")
    assert r.startswith("        try {"), r  # keeps the original indentation
    src = "public class T { public static void main(String[] x) {\n" + r + "\n System.out.println(\"after\"); } }"
    d = java_compile_run(src, "T")
    eq(sh(["java", "-cp", str(d), "T"]), "after\n")


def t_java_getters():
    need("javac")
    fields = "    private String name;\n    private final int id = 1;\n    private boolean active;\n    private List<String> tags;"
    r = out("java-tools", "gettersSetters", fields, "Java", "Person.java")
    contains(r, "public String getName()", "public void setName(String name)", "public int getId()",
             "public boolean isActive()", "public void setActive(boolean active)", "public List<String> getTags()")
    assert "setId" not in r, "final field must not get a setter"
    java_compile_run("import java.util.List;\npublic class Person {\n" + r + "\n}", "Person")
    fails_with("java-tools", "gettersSetters", "System.out.println(1);", "No field declarations", "Java", "P.java")


def t_java_record():
    need("javac")
    r = out("java-tools", "record", "private String name;\nprivate int age;\nprivate List<String> tags;", "Java", "person-info.java")
    eq(r, "public record PersonInfo(String name, int age, List<String> tags) {}")
    java_compile_run("import java.util.List;\n" + r, "PersonInfo")


check("java-tools: wrapMain compiles and runs (class named after file)", t_java_main)
check("java-tools: wrapTryCatch keeps indentation and compiles", t_java_try)
check("java-tools: getters/setters (boolean isX, final has no setter) compile", t_java_getters)
check("java-tools: record from fields compiles", t_java_record)

# ---------------------------------------------------------------- Python
def t_py_main():
    need("python3")
    r = out("python-tools", "wrapMain", '    print("hi")\n    print(1+1)', "Python", "a.py")
    eq(r, 'def main():\n    print("hi")\n    print(1+1)\n\n\nif __name__ == "__main__":\n    main()')
    eq(sh(["python3", "-c", r]), "hi\n2\n")
    contains(out("python-tools", "wrapMain", "", "Python", "a.py"), "    pass")


def t_py_try():
    need("python3")
    r = out("python-tools", "wrapTryExcept", "        1/0", "Python", "a.py")
    assert r.startswith("        try:"), r
    eq(sh(["python3", "-c", "def f():\n    if True:\n" + r + "\nf()"]), "Error: division by zero\n")


def t_py_func():
    need("python3")
    r = out("python-tools", "wrapFunction", 'print("called")', "Python", "a.py")
    eq(sh(["python3", "-c", r + "\nmy_function()"]), "called\n")


def t_py_dataclass():
    need("python3")
    r = out("python-tools", "dataclass", "name: str\nage: int = 3\n# comment\ntags: list = None", "Python", "user-profile.py")
    contains(r, "@dataclass", "class UserProfile:")
    eq(sh(["python3", "-c", r + '\nprint(UserProfile("a"))']), "UserProfile(name='a', age=3, tags=None)\n")
    fails_with("python-tools", "dataclass", "print(1)", "Expected lines like", "Python", "a.py")


check("python-tools: wrapMain runs with __main__ guard", t_py_main)
check("python-tools: wrapTryExcept keeps indentation and catches", t_py_try)
check("python-tools: wrapFunction is callable", t_py_func)
check("python-tools: dataclass works, bad input rejected", t_py_dataclass)

# ---------------------------------------------------------------- C
def t_c_main():
    need("cc")
    r = out("c-tools", "wrapMain", '    printf("hi\\n");', "C", "m.c")
    d = tmp()
    (d / "m.c").write_text(r)
    sh(["cc", "-Wall", "-Werror", str(d / "m.c"), "-o", str(d / "m")])
    eq(sh([str(d / "m")]), "hi\n")


def t_c_guard():
    need("cc")
    r = out("c-tools", "includeGuard", "typedef struct { int a; } Foo;\nint f(void);", "C", "my-header.h")
    contains(r, "#ifndef MY_HEADER_H", "#define MY_HEADER_H", "#endif /* MY_HEADER_H */")
    d = tmp()
    (d / "my-header.h").write_text(r)
    (d / "m.c").write_text('#include "my-header.h"\n#include "my-header.h"\nint main(void){Foo x={1};return x.a-1;}\n')
    sh(["cc", "-Werror", "-c", str(d / "m.c"), "-o", str(d / "m.o")])  # double include only works with the guard
    contains(out("c-tools", "includeGuard", "int x;", "C", ""), "INCLUDE_GUARD_H")  # no file name
    contains(out("c-tools", "includeGuard", "int x;", "C", "new 1"), "#ifndef NEW_1_H")


def t_c_externc():
    need("cc", "g++")
    r = out("c-tools", "externC", "int add(int a, int b);", "C", "add.h")
    d = tmp()
    (d / "add.h").write_text(r)
    for cc, x in (("cc", "c"), ("g++", "c++")):
        sh([cc, "-fsyntax-only", "-x", x, str(d / "add.h")])
    contains(r, '#ifdef __cplusplus\nextern "C" {')


def t_c_struct():
    need("cc")
    r = out("c-tools", "structFromFields", "int x;\nint y;\nchar *name;\ndouble v[3];", "C", "point.c")
    contains(r, "typedef struct {", "} Point;")
    d = tmp()
    (d / "p.c").write_text(r + '\nint main(void){Point p={1,2,"n",{0}};return p.x+p.y-3;}\n')
    sh(["cc", "-Werror", str(d / "p.c"), "-o", str(d / "p")])
    sh([str(d / "p")])
    fails_with("c-tools", "structFromFields", "printf(1)", "Expected field declarations", "C", "p.c")


check("c-tools: wrapMain compiles with -Wall -Werror and runs", t_c_main)
check("c-tools: include guard prevents double-include errors", t_c_guard)
check("c-tools: extern \"C\" block compiles as C and C++", t_c_externc)
check("c-tools: typedef struct compiles and is usable", t_c_struct)

# ---------------------------------------------------------------- C++
def gpp(src, *flags):
    d = tmp()
    (d / "t.cpp").write_text(src)
    sh(["g++", "-std=c++17", "-Wall", "-Werror", str(d / "t.cpp"), "-o", str(d / "t"), *flags])
    return sh([str(d / "t")])


def t_cpp_main():
    need("g++")
    eq(gpp(out("cpp-tools", "wrapMain", '    std::cout << "hi" << std::endl;', "C++", "m.cpp")), "hi\n")


def t_cpp_try():
    need("g++")
    r = out("cpp-tools", "wrapTryCatch", '    throw std::runtime_error("boom");', "C++", "m.cpp")
    eq(gpp("#include <stdexcept>\n#include <iostream>\nint main() {\n" + r + "\n    std::cout << \"after\\n\";\n}"), "after\n")


def t_cpp_ns():
    need("g++")
    r = out("cpp-tools", "wrapNamespace", "inline int three() { return 3; }", "C++", "m.cpp")
    gpp(r + "\nint main() { return app::three() == 3 ? 0 : 1; }")


def t_cpp_class():
    need("g++")
    r = out("cpp-tools", "classFromFields", "int x;\nstd::string name;\ndouble *ptr;", "C++", "item.cpp")
    contains(r, "class Item {", "int getX() const", "std::string getName() const")
    eq(gpp("#include <string>\n#include <iostream>\n" + r + '\nint main(){ double d=2; Item i(5,"n",&d); std::cout << i.getX() << i.getName() << *i.getPtr(); }'), "5n2")
    fails_with("cpp-tools", "classFromFields", "foo(1);", "Expected member declarations", "C++", "i.cpp")


check("cpp-tools: wrapMain compiles (-Wall -Werror) and runs", t_cpp_main)
check("cpp-tools: wrapTryCatch catches std::exception", t_cpp_try)
check("cpp-tools: wrapNamespace compiles and resolves", t_cpp_ns)
check("cpp-tools: class from members compiles and getters work", t_cpp_class)

# ---------------------------------------------------------------- JavaScript / TypeScript
def node(code):
    return sh(["node", "-e", code])


def t_js_iife():
    need("node")
    r = out("javascript-tools", "wrapIife", 'console.log("iife");', "JavaScript", "a.js")
    contains(r, '"use strict"')
    eq(node(r), "iife\n")


def t_js_async():
    need("node")
    r = out("javascript-tools", "wrapAsyncMain", 'await Promise.resolve();\nconsole.log("async");', "JavaScript", "a.js")
    eq(node(r), "async\n")
    bad = out("javascript-tools", "wrapAsyncMain", 'throw new Error("x");', "TypeScript", "a.ts")
    p = subprocess.run(["node", "-e", bad], capture_output=True)
    assert p.returncode == 1, "errors should set a non-zero exit code"


def t_js_try():
    need("node")
    r = out("javascript-tools", "wrapTryCatch", '  null.x;', "JavaScript", "a.js")
    assert r.startswith("  try {"), r
    p = subprocess.run(["node", "-e", r + '\nconsole.log("ok")'], capture_output=True)
    assert p.returncode == 0 and p.stdout.decode() == "ok\n", p.stderr.decode()


def t_js_dom():
    need("node")
    r = out("javascript-tools", "wrapDomReady", 'init();', "JavaScript", "a.js")
    sh(["node", "--check", "/dev/stdin"], input=r.encode())
    contains(r, 'document.addEventListener("DOMContentLoaded", () => {')


check("javascript-tools: wrapIife runs in strict mode", t_js_iife)
check("javascript-tools: wrapAsyncMain awaits and sets exit code on error", t_js_async)
check("javascript-tools: wrapTryCatch swallows the error and keeps indent", t_js_try)
check("javascript-tools: wrapDomReady is valid JS", t_js_dom)

# ---------------------------------------------------------------- Go (no toolchain here: exact output)
check("go-tools: wrapMain", lambda: eq(out("go-tools", "wrapMain", '    fmt.Println("hi")\n    x := 1', "Go", "m.go"),
                                       'package main\n\nfunc main() {\n\tfmt.Println("hi")\n\tx := 1\n}'))
check("go-tools: wrapMain empty", lambda: eq(out("go-tools", "wrapMain", "", "Go", "m.go"), "package main\n\nfunc main() {\n}"))
check("go-tools: wrapFunc", lambda: eq(out("go-tools", "wrapFunc", "doThing()", "Go", "m.go"),
                                       "func myFunction() error {\n\tdoThing()\n\treturn nil\n}"))
check("go-tools: wrapGoroutine keeps indent", lambda: eq(out("go-tools", "wrapGoroutine", "\twork()", "Go", "m.go"),
                                                         "\tgo func() {\n\t\twork()\n\t}()"))
check("go-tools: struct from fields", lambda: eq(out("go-tools", "structFromFields", 'Name string\nTags []string\nAge int `json:"age"`', "Go", "user_profile.go"),
                                                 'type UserProfile struct {\n\tName string\n\tTags []string\n\tAge int `json:"age"`\n}'))
check("go-tools: struct rejects non-fields", lambda: fails_with("go-tools", "structFromFields", "fmt.Println(x)", "Expected lines like", "Go", "a.go"))

# ---------------------------------------------------------------- Comment Wrapper
COMMENT_LANGS = ["Java", "C", "C++", "C#", "JavaScript", "TypeScript", "Go", "Rust", "Swift", "Kotlin", "PHP", "Python", "Ruby", "Shell",
                 "Perl", "YAML", "SQL", "Lua", "Haskell", "Lisp", "INI", "LaTeX", "VB"]
CODE = "int a = 1;\n    if (a) {\n        a++;\n    }\n\n    return a;"


def t_comment_roundtrip():
    for lang in COMMENT_LANGS:
        c = out("comment-wrapper", "commentLines", CODE, lang, "x")
        for line in c.split("\n"):
            assert not line.strip() or re.match(r"^\s*(//|#|--|;|%|')", line), (lang, line)
        eq(out("comment-wrapper", "uncommentLines", c, lang, "x"), CODE)


def t_comment_runs():
    for lang, tools, ext, runner in [
        ("Python", ["python3"], "py", lambda f: sh(["python3", f])),
        ("Ruby", ["ruby"], "rb", lambda f: sh(["ruby", f])),
        ("Shell", ["bash"], "sh", lambda f: sh(["bash", f])),
        ("JavaScript", ["node"], "js", lambda f: sh(["node", f])),
    ]:
        if not all(TOOLS[t] for t in tools):
            continue
        prints = {"Python": 'print("%s")', "Ruby": 'puts "%s"', "Shell": 'echo %s', "JavaScript": 'console.log("%s")'}[lang]
        d = tmp()
        commented = out("comment-wrapper", "commentLines", prints % "B", lang, "x." + ext)
        (d / f"t.{ext}").write_text(prints % "A" + "\n" + commented + "\n")
        eq(runner(str(d / f"t.{ext}")), "A\n")


def t_comment_java_c():
    need("javac", "cc")
    d = tmp()
    c = out("comment-wrapper", "commentLines", 'System.out.println("B");', "Java", "T.java")
    b = out("comment-wrapper", "blockComment", 'System.out.println("C");', "Java", "T.java")
    (d / "T.java").write_text('public class T { public static void main(String[] a) {\nSystem.out.println("A");\n' + c + "\n" + b + "\n} }")
    sh(["javac", "-d", str(d), str(d / "T.java")])
    eq(sh(["java", "-cp", str(d), "T"]), "A\n")
    cc = out("comment-wrapper", "commentLines", 'return 3;', "C", "m.c")
    (d / "m.c").write_text("int main(void){\n" + cc + "\n return 0; }\n")
    sh(["cc", str(d / "m.c"), "-o", str(d / "m")])
    sh([str(d / "m")])


def t_comment_block_doc():
    eq(out("comment-wrapper", "blockComment", "a\nb", "C", "x.c"), "/*\na\nb\n*/")
    eq(out("comment-wrapper", "blockComment", "a", "HTML", "x.html"), "<!--\na\n-->")
    eq(out("comment-wrapper", "blockComment", "a", "Ruby", "x.rb"), "=begin\na\n=end")
    eq(out("comment-wrapper", "blockComment", "a", "Lua", "x.lua"), "--[[\na\n]]")
    eq(out("comment-wrapper", "blockComment", "a", "Haskell", "x.hs"), "{-\na\n-}")
    fails_with("comment-wrapper", "blockComment", "a", "no block comment", "Python", "x.py")
    eq(out("comment-wrapper", "docComment", "Adds.\n\n@param a x", "Java", "A.java"), "/**\n * Adds.\n *\n * @param a x\n */")
    eq(out("comment-wrapper", "docComment", "Adds.", "Python", "a.py"), '"""Adds."""')
    eq(out("comment-wrapper", "docComment", "Adds.", "Rust", "a.rs"), "/// Adds.")
    eq(out("comment-wrapper", "docComment", "Adds.", "Go", "a.go"), "// Adds.")
    if TOOLS["javac"]:
        d = tmp()
        doc = out("comment-wrapper", "docComment", "Adds two numbers.\n\n@param a first", "Java", "T.java")
        (d / "T.java").write_text("public class T {\n" + doc + "\n static int f(int a){return a;} }")
        sh(["javac", "-d", str(d), str(d / "T.java")])
    if TOOLS["python3"]:
        sh(["python3", "-c", out("comment-wrapper", "docComment", "line one\nline two", "Python", "a.py") + "\nx = 1"])


def t_comment_detect():
    eq(out("comment-wrapper", "commentLines", "x = 1", "Plain Text", "a.py"), "# x = 1")  # extension fallback
    fails_with("comment-wrapper", "commentLines", "x", "Can't tell which language", "Plain Text", "notes.txt")
    fails_with("comment-wrapper", "commentLines", "x", "no single-line comment marker", "HTML", "a.html")


check("comment-wrapper: comment/uncomment round-trips in 23 languages", t_comment_roundtrip)
check("comment-wrapper: commented-out lines really don't run (py/rb/sh/js)", t_comment_runs)
check("comment-wrapper: Java and C still compile with commented code", t_comment_java_c)
check("comment-wrapper: block and doc comments (and they compile)", t_comment_block_doc)
check("comment-wrapper: language detection and errors", t_comment_detect)

# ---------------------------------------------------------------- Existing starter plugins
def t_text_case():
    eq(out("text-case", "upper", "hello"), "HELLO")
    eq(out("text-case", "lower", "HeLLo"), "hello")
    eq(out("text-case", "title", "hello big WORLD"), "Hello Big World")
    eq(out("text-case", "camel", "foo_bar baz-Qux\nsome thing"), "fooBarBazQux\nsomeThing")
    eq(out("text-case", "snake", "fooBar Baz"), "foo_bar_baz")
    eq(out("text-case", "kebab", "fooBar Baz"), "foo-bar-baz")


def t_web_codec():
    eq(out("web-codec", "urlEncode", "a b&c/é"), "a%20b%26c%2F%C3%A9")
    eq(out("web-codec", "urlDecode", "a%20b%26c+d"), "a b&c d")
    fails_with("web-codec", "urlDecode", "%E0%A4%A", "")
    eq(out("web-codec", "htmlEscape", "<a href=\"x\">'&'</a>"), "&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;")
    eq(out("web-codec", "htmlUnescape", "&lt;b&gt; &amp;amp; &#39;x&#39; &#x1F600; &unknown;"), "<b> &amp; 'x' \U0001F600 &unknown;")


def t_whitespace():
    eq(out("whitespace-cleaner", "trimTrailing", "a  \n\tb\t \nc"), "a\n\tb\nc")
    eq(out("whitespace-cleaner", "trimBoth", "  a  \n\tb\t"), "a\nb")
    eq(out("whitespace-cleaner", "removeBlankLines", "a\n\n  \nb"), "a\nb")
    eq(out("whitespace-cleaner", "collapseBlankLines", "a\n\n\n\nb\n\nc"), "a\n\nb\n\nc")
    eq(out("whitespace-cleaner", "tabsToSpaces", "\ta\tb"), "    a    b")


check("text-case: all six conversions", t_text_case)
check("web-codec: URL and HTML encode/decode", t_web_codec)
check("whitespace-cleaner: all five commands", t_whitespace)

# ---------------------------------------------------------------- summary
print(f"\n{passed} passed, {len(failed)} failed, {len(skipped)} skipped (no toolchain)")
for name in failed:
    print("  FAILED:", name)
print("Toolchains:", ", ".join(f"{t}={'yes' if p else 'no'}" for t, p in TOOLS.items()))
sys.exit(1 if failed else 0)
