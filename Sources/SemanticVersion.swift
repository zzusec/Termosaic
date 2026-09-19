import Foundation

struct SemanticVersion: Comparable, CustomStringConvertible, Sendable {
    let components: [Int]

    init?(_ rawValue: String) {
        var normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.lowercased().hasPrefix("v") { normalized.removeFirst() }
        normalized = String(normalized.split(separator: "-", maxSplits: 1).first ?? "")
        let parts = normalized.split(separator: ".")
        guard !parts.isEmpty else { return nil }
        let numbers = parts.compactMap { Int($0) }
        guard numbers.count == parts.count else { return nil }
        components = numbers
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    var description: String {
        components.map(String.init).joined(separator: ".")
    }
}
