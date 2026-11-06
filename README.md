# WidgetJava

A macOS WidgetKit sample project written in Swift that executes a bundled shell script (`widget.sh`), modeled after `../QLJava`.

## Architecture

- **`WidgetJava` (`WidgetJava.appex`)**: macOS WidgetKit extension written in Swift (`WidgetJava/WidgetJava.swift`).
  - Uses `WidgetJavaProvider` (`TimelineProvider`) to run `widget.sh` via `ShellRunner` (`Process` + `Pipe` + `DispatchGroup`) and display either terminal-styled text output or inline `data:image/png;base64,...` images.
  - Configured with `WidgetJava/WidgetJava.entitlements` (App Sandbox + temporary SBPL exceptions for `process-exec` / `process-fork`) just like `../QLJava`.
  - Logs execution details to `/tmp/widgetjava.log`.
- **`WidgetJavaApp` (`WidgetJavaApp.app`)**: Host macOS application (`WidgetJava/WidgetJavaApp/WidgetJavaApp.swift`) that embeds `WidgetJava.appex`, provides a live preview of `widget.sh`, and triggers `WidgetCenter.shared.reloadAllTimelines()`.
- **`WidgetJava/widget.sh`**: Bundled shell script executed by the widget extension.

## Build & Run

```bash
xcodebuild -project WidgetJava.xcodeproj -scheme WidgetJava build
```

After running `WidgetJavaApp.app` once to register the extension with macOS, open **Notification Center -> Edit Widgets** (or right-click Desktop -> **Edit Widgets**) and add **WidgetJava**.
