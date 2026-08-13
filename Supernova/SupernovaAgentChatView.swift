import SwiftUI
import Foundation
import Combine

// MARK: - Supernova agent connection

private struct SupernovaAgentEvent {
    let type: String
    let text: String?
    let message: String?
    let task: [String: Any]?
}

/// WebSocket client for the local Supernova FastAPI agent.
/// The simulator reaches the server at 127.0.0.1. For a physical iPad, replace
/// this host with the Mac's LAN address in one place below.
private final class SupernovaAgentSocket: NSObject, URLSessionWebSocketDelegate {
    private let endpoint = URL(string: "ws://127.0.0.1:8000/ws")!
    // نحتفظ بالجلسة طوال عمر المحادثة؛ لا تعتمد على جلسة مؤقتة قد تُغلق
    // بعد انقطاع التطبيق أو إعادة تشغيل الخادم.
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    private var socket: URLSessionWebSocketTask?
    var onEvent: ((SupernovaAgentEvent) -> Void)?

    func connect() {
        guard socket == nil else { return }
        let newSocket = session.webSocketTask(with: endpoint)
        socket = newSocket
        newSocket.resume()
        receive()
    }

    func send(_ text: String) {
        connect()
        let payload = ["type": "message", "text": text]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let raw = String(data: data, encoding: .utf8) else { return }
        socket?.send(.string(raw)) { [weak self] error in
            guard error != nil else { return }
            self?.onEvent?(SupernovaAgentEvent(type: "error", text: nil, message: "تعذر إرسال الرسالة إلى Supernova.", task: nil))
        }
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    private func receive() {
        socket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let raw) = message { self.parse(raw) }
                self.receive()
            case .failure:
                self.socket = nil
                self.onEvent?(SupernovaAgentEvent(type: "disconnected", text: nil, message: nil, task: nil))
            }
        }
    }

    private func parse(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = object["type"] as? String else { return }
        onEvent?(SupernovaAgentEvent(
            type: type,
            text: object["text"] as? String,
            message: object["message"] as? String,
            task: object["task"] as? [String: Any]
        ))
    }
}

// MARK: - Chat model

private struct SupernovaChatMessage: Identifiable {
    enum Sender { case parent, agent }
    let id = UUID()
    var text: String
    let sender: Sender
}

@MainActor
private final class SupernovaAgentChatModel: ObservableObject {
    @Published var messages: [SupernovaChatMessage] = [
        SupernovaChatMessage(text: "مرحبًا، أنا Supernova. اكتب المهمة التي تريد إعدادها لطفلك وسأقسمها إلى مهام صغيرة مناسبة.", sender: .agent)
    ]
    @Published var draft = ""
    @Published var status = "جارٍ الاتصال بـ Supernova..."
    @Published var isWaiting = false

    var onTaskAdded: ((TaskItem) -> Void)?
    private let socket = SupernovaAgentSocket()

    init() {
        socket.onEvent = { [weak self] event in
            DispatchQueue.main.async { self?.handle(event) }
        }
    }

    func connect() { socket.connect() }

    func reconnect() {
        // يعالج جلسة عالقة إذا كان الخادم قد أُعيد تشغيله أثناء فتح الشاشة.
        socket.disconnect()
        status = "جارٍ الاتصال بـ Supernova..."
        socket.connect()
    }

    func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isWaiting else { return }
        messages.append(SupernovaChatMessage(text: text, sender: .parent))
        draft = ""
        isWaiting = true
        status = "Supernova يفكر..."
        socket.send(text)
    }

    private func handle(_ event: SupernovaAgentEvent) {
        switch event.type {
        case "session":
            status = "متصل بـ Supernova"
        case "status":
            status = event.message ?? "Supernova يفكر..."
        case "token":
            status = ""
            if let last = messages.last, last.sender == .agent, isWaiting {
                messages[messages.count - 1].text += event.text ?? ""
            } else {
                messages.append(SupernovaChatMessage(text: event.text ?? "", sender: .agent))
            }
        case "task_added":
            if let task = event.task, let item = taskItem(from: task) {
                onTaskAdded?(item)
                messages.append(SupernovaChatMessage(text: "تمت إضافة المهمة إلى قائمة مهام طفلك بنجاح ⭐", sender: .agent))
            }
        case "error":
            messages.append(SupernovaChatMessage(text: event.message ?? "تعذر الاتصال بـ Supernova. تأكد من تشغيل الخادم ثم حاول مرة أخرى.", sender: .agent))
            isWaiting = false
        case "done":
            isWaiting = false
            status = "متصل بـ Supernova"
        case "disconnected":
            isWaiting = false
            status = "انقطع الاتصال بـ Supernova"
        default:
            break
        }
    }

    private func taskItem(from task: [String: Any]) -> TaskItem? {
        guard let title = task["title"] as? String, !title.isEmpty else { return nil }
        let focus = task["focus_duration"] as? Int ?? 20
        let rest = task["break_duration"] as? Int ?? 5
        let requiresPIN = task["requires_code"] as? Bool ?? false
        let subtasks = (task["subtasks"] as? [[String: Any]] ?? []).compactMap { $0["title"] as? String }
        return TaskItem(
            title: title,
            focusMinutes: max(1, focus),
            breakMinutes: max(1, rest),
            steps: subtasks.isEmpty ? ["أكمل المهمة"] : subtasks,
            requirePin: requiresPIN
        )
    }
}

// MARK: - Chat screen

struct SupernovaAgentChatView: View {
    let onTaskAdded: (TaskItem) -> Void
    let onClose: () -> Void
    @StateObject private var model = SupernovaAgentChatModel()

    private let page = Color(red: 0.08, green: 0.10, blue: 0.25)
    private let panel = Color(red: 0.12, green: 0.15, blue: 0.34)
    private let agentBubble = Color(red: 0.16, green: 0.19, blue: 0.39)
    private let parentBubble = Color(red: 0.20, green: 0.55, blue: 0.56)
    private let mint = Color(red: 0.38, green: 0.83, blue: 0.67)

    var body: some View {
        ZStack {
            LinearGradient(colors: [page, Color(red: 0.17, green: 0.18, blue: 0.43)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Divider().overlay(Color.white.opacity(0.12))
                conversation
                composer
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            model.onTaskAdded = onTaskAdded
            model.reconnect()
        }
    }

    private var header: some View {
        HStack {
            BackCapsuleButton(action: onClose)
            Spacer()
            Text("Supernova")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Image(systemName: "sparkles")
                .foregroundStyle(mint)
                .frame(width: 46, height: 46)
                .background(Circle().fill(panel))
        }
        .padding(.horizontal, AppHeaderLayout.horizontal)
        // Use the same top inset as every other page header, so the back
        // button and the Supernova identity line up across the app.
        .padding(.top, AppHeaderLayout.top)
        .padding(.bottom, 14)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(model.messages) { message in
                        HStack {
                            if message.sender == .parent { Spacer(minLength: 140) }
                            Text(message.text)
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 22).fill(message.sender == .parent ? parentBubble : agentBubble))
                            if message.sender == .agent { Spacer(minLength: 140) }
                        }
                        .environment(\.layoutDirection, .leftToRight)
                        .id(message.id)
                    }
                    if model.isWaiting {
                        HStack {
                            Label("Supernova يفكر...", systemImage: "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(mint)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.layoutDirection, .leftToRight)
                        .id("thinking")
                    }
                }
                .padding(28)
            }
            .onChange(of: model.messages.count) { _, _ in
                if let last = model.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
            .onChange(of: model.isWaiting) { _, waiting in
                if waiting { proxy.scrollTo("thinking", anchor: .bottom) }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if !model.isWaiting {
                Text(model.status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(mint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack(spacing: 12) {
                TextField("اكتب المهمة أو إجابتك هنا...", text: $model.draft, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 18))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 20).fill(panel))
                    .foregroundStyle(.white)
                    .disabled(model.isWaiting)
                    .onSubmit { model.send() }
                Button(action: model.send) {
                    Image(systemName: model.isWaiting ? "hourglass" : "arrow.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(page)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(mint))
                }
                .disabled(model.isWaiting)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(page.opacity(0.96))
    }
}
