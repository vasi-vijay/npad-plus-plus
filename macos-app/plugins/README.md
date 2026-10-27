# NPad++ community plugins

Plugins are small, open-source JavaScript files that run in a sandbox (Apple's JavaScriptCore). They get the selected
text (or the whole document) as a string and return a string. They have no access to files, the network or other apps.

```js
// main.js
commands.upper = function (text, ctx) { return text.toUpperCase(); };
```

`ctx` describes the document: `{ language: "Java", fileName: "Main.java", extension: "java" }`, so a plugin can adapt to the
language being edited (see `json-wrapper` and `comment-wrapper`). Throw an `Error` to show a message to the user.

Each plugin folder holds `manifest.json` (id, name, version, license, commands…) and `main.js` (max 256 KB).

## Adding or updating a plugin

1. Create `<id>/manifest.json` and `<id>/main.js` (ids: lowercase letters, digits, `-`, `_`). Bump `version` when updating.
2. Run `./build_catalog.py` to regenerate `catalog.json` with the SHA-256 of each script.
3. Merge to `main`. NPad++ loads the catalog from
   `https://raw.githubusercontent.com/vasi-vijay/npad-plus-plus/main/macos-app/plugins/catalog.json`
   and refuses any download whose checksum doesn't match.

To test locally, point the app at a local catalog (`file://` downloads are accepted only from a `file://` catalog):

```sh
./build_catalog.py "file://$PWD"
defaults write <bundle-id> npad.plugins.catalogURL "file://$PWD/catalog.json"
```

## Testing

`tests/test_plugins.py` runs every plugin through the app's own `JSPluginRunner`, and where a toolchain is installed
(javac, cc, g++, node, python3, ruby, bash, swiftc) it compiles or runs the generated code to prove it is valid.
It also checks the catalog (ids, licenses, URLs, SHA-256 of every script).

```sh
tests/build_runner.sh && tests/test_plugins.py
```
