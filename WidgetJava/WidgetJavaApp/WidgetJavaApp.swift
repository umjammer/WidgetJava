import Cocoa
import Combine
import SwiftUI
import WidgetKit

final class ScriptPreviewModel: ObservableObject {
    @Published var scriptOutput: String = ""
    @Published var scriptError: String = ""
    @Published var decodedImage: NSImage?

    func runScriptPreview() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ShellRunner.runWidgetScript()
            DispatchQueue.main.async {
                self.scriptOutput = result.stdout
                self.scriptError = result.stderr
                self.decodedImage = result.image
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: ScriptPreviewModel

    private let terminalGreen = Color(red: 0x66 / 255.0, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: 16) {
            Text("WidgetJava Extension is now installed.")
                .font(.headline)

            Text("You can add the widget via Notification Center -> Edit Widgets -> WidgetJava,\nor right-click the Desktop -> Edit Widgets.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            GroupBox(label: Text("widget.sh Preview Output").font(.caption)) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if let image = model.decodedImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 160)
                        }
                        if !model.scriptOutput.isEmpty {
                            Text(model.scriptOutput)
                                .font(.custom("Monaco", size: 12))
                                .foregroundStyle(terminalGreen)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !model.scriptError.isEmpty {
                            Text(model.scriptError)
                                .font(.custom("Monaco", size: 11))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            HStack(spacing: 12) {
                Button("Run widget.sh") {
                    model.runScriptPreview()
                }
                Button("Reload Widget Timeline") {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 320)
        .onAppear {
            model.runScriptPreview()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let previewModel = ScriptPreviewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 520, height: 360)
        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WidgetJava Manager"
        window.center()
        window.contentView = NSHostingView(rootView: ContentView(model: previewModel))
        window.makeKeyAndOrderFront(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct WidgetJavaAppMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
