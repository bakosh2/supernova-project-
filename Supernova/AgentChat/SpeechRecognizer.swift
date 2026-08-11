import AVFoundation
import Speech
import Combine

/// Converts the parent's Arabic speech into text on the iPad.
/// The recognised text is placed in the chat composer; it is never sent until
/// the parent taps the normal send button.
@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var statusMessage: String?

    var onTranscript: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func toggleRecording() {
        isRecording ? stopRecording() : requestPermissionsAndStart()
    }

    func stopRecording() {
        guard isRecording else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
        statusMessage = nil
    }

    private func requestPermissionsAndStart() {
        errorMessage = nil
        statusMessage = "جارٍ تجهيز الميكروفون..."
        guard recognizer?.isAvailable == true else {
            errorMessage = "التعرّف على الكلام غير متاح الآن. تحقّق من اتصال الإنترنت أو إعدادات الجهاز."
            statusMessage = nil
            return
        }

        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            guard speechStatus == .authorized else {
                Task { @MainActor in
                    self?.errorMessage = "اسمح للتطبيق باستخدام التعرّف على الكلام من الإعدادات."
                    self?.statusMessage = nil
                }
                return
            }
            AVAudioApplication.requestRecordPermission { allowed in
                Task { @MainActor in
                    guard allowed else {
                        self?.errorMessage = "اسمح للتطبيق باستخدام الميكروفون من الإعدادات."
                        self?.statusMessage = nil
                        return
                    }
                    self?.startRecording()
                }
            }
        }
    }

    private func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "تعذّر تجهيز الميكروفون. تحقّق من إذن الميكروفون."
            statusMessage = nil
            return
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            inputNode.removeTap(onBus: 0)
            errorMessage = "تعذّر بدء تسجيل الصوت. حاول مرة أخرى."
            statusMessage = nil
            return
        }

        statusMessage = "جارٍ الاستماع... اضغط زر الإيقاف عند الانتهاء"
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.onTranscript?(result.bestTranscription.formattedString)
                    if result.isFinal { self.stopRecording() }
                }
                if error != nil, self.isRecording {
                    self.errorMessage = "توقف التعرّف على الكلام. حاول مرة أخرى."
                    self.stopRecording()
                }
            }
        }
    }
}
