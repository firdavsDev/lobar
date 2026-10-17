import Foundation

/// Tiny LAN protocol between two Lobars (Bonjour `_lobar._tcp`).
struct PeerMessage: Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable { case hello, gossip, bye }
    var from: String
    var text: String
    var kind: Kind

    func encoded() throws -> Data {
        var d = try JSONEncoder().encode(self); d.append(0x0A); return d   // newline-delimited
    }
    static func decode(_ data: Data) throws -> PeerMessage {
        var d = data; if d.last == 0x0A { d.removeLast() }
        return try JSONDecoder().decode(PeerMessage.self, from: d)
    }
}
