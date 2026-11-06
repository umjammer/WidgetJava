import Foundation
import AppKit

/// Logs diagnostic messages to `/tmp/widgetjava.log`, mirroring `LogToFile` in `../QLJava`.
public func logToFile(_ message: String) {
    let logPath = "/tmp/widgetjava.log"
    let logLine = "\(Date()): \(message)\n"
    guard let data = logLine.data(using: .utf8) else { return }

    if !FileManager.default.fileExists(atPath: logPath) {
        FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
    }

    guard let fileHandle = FileHandle(forWritingAtPath: logPath) else { return }
    defer {
        try? fileHandle.close()
    }
    do {
        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: data)
    } catch {
        NSLog("Failed to write to log file: %@", "\(error)")
    }
}

public struct ShellResult {
    public let stdout: String
    public let stderr: String
    public let terminationStatus: Int32
    public let image: NSImage?
}

public enum ShellRunner {
    /// Executes the bundled `widget.sh` script using `/bin/sh` and captures stdout/stderr,
    /// following the same pattern as `PreviewProvider.m` in `../QLJava`.
    public static func runWidgetScript(arguments: [String] = [], bundle: Bundle = .main) -> ShellResult {
        logToFile("--- WidgetJava Script Request Started ---")

        let resolvedBundle: Bundle
        if bundle.path(forResource: "widget", ofType: "sh") != nil {
            resolvedBundle = bundle
        } else {
            resolvedBundle = Bundle(for: BundleToken.self)
        }

        guard let shPath = resolvedBundle.path(forResource: "widget", ofType: "sh") else {
            let resourcePath = resolvedBundle.resourcePath ?? "unknown"
            logToFile("Error: widget.sh not found in bundle: \(resourcePath)")
            return ShellResult(
                stdout: "",
                stderr: "widget.sh script not found in resources bundle (\(resourcePath)).",
                terminationStatus: -1,
                image: nil
            )
        }

        return runScript(atPath: shPath, resourcePath: resolvedBundle.resourcePath ?? "", extraArguments: arguments)
    }

    /// Executes an arbitrary shell script at `shPath` via `/bin/sh`.
    public static func runScript(atPath shPath: String, resourcePath: String = "", extraArguments: [String] = []) -> ShellResult {
        logToFile("Script path: \(shPath)")
        logToFile("Bundle resource path: \(resourcePath)")

        let pipe = Pipe()
        let errPipe = Pipe()

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        var taskArgs = [shPath]
        taskArgs.append(contentsOf: extraArguments)
        if !resourcePath.isEmpty {
            taskArgs.append(resourcePath)
        }
        task.arguments = taskArgs
        task.standardOutput = pipe
        task.standardError = errPipe

        do {
            try task.run()
        } catch {
            logToFile("Failed to launch task: \(error)")
            return ShellResult(
                stdout: "",
                stderr: "Failed to launch task: \(error.localizedDescription)",
                terminationStatus: -1,
                image: nil
            )
        }

        var outData = Data()
        var errData = Data()
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global(qos: .default).async {
            if let data = try? pipe.fileHandleForReading.readToEnd() {
                outData = data
            }
            group.leave()
        }

        group.enter()
        DispatchQueue.global(qos: .default).async {
            if let data = try? errPipe.fileHandleForReading.readToEnd() {
                errData = data
            }
            group.leave()
        }

        task.waitUntilExit()
        group.wait()

        try? pipe.fileHandleForReading.close()
        try? errPipe.fileHandleForReading.close()

        let outStr = String(data: outData, encoding: .utf8) ?? ""
        let errStr = String(data: errData, encoding: .utf8) ?? ""

        if !errStr.isEmpty {
            logToFile("Task stderr:\n\(errStr)")
        }
        if !outStr.isEmpty {
            logToFile("Task stdout:\n\(outStr)")
        }

        let decodedImage = extractBase64PNG(from: outStr)
        if let decodedImage = decodedImage {
            logToFile(String(format: "Output identified as native PNG image (size: %.0fx%.0f)", decodedImage.size.width, decodedImage.size.height))
        }

        logToFile("--- WidgetJava Script Request Finished (status: \(task.terminationStatus)) ---")

        return ShellResult(
            stdout: outStr.trimmingCharacters(in: .whitespacesAndNewlines),
            stderr: errStr.trimmingCharacters(in: .whitespacesAndNewlines),
            terminationStatus: task.terminationStatus,
            image: decodedImage
        )
    }

    /// Parses an inline `data:image/png;base64,...` image from stdout, matching `../QLJava`.
    public static func extractBase64PNG(from output: String) -> NSImage? {
        let marker = "data:image/png;base64,"
        guard let markerRange = output.range(of: marker) else {
            return nil
        }
        let remainder = output[markerRange.upperBound...]
        let base64Substring: Substring
        if let quoteIndex = remainder.firstIndex(of: "\"") {
            base64Substring = remainder[..<quoteIndex]
        } else if let newlineIndex = remainder.firstIndex(where: { $0.isNewline }) {
            base64Substring = remainder[..<newlineIndex]
        } else {
            base64Substring = remainder
        }
        let cleaned = base64Substring.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              let pngData = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters),
              !pngData.isEmpty else {
            return nil
        }
        return NSImage(data: pngData)
    }
}

private final class BundleToken {}
