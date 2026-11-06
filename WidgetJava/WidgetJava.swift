import WidgetKit
import SwiftUI
import AppKit

struct WidgetJavaEntry: TimelineEntry {
    let date: Date
    let output: String
    let errorOutput: String
    let image: NSImage?
}

struct WidgetJavaProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetJavaEntry {
        WidgetJavaEntry(
            date: Date(),
            output: "=== WidgetJava ===\nLoading shell script output...",
            errorOutput: "",
            image: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetJavaEntry) -> Void) {
        if context.isPreview {
            let result = ShellRunner.runWidgetScript()
            let entry = WidgetJavaEntry(
                date: Date(),
                output: result.stdout.isEmpty ? "=== WidgetJava ===\nPreview Ready" : result.stdout,
                errorOutput: result.stderr,
                image: result.image
            )
            completion(entry)
        } else {
            let result = ShellRunner.runWidgetScript()
            let entry = WidgetJavaEntry(
                date: Date(),
                output: result.stdout,
                errorOutput: result.stderr,
                image: result.image
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetJavaEntry>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let currentDate = Date()
            let result = ShellRunner.runWidgetScript()
            let entry = WidgetJavaEntry(
                date: currentDate,
                output: result.stdout,
                errorOutput: result.stderr,
                image: result.image
            )

            // Refresh timeline every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)
                ?? currentDate.addingTimeInterval(900)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct WidgetJavaEntryView: View {
    var entry: WidgetJavaProvider.Entry

    private let terminalGreen = Color(red: 0x66 / 255.0, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let nsImage = entry.image {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(displayText)
                    .font(.custom("Monaco", size: 11))
                    .foregroundStyle(entry.output.isEmpty && !entry.errorOutput.isEmpty ? Color.red : terminalGreen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(10)
        .containerBackground(for: .widget) {
            Color.black
        }
    }

    private var displayText: String {
        if !entry.output.isEmpty {
            return entry.output
        } else if !entry.errorOutput.isEmpty {
            return "Error:\n\(entry.errorOutput)"
        } else {
            return "(no output from widget.sh)"
        }
    }
}

@main
struct WidgetJavaBundle: WidgetBundle {
    init() {
        logToFile("WidgetJavaBundle initialized in runtime!")
    }

    var body: some Widget {
        WidgetJavaWidget()
    }
}

struct WidgetJavaWidget: Widget {
    let kind: String = "com.vavi.WidgetJava.Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetJavaProvider()) { entry in
            WidgetJavaEntryView(entry: entry)
        }
        .configurationDisplayName("WidgetJava")
        .description("Executes bundled widget.sh shell script and displays output.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
