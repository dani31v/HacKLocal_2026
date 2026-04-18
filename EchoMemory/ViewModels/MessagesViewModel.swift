import SwiftUI
import AVFoundation
import Combine

class MessagesViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var isPlaying = false
    @Published var playbackProgress: CGFloat = 0.0
    @Published var recordingSeconds: Int = 0
    @Published var messageSent = false

    private var timer: Timer?
    private var playbackTimer: Timer?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?

    var recordingTimeFormatted: String {
        let mins = recordingSeconds / 60
        let secs = recordingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func startRecording() {
        // Request microphone permission
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard granted else { return }
                    self?.beginRecording()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard granted else { return }
                    self?.beginRecording()
                }
            }
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("echo_voice.m4a")
            recordingURL = url

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()

            isRecording = true
            recordingSeconds = 0
            startTimer()
        } catch {
            // Simulation fallback for Simulator
            isRecording = true
            recordingSeconds = 0
            startTimer()
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        hasRecording = true
        stopTimer()
    }

    func playRecording() {
        guard let url = recordingURL else {
            // Simulate playback
            simulatePlayback()
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            simulatePlayback()
        } catch {
            simulatePlayback()
        }
    }

    private func simulatePlayback() {
        isPlaying = true
        playbackProgress = 0
        let totalSeconds = max(1, recordingSeconds)
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.playbackProgress += 0.1 / CGFloat(totalSeconds)
            if self.playbackProgress >= 1.0 {
                self.playbackProgress = 1.0
                self.isPlaying = false
                t.invalidate()
            }
        }
    }

    func discardRecording() {
        audioRecorder?.stop()
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        isRecording = false
        hasRecording = false
        isPlaying = false
        playbackProgress = 0
        recordingSeconds = 0
    }

    func sendMessage(appState: AppState) {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        
        var finalURL: URL? = nil
        if let tempURL = recordingURL {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "echo_voice_\(UUID().uuidString).m4a"
            let destination = documents.appendingPathComponent(filename)
            do {
                try FileManager.default.copyItem(at: tempURL, to: destination)
                finalURL = destination
            } catch {
                print("Error saving audio file: \(error)")
            }
        }

        let newMessage = VoiceMessage(
            senderName: appState.userName,
            senderEmoji: "👩🏽",
            duration: recordingTimeFormatted,
            date: Date(),
            isFromCaregiver: false,
            text: "Mensaje de voz",
            audioURL: finalURL
        )

        withAnimation {
            appState.voiceMessages.insert(newMessage, at: 0)
            messageSent = true
            hasRecording = false
            isPlaying = false
            playbackProgress = 0
            recordingSeconds = 0
            recordingURL = nil
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { self.messageSent = false }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
