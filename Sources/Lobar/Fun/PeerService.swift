import Foundation
import Network

/// Bonjour-based hello between Lobars on the same LAN.
@MainActor
final class PeerService {
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connections: [NWConnection] = []
    private var greeted: [String: Date] = [:]
    private let name: () -> String
    var onPeerHello: ((String, String) -> Void)?     // peer name, text
    private let serviceType = "_lobar._tcp"
    private let id = UUID().uuidString.prefix(6)

    init(name: @escaping () -> String) { self.name = name }

    func start() {
        stop()
        do {
            let l = try NWListener(using: .tcp)
            l.service = NWListener.Service(name: "Lobar-\(id)", type: serviceType)
            l.newConnectionHandler = { [weak self] c in
                c.start(queue: .main)
                Task { @MainActor in self?.receive(on: c) }
            }
            l.start(queue: .main)
            listener = l
        } catch { Log.app.error("peer listener failed: \(error.localizedDescription)") }

        let b = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: .tcp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                guard let self else { return }
                for r in results {
                    if case let .service(sname, _, _, _) = r.endpoint, sname == "Lobar-\(self.id)" { continue }
                    self.greet(r.endpoint)
                }
            }
        }
        b.start(queue: .main)
        browser = b
    }

    func stop() {
        listener?.cancel(); listener = nil
        browser?.cancel(); browser = nil
        connections.forEach { $0.cancel() }; connections.removeAll()
    }

    private func greet(_ endpoint: NWEndpoint) {
        let key = "\(endpoint)"
        if let last = greeted[key], Date().timeIntervalSince(last) < 3600 { return }
        greeted[key] = Date()
        let c = NWConnection(to: endpoint, using: .tcp)
        connections.append(c)
        let payload = try? PeerMessage(from: name(), text: "Salom! Sening odaming ham ishlayaptimi?", kind: .hello).encoded()
        c.stateUpdateHandler = { [weak c] state in
            guard case .ready = state, let c, let payload else { return }
            c.send(content: payload, completion: .contentProcessed { _ in c.cancel() })
        }
        c.start(queue: .main)
    }

    private func receive(on c: NWConnection) {
        c.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            Task { @MainActor in
                guard let self, let data, let msg = try? PeerMessage.decode(data) else { c.cancel(); return }
                self.onPeerHello?(msg.from, msg.text)
                c.cancel()
            }
        }
    }
}
