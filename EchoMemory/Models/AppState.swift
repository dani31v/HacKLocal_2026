import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var userName: String = "Carmen"
    @Published var userAge: Int = 47
    @Published var todayMessage: String = "Hoy vas a tomar tu medicamento a las 9 AM."
    @Published var emergencyName1: String = "👩🏽 Hija: Marcela"
    @Published var emergencyName2: String = "🧑🏻 Hijo: Emiliano"
    @Published var emergencyName3: String = "👨🏻 Esposo: Juan "
    @Published var caregiverName: String = "Tu hija Marcela"
    @Published var direccionCasa : String = "Calle Augusto Rodin 498 Col. Insurgentes Mixcoac 03920 Benito Juarez, CDMX, México"
    @Published var Profesion: String = "Medico"
    @Published var caregiverEmoji: String = "👩🏽"
    @Published var hasUnreadMessage: Bool = true
    @Published var emotionalEntries: [EmotionalEntry] = EmotionalEntry.sampleData()
    @Published var photoMemories: [PhotoMemory] = PhotoMemory.sampleData()
    @Published var reminders: [Reminder] = Reminder.sampleData()
    @Published var voiceMessages: [VoiceMessage] = VoiceMessage.sampleMessages()
    @Published var showWelcomeAnimation: Bool = true
    @Published var showAddReminder: Bool = false
    
    // MARK: - Emotion & Activities
    @Published var todayEmotion: CapturedEmotion?
    @Published var todayActivities: [Activity] = []
    @Published var isGeneratingActivities: Bool = false

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case activities = "figure.walk"
        case photos = "photo.fill"
        case messages = "mic.fill"
        case profile = "person.fill"

        var label: String {
            switch self {
            case .home: return "Inicio"
            case .activities: return "Actividades"
            case .photos: return "Fotos"
            case .messages: return "Mensajes"
            case .profile: return "Perfil"
            }
        }
    }
}
