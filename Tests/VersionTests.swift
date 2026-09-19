import Foundation

@main
struct VersionTests {
    static func main() {
        expect(SemanticVersion("v1.2.0") == SemanticVersion("1.2.0"), "leading v should be ignored")
        expect(SemanticVersion("1.2.1")! > SemanticVersion("1.2.0")!, "patch updates should compare correctly")
        expect(SemanticVersion("1.10.0")! > SemanticVersion("1.9.9")!, "numeric components should not compare lexically")
        expect(SemanticVersion("2.0")! > SemanticVersion("1.99.99")!, "major updates should compare correctly")
        expect(SemanticVersion("1.2.0-beta") == SemanticVersion("1.2.0"), "prerelease suffix should be ignored after release filtering")
        print("SemanticVersion tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("FAIL: \(message)\n", stderr)
            exit(1)
        }
    }
}
