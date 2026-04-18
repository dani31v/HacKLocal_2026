import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Perfil")
                            .font(.echoTitle)
                            .foregroundColor(Color.echoTextPrimary)
                        Text("Tu información")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.echoTeal.opacity(0.4), Color.echoBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text("👤")
                        .font(.system(size: 40))
                }
                
                
                Text(appState.userName)
                    .font(.echoTitle)
                    .foregroundColor(Color.echoTextPrimary)
                
                Text("\(appState.userAge) años")
                    .font(.system(size: 20))
                    .foregroundColor(Color.echoTextSecondary)
          
            
                HStack(spacing: 8) {
                    Text(appState.emergencyName1)
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)

                    Text(appState.emergencyName2)
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)

                    Text(appState.emergencyName3)
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 12) {
                    StatCard(
                        icon: "checkmark.circle.fill",
                        title: "Actividades completadas",
                        value: "\(appState.todayActivities.filter { $0.isCompleted }.count)",
                        color: Color.moodGreen
                    )
                    
                    StatCard(
                        icon: "face.smiling.fill",
                        title: "Emoción del día",
                        value: appState.todayEmotion?.emotion ?? "Sin registrar",
                        color: Color.echoTeal
                    )
                    
                    StatCard(
                        icon: "photo.fill",
                        title: "Fotos guardadas",
                        value: "\(appState.photoMemories.count)",
                        color: Color.echoAmber
                    )
                    StatCard(
                        icon: "pill.fill",
                        title: "Medicinas Registradas",
                        value: "3",
                        color: Color.echoCoral
                    )
                    Text(" ")
                        .padding(.top,-5)
                    
                    Text("Historial Semanal: ")
                        .font(.system(size: 18))
                        .foregroundColor(Color.echoTextSecondary)
                    
                    EmotionLineChart(
                        entries: Array(appState.emotionalEntries.suffix(7)),
                        appeared: true
                    )
                    .frame(height: 160)
                    .padding(.horizontal, 20)
                    .echoCard()
                }
                
                
                
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextSecondary)
                Text(value)
                    .font(.echoHeadline)
                    .foregroundColor(Color.echoTextPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

