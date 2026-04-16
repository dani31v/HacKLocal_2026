import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MessagesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mensajes")
                        .font(.echoHeadline)
                        .foregroundColor(Color.echoTextPrimary)
                    Text("Conecta con quienes amas")
                        .font(.echoCaption)
                        .foregroundColor(Color.echoTextSecondary)
                }
                Spacer()
                Text(appState.caregiverEmoji)
                    .font(.system(size: 36))
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // MARK: - Recipient card
                    RecipientCard()
                        .padding(.horizontal, 20)

                    // MARK: - Received messages
                    if !VoiceMessage.sampleMessages().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mensajes recibidos")
                                .font(.echoCaption)
                                .foregroundColor(Color.echoTextSecondary)
                                .padding(.horizontal, 20)

                            ForEach(VoiceMessage.sampleMessages()) { msg in
                                ReceivedMessageCard(message: msg)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    // MARK: - Record area
                    RecordingCard(viewModel: viewModel)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
        }
    }
}

// MARK: - Recipient Card
struct RecipientCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.echoCoral.opacity(0.15))
                    .frame(width: 60, height: 60)
                Text(appState.caregiverEmoji)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Envía un mensaje a")
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextMuted)
                Text(appState.caregiverName)
                    .font(.echoSubheadline)
                    .foregroundColor(Color.echoTextPrimary)
                    .fontWeight(.semibold)
            }

            Spacer()

            Image(systemName: "heart.fill")
                .foregroundColor(Color.echoCoral)
                .font(.system(size: 20))
        }
        .padding(18)
        .echoCard()
    }
}

// MARK: - Recording Card
struct RecordingCard: View {
    @ObservedObject var viewModel: MessagesViewModel

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isRecording {
                // Waveform animation
                WaveformView()
                    .frame(height: 60)

                Text(viewModel.recordingTimeFormatted)
                    .font(.echoHeadline)
                    .foregroundColor(Color.echoTextPrimary)
                    .monospacedDigit()

                Text("Grabando...")
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextSecondary)
            } else if viewModel.hasRecording {
                // Playback state
                HStack(spacing: 16) {
                    Button {
                        viewModel.playRecording()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.echoTeal)
                            .frame(width: 44, height: 44)
                            .background(Color.echoTeal.opacity(0.12))
                            .clipShape(Circle())
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.echoTextMuted.opacity(0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.echoTeal)
                                .frame(width: geo.size.width * viewModel.playbackProgress, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text(viewModel.recordingTimeFormatted)
                        .font(.echoCaption)
                        .foregroundColor(Color.echoTextSecondary)
                        .monospacedDigit()
                }

                HStack(spacing: 12) {
                    // Discard
                    Button {
                        withAnimation { viewModel.discardRecording() }
                    } label: {
                        Label("Descartar", systemImage: "trash.fill")
                            .font(.echoCaption)
                            .foregroundColor(Color.echoCoral)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.echoCoral.opacity(0.1))
                            .cornerRadius(20)
                    }

                    Spacer()

                    // Send
                    Button {
                        withAnimation { viewModel.sendMessage() }
                    } label: {
                        Label("Enviar", systemImage: "paperplane.fill")
                            .font(.echoCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.echoTeal)
                            .cornerRadius(20)
                    }
                }
            } else {
                // Idle state
                VStack(spacing: 10) {
                    Text("Envía un mensaje de voz")
                        .font(.echoSubheadline)
                        .foregroundColor(Color.echoTextPrimary)
                    Text("Toca el micrófono y habla con amor")
                        .font(.echoCaption)
                        .foregroundColor(Color.echoTextSecondary)
                }
            }

            // Big mic button
            Button {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else if !viewModel.hasRecording {
                    viewModel.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.echoCoral : Color.echoTeal)
                        .frame(width: 90, height: 90)
                        .shadow(color: (viewModel.isRecording ? Color.echoCoral : Color.echoTeal).opacity(0.4),
                                radius: viewModel.isRecording ? 20 : 12)
                        .scaleEffect(viewModel.isRecording ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: viewModel.isRecording)

                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.hasRecording)
            .opacity(viewModel.hasRecording ? 0.5 : 1)
        }
        .padding(24)
        .echoCard()
    }
}

// MARK: - Received Message Card
struct ReceivedMessageCard: View {
    let message: VoiceMessage
    @State private var isExpanded = false
    @State private var heartPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(message.senderEmoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(message.senderName) te respondió")
                        .font(.echoCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.echoTextPrimary)
                    Text("Hoy a las 8:45 AM")
                        .font(.echoSmall)
                        .foregroundColor(Color.echoTextMuted)
                }

                Spacer()

                Image(systemName: "heart.fill")
                    .foregroundColor(Color.echoCoral)
                    .font(.system(size: 18))
                    .scaleEffect(heartPulse ? 1.2 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            heartPulse = true
                        }
                    }
            }

            if let text = message.text {
                Text(text)
                    .font(.echoBody)
                    .foregroundColor(Color.echoTextPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#FFF0F0"))
                    .cornerRadius(14)
            }

            // Audio playback row
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.echoTeal)
                    .frame(width: 30, height: 30)
                    .background(Color.echoTeal.opacity(0.12))
                    .clipShape(Circle())

                // Fake waveform bars
                HStack(spacing: 3) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.echoTeal.opacity(0.6))
                            .frame(width: 3, height: CGFloat([8,14,10,18,12,16,8,14,20,12,16,10,18,14,8,16,12,20,10,14][i]))
                    }
                }

                Spacer()
                Text(message.duration)
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextMuted)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .echoCard(color: Color(hex: "#FFF8F8"))
    }
}

// MARK: - Waveform Animation
struct WaveformView: View {
    @State private var animating = false

    let barCount = 20
    let heights: [CGFloat] = [12, 20, 16, 28, 18, 24, 14, 30, 22, 18, 26, 14, 20, 28, 16, 24, 18, 30, 14, 22]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.echoTeal)
                    .frame(width: 4)
                    .frame(height: animating ? heights[i] : heights[i] * 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.04),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}
