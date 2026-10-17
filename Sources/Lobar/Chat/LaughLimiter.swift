import Foundation

/// Keeps "hihi / ha-ha" from appearing in every line: after one laugh, strips laughs from the next 3 lines.
struct LaughLimiter: Sendable {
    private var linesSinceLaugh = 99
    static let cooldownLines = 3
    private static let laughPattern = #"(?i)\b(hi-?hi+|ha-?ha+|he-?he+|xi-?xi+)\b[!.,]?\s*"#

    mutating func filter(_ text: String) -> String {
        let hasLaugh = text.range(of: Self.laughPattern, options: .regularExpression) != nil
        guard hasLaugh else { linesSinceLaugh += 1; return text }
        if linesSinceLaugh >= Self.cooldownLines {
            linesSinceLaugh = 0
            return text
        }
        linesSinceLaugh += 1
        return Self.strip(text)
    }

    static func strip(_ text: String) -> String {
        var s = text.replacingOccurrences(of: laughPattern, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+([,.!?])"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^[,.\s]+"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[,\s]+$"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"([.!?])\s*,"#, with: "$1", options: .regularExpression)
        // capitalize first letter and letters that now follow sentence punctuation
        if let f = s.first { s = String(f).uppercased() + s.dropFirst() }
        if let re = try? NSRegularExpression(pattern: #"([.!?]\s+)(\p{Ll})"#) {
            let ns = NSMutableString(string: s)
            for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)).reversed() {
                let r = m.range(at: 2)
                ns.replaceCharacters(in: r, with: ns.substring(with: r).uppercased())
            }
            s = ns as String
        }
        return s
    }
}
