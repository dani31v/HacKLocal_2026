import SwiftUI
import Foundation

// MARK: - EmotionalEntry
struct EmotionalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var mood: Mood
    var note: String?

    enum Mood: String, Codable, CaseIterable {
        case great = "Bien"
        case neutral = "Neutro"
        case sad = "Decaído"

        var color: Color {
            switch self {
            case .great: return Color.moodGreen
            case .neutral: return Color.moodYellow
            case .sad: return Color.moodRed
            }
        }

        var emoji: String {
            switch self {
            case .great: return "😊"
            case .neutral: return "😐"
            case .sad: return "😔"
            }
        }

        var colorHex: String {
            switch self {
            case .great: return "#6DBF82"
            case .neutral: return "#F5C872"
            case .sad: return "#F28B82"
            }
        }
    }

    static func sampleData() -> [EmotionalEntry] {
        let calendar = Calendar.current
        let today = Date()
        var entries: [EmotionalEntry] = []
        let randomNotes = [
            "Visité el jardín", "Hablé con mi hija", "Me sentí un poco cansada",
            "Comí pastel", "Vi una película bonita", "Me dolió la espalda",
            "Salí a caminar", "Día muy tranquilo", "Escuché música de antes",
            "Recordé a mi mamá", "Dormí muy bien"
        ]
        for i in (1..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let randomMood: Mood = [.great, .great, .neutral, .sad, .great].randomElement()!
            let hasNote = Bool.random()
            let note = hasNote ? randomNotes.randomElement()! : nil
            entries.append(EmotionalEntry(date: date, mood: randomMood, note: note))
        }
        return entries
    }
}

// MARK: - PhotoMemory
struct PhotoMemory: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var time: String
    var imageName: String        // Nombre del archivo guardado o URL
    var emoji: String
    var location: String?
    var relatedPerson: String?
    var mood: EmotionalEntry.Mood

    static func sampleData() -> [PhotoMemory] {
        let calendar = Calendar.current
        let today = Date()
        return [
            PhotoMemory(date: today, time: "10:15 AM", imageName: "https://images.unsplash.com/photo-1541883584821-2e6b72a6b245?auto=format&fit=crop&q=80&w=800",
                        emoji: "😊", location: "Cocina", mood: .great),
            PhotoMemory(date: today, time: "3:45 PM", imageName: "https://images.unsplash.com/photo-1541883584821-2e6b72a6b245?auto=format&fit=crop&q=80&w=800",
                        emoji: "❤️", relatedPerson: "Hija", mood: .neutral),
            PhotoMemory(date: today, time: "5:20 PM", imageName: "https://images.unsplash.com",
                        emoji: "😊", location: "Jardín", mood: .great),
            PhotoMemory(date: calendar.date(byAdding: .day, value: -1, to: today)!, time: "7:10 AM",
                        imageName: "https://images.unsplash.com/photo-1541883584821-2e6b72a6b245?auto=format&fit=crop&q=80&w=800", emoji: "😊", location: "Ventana", mood: .great),
            PhotoMemory(date: calendar.date(byAdding: .day, value: -1, to: today)!, time: "6:30 PM",
                        imageName: "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80&w=800", emoji: "❤️", relatedPerson: "Familia", mood: .neutral)
        ]
    }
}

// MARK: - Reminder
struct Reminder: Identifiable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var time: String
    var timeDate: Date
    var icon: String
    var isCompleted: Bool = false
    var accentColor: Color

    static func sampleData() -> [Reminder] {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return [
            Reminder(title: "Medicamento", detail: "Tomar pastilla azul con agua",
                     time: "9:00 AM", timeDate: formatter.date(from: "9:00 AM") ?? Date(), icon: "pills.fill", accentColor: Color.echoMint),
            Reminder(title: "Cita médica", detail: "Con el Dr. Ramírez en el consultorio",
                     time: "2:00 PM", timeDate: formatter.date(from: "2:00 PM") ?? Date(), icon: "stethoscope", accentColor: Color.echoCoral)
        ]
    }
}

// MARK: - VoiceMessage
struct VoiceMessage: Identifiable {
    var id: UUID = UUID()
    var senderName: String
    var senderEmoji: String
    var duration: String
    var date: Date
    var isFromCaregiver: Bool
    var text: String?
    var audioURL: URL?

    static func sampleMessages() -> [VoiceMessage] {
        [
            VoiceMessage(senderName: "Tu hija", senderEmoji: "👩🏽",
                         duration: "0:18", date: Date(), isFromCaregiver: true,
                         text: "Hola mami, me dio mucho gusto escucharte. Te quiero ❤️",
                         audioURL: nil)
        ]
    }
}
// MARK: - CapturedEmotion
struct CapturedEmotion: Identifiable {
    var id: UUID = UUID()
    var emotion: String // "Feliz", "Triste", "Neutral", "Enojado", "Sorprendido"
    var capturedImage: UIImage?
    var assetLocalIdentifier: String?
    var timestamp: Date
    var confidenceLevel: Double = 1.0
    
    var displayMessage: String {
        switch emotion.lowercased() {
        case "feliz": return "Te ves feliz ✨"
        case "triste": return "Te ves triste, pero aquí estamos para ti 💙"
        case "neutral": return "Te ves tranquilo"
        case "enojado": return "Te ves molesto, respira profundo 🌬️"
        case "sorprendido": return "Te ves sorprendido 😮"
        default: return "Te veo bien hoy"
        }
    }
    
    var isPositive: Bool {
        ["feliz", "sorprendido"].contains(emotion.lowercased())
    }
}

// MARK: - Activity
struct Activity: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var icon: String
    var duration: String // "5 min", "10 min", etc.
    var category: Category
    var steps: [String]
    var isCompleted: Bool = false
    var completedAt: Date?
    
    enum Category: String {
        case physical = "Física"
        case mental = "Mental"
        case social = "Social"
        case creative = "Creativa"
        case relaxation = "Relajación"
        
        var color: Color {
            switch self {
            case .physical: return Color.moodGreen
            case .mental: return Color.echoTeal
            case .social: return Color.echoCoral
            case .creative: return Color.echoAmber
            case .relaxation: return Color(hex: "#A8C9E8")
            }
        }
    }
}

