import XCTest

final class WidgetJavaTests: XCTestCase {
    func testRunWidgetScriptProducesOutput() {
        let bundle = Bundle(for: WidgetJavaTests.self)
        let result = ShellRunner.runWidgetScript(bundle: bundle)
        XCTAssertEqual(result.terminationStatus, 0, "widget.sh should exit with status 0, stderr: \(result.stderr)")
        XCTAssertTrue(result.stdout.contains("WidgetJava"), "Expected stdout to contain 'WidgetJava', got: \(result.stdout)")
    }

    func testExtractBase64PNG() {
        // 1x1 transparent PNG in base64
        let onePixelPNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let sampleHTML = "<img src=\"data:image/png;base64,\(onePixelPNG)\" />"
        let image = ShellRunner.extractBase64PNG(from: sampleHTML)
        XCTAssertNotNil(image, "Should decode valid base64 PNG from HTML output")
        XCTAssertEqual(image?.size.width, 1)
        XCTAssertEqual(image?.size.height, 1)
    }
}
