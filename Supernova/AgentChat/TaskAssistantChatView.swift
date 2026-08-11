
import SwiftUI
import Foundation
import Combine

enum ChatPalette {
    static let page = Color(red: 0.08, green: 0.10, blue: 0.25)
    static let panel = Color(red: 0.12, green: 0.15, blue: 0.34)
    static let assistantBubble = Color(red: 0.16, green: 0.19, blue: 0.39)
    static let parentBubble = Color(red: 0.20, green: 0.55, blue: 0.56)
    static let input = Color(red: 0.25, green: 0.29, blue: 0.55)
    static let mint = Color(red: 0.38, green: 0.83, blue: 0.67)
}

struct ChatMessage: Identifiable, Equatable {
    enum Sender { case assistant, parent }
    let id = UUID()
    var text: String
    let sender: Sender
}

@MainActor
final class TaskChatViewModel: ObservableObject {
    @Published var messages = [
        ChatMessage(text: "مرحبًا، أنا Supernova، مساعد المهام. اكتب المهمة التي تريد إعدادها لطفلك.", sender: .assistant)
    ]
    @Published var draft = ""
    @Published var status = "جارٍ الاتصال بالمساعد..."
    @Published var isSending = false

    private let agent = AgentWebSocketService()

    init() {
        agent.onEvent = { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
    }

    func connect() { agent.connect() }

    func send(_ suggestion: String? = nil) {
        let text = (suggestion ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        messages.append(ChatMessage(text: text, sender: .parent))
        draft = ""
        isSending = true
        status = "المساعد يجهّز الرد..."
        agent.send(text)
    }

    private func handle(_ event: AgentEvent) {
        switch event.type {
        case "session":
            status = "متصل بالمساعد"
        case "status":
            status = event.message ?? "المساعد يعمل..."
        case "token":
            status = ""
            if let last = messages.last, last.sender == .assistant, isSending {
                messages[messages.count - 1].text += event.text ?? ""
            } else {
                messages.append(ChatMessage(text: event.text ?? "", sender: .assistant))
            }
        case "task_added":
            // This comes from the real agent only after explicit parent approval.
            status = "تم إرسال المهمة إلى قائمة المهام"
        case "error":
            messages.append(ChatMessage(text: event.message ?? "تعذر الاتصال بالمساعد. حاول مرة أخرى.", sender: .assistant))
            isSending = false
        case "done":
            isSending = false
            status = "متصل بالمساعد"
        case "disconnected":
            status = "انقطع الاتصال بالمساعد"
            isSending = false
        default:
            break
        }
    }
}

struct TaskChatView: View {
    @StateObject private var model = TaskChatViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    private let suggestions = ["أريد إنشاء مهمة", "قسّم مهمة موجودة", "ساعدني في تنظيم واجب"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [ChatPalette.page, Color(red: 0.17, green: 0.18, blue: 0.43)], startPoint: .top, endPoint: .bottom)
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
        .task { model.connect() }
        .onAppear {
            speechRecognizer.onTranscript = { transcript in
                model.draft = transcript
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(ChatPalette.mint)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.10)))
            Text("Supernova")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text("AI")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ChatPalette.mint)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.09)))
                .overlay(Capsule().stroke(Color.white.opacity(0.13)))
        }
        .padding(.horizontal, 28)
        .frame(height: 84)
        .background(ChatPalette.page.opacity(0.78))
        .environment(\.layoutDirection, .leftToRight)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 15) {
                    if model.status == "انقطع الاتصال بالمساعد" {
                        Text(model.status)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.orange.opacity(0.95))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    ForEach(model.messages) { message in
                        MessageBubble(message: message).id(message.id)
                    }
                    if model.isSending, model.messages.last?.sender == .parent {
                        ThinkingIndicator().id("thinking")
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }
            .onChange(of: model.messages) { _, messages in
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.22)) { proxy.scrollTo(last.id, anchor: .bottom) }
            }
            .onChange(of: model.isSending) { _, sending in
                if sending { withAnimation(.easeOut(duration: 0.22)) { proxy.scrollTo("thinking", anchor: .bottom) } }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 13) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) { model.send(suggestion) }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 11)
                            .background(Capsule().fill(ChatPalette.panel))
                            .overlay(Capsule().stroke(Color.white.opacity(0.16)))
                    }
                }
                .padding(.horizontal, 28)
            }
            if let errorMessage = speechRecognizer.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.orange.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 28)
            }
            if let statusMessage = speechRecognizer.statusMessage {
                Text(statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ChatPalette.mint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 28)
            }
            HStack(spacing: 12) {
                Button { speechRecognizer.toggleRecording() } label: {
                    Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(ChatPalette.mint)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(ChatPalette.panel))
                        .overlay(Circle().stroke(ChatPalette.mint.opacity(speechRecognizer.isRecording ? 0.80 : 0.18), lineWidth: speechRecognizer.isRecording ? 2 : 1))
                }
                .disabled(model.isSending)
                .accessibilityLabel(speechRecognizer.isRecording ? "إيقاف التسجيل" : "إدخال صوتي")
                TextField("اكتب المهمة أو إجابتك هنا...", text: $model.draft, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 20).fill(ChatPalette.input.opacity(0.70)))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12)))
                    .disabled(model.isSending)
                    .onSubmit { model.send() }
                Button { model.send() } label: {
                    Image(systemName: model.isSending ? "hourglass" : "arrow.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ChatPalette.page)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(ChatPalette.mint))
                }
                .disabled(model.isSending)
                .accessibilityLabel("إرسال")
            }
            .padding(.horizontal, 28)
        }
        .padding(.top, 14).padding(.bottom, 18)
        .background(ChatPalette.page.opacity(0.94))
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.sender == .parent { Spacer(minLength: 110) }
            Text(message.text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineSpacing(4)
                .padding(.horizontal, 18).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 21).fill(message.sender == .parent ? ChatPalette.parentBubble : ChatPalette.assistantBubble))
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.white.opacity(message.sender == .parent ? 0 : 0.12)))
            if message.sender == .assistant { Spacer(minLength: 110) }
        }
        // The chat's positions are intentional: parent on the right, agent on
        // the left. Keep this independent of the Arabic text direction.
        .environment(\.layoutDirection, .leftToRight)
    }
}

private struct ThinkingIndicator: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ChatPalette.mint)
            Text("Supernova يفكر...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ChatPalette.mint)
            Spacer(minLength: 110)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 5)
        .environment(\.layoutDirection, .leftToRight)
    }
}
