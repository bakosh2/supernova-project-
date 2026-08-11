import Foundation

struct AgentEvent {
    let type: String
    let text: String?
    let message: String?
}

/// Native Swift client for the Python AI Agent's /ws contract.
/// iPad Simulator: ws://127.0.0.1:8000/ws
/// Physical iPad: replace 127.0.0.1 with the Mac's local network IP.
final class AgentWebSocketService: NSObject {
    // Change this one value when testing on a physical iPad.
    private let endpoint = URL(string: "ws://127.0.0.1:8000/ws")!
    private var task: URLSessionWebSocketTask?
    private var sessionID: String?
    var onEvent: ((AgentEvent) -> Void)?

    func connect() {
        guard task == nil else { return }
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        let socket = session.webSocketTask(with: endpoint)
        task = socket
        socket.resume()
        receive()
    }

    func send(_ text: String) {
        connect()
        let payload: [String: String] = ["type": "message", "text": text]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let raw = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(raw)) { [weak self] error in
            if error != nil { self?.onEvent?(AgentEvent(type: "error", text: nil, message: "تعذر إرسال الرسالة إلى المساعد.")) }
        }
    }

    private func receive() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let raw) = message { self.parse(raw) }
                self.receive()
            case .failure:
                self.task = nil
                self.onEvent?(AgentEvent(type: "disconnected", text: nil, message: nil))
            }
        }
    }

    private func parse(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = object["type"] as? String else { return }
        if type == "session" { sessionID = object["session_id"] as? String }
        onEvent?(AgentEvent(type: type, text: object["text"] as? String, message: object["message"] as? String))
    }
}

extension AgentWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        onEvent?(AgentEvent(type: "session", text: nil, message: nil))
    }
}
