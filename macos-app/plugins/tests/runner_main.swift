import Foundation

// Usage: plugin-runner <plugin-folder> <command> <language> <fileName>   (text on stdin, result on stdout)
// Runs a plugin through the same JSPluginRunner the app uses.
let args = CommandLine.arguments
guard args.count == 5 else {
    FileHandle.standardError.write(Data("usage: plugin-runner <plugin-folder> <command> <language> <fileName>\n".utf8))
    exit(2)
}
let script = try String(contentsOfFile: args[1] + "/main.js", encoding: .utf8)
let input = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
let fileName = args[4]
let info = ["language": args[3], "fileName": fileName, "extension": (fileName as NSString).pathExtension.lowercased()]

switch JSPluginRunner.run(script: script, command: args[2], input: input, context: info) {
case .success(let text):
    FileHandle.standardOutput.write(Data(text.utf8))
case .failure(let error):
    FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
    exit(1)
}
