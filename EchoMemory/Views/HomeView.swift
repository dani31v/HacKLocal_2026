import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var cardAppeared = false
    @State private var postItAppeared = false
    @State private var reminderIndex = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // MARK: - Header greeting
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hola,")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                        Text(appState.userName)
                            .font(.echoTitle)
                            .foregroundColor(Color.echoTextPrimary)
                    }
                    Spacer()
                    // Date pill
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Hoy es")
                            .font(.echoSmall)
                            .foregroundColor(Color.echoTextMuted)
                        Text(Date().dayOfWeekSpanish)
                            .font(.echoCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.echoTeal)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.echoMint)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // MARK: - Identity Card
                IdentityCard()
                    .opacity(cardAppeared ? 1 : 0)
                    .offset(y: cardAppeared ? 0 : 20)
                    .padding(.horizontal, 20)

                // MARK: - Post-it message of the day
                PostItMessage(message: appState.todayMessage)
                    .opacity(postItAppeared ? 1 : 0)
                    .scaleEffect(postItAppeared ? 1 : 0.9)
                    .padding(.horizontal, 20)

                // MARK: - Reminders
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recordatorios de hoy")
                        .font(.echoSubheadline)
                        .foregroundColor(Color.echoTextPrimary)
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            let sortedIndices = appState.reminders.indices.sorted {
                                !appState.reminders[$0].isCompleted && appState.reminders[$1].isCompleted
                            }
                            ForEach(sortedIndices, id: \.self) { index in
                                ReminderCard(reminder: $appState.reminders[index])
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // MARK: - Caregiver message
                if appState.hasUnreadMessage {
                    CaregiverMessageBanner()
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                cardAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.4)) {
                postItAppeared = true
            }
        }
    }
}

// MARK: - Identity Card
struct IdentityCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.echoAmber.opacity(0.4), Color.echoCoral.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Text(appState.caregiverEmoji)
                    .font(.system(size: 44))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Tu ser querido más cercano")
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextMuted)

                Text(appState.caregiverName)
                    .font(.echoHeadline)
                    .foregroundColor(Color.echoTextPrimary)

                HStack(spacing: 8) {
                    Label("\(appState.userAge) años", systemImage: "person.fill")
                    Spacer()
                    Label(Date().dayMonth, systemImage: "calendar")
                }
                .font(.echoCaption)
                .foregroundColor(Color.echoTextSecondary)
            }
        }
        .padding(20)
        .echoCard()
    }
}

// MARK: - Post-It Message
struct PostItMessage: View {
    let message: String
    @State private var unfolded = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 22))
                .foregroundColor(Color.echoAmber)

            VStack(alignment: .leading, spacing: 6) {
                Text("Mensaje del día")
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextMuted)
                Text(message)
                    .font(.echoSubheadline)
                    .foregroundColor(Color.echoTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(hex: "#FFFBEC")
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.echoAmber.opacity(0.3), lineWidth: 1.5)
                )
        )
        .cornerRadius(18)
        .shadow(color: Color.echoAmber.opacity(0.15), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                unfolded = true
            }
        }
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    @Binding var reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(reminder.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: reminder.icon)
                        .font(.system(size: 18))
                        .foregroundColor(reminder.accentColor)
                }
                Spacer()
                // Checkmark
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        reminder.isCompleted.toggle()
                    }
                } label: {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(reminder.isCompleted ? Color.moodGreen : Color.echoTextMuted)
                }
            }

            Text(reminder.title)
                .font(.echoCaption)
                .fontWeight(.semibold)
                .foregroundColor(Color.echoTextPrimary)

            Text(reminder.detail)
                .font(.echoSmall)
                .foregroundColor(Color.echoTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Label(reminder.time, systemImage: "clock.fill")
                .font(.echoSmall)
                .foregroundColor(reminder.accentColor)
        }
        .padding(16)
        .frame(width: 160, height: 160)
        .echoCard()
        .opacity(reminder.isCompleted ? 0.6 : 1)
    }
}

// MARK: - Caregiver Message Banner
struct CaregiverMessageBanner: View {
    @EnvironmentObject var appState: AppState
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            // Pulsing heart
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundColor(Color.echoCoral)
                .scaleEffect(heartScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        heartScale = 1.2
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.caregiverName) te mandó un mensaje")
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextPrimary)
                    .fontWeight(.semibold)
                Text("Toca para escuchar")
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.echoTextMuted)
        }
        .padding(16)
        .background(Color(hex: "#FFF0F0"))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.echoCoral.opacity(0.25), lineWidth: 1.5)
        )
        .onTapGesture {
            withAnimation {
                appState.selectedTab = .messages
                appState.hasUnreadMessage = false
            }
        }
    }
}
