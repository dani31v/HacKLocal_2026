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
        case sad = "Mal"

        var color: Color {
            switch self {
            case .great: return Color("MoodGreen")
            case .neutral: return Color("MoodYellow")
            case .sad: return Color("MoodRed")
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
        for i in (0..<30).reversed() {
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
    var imageName: String        // SF Symbol or asset name
    var emoji: String
    var location: String?
    var relatedPerson: String?
    var mood: EmotionalEntry.Mood

    static func sampleData() -> [PhotoMemory] {
        let calendar = Calendar.current
        let today = Date()
        return [
            PhotoMemory(date: today, time: "10:15 AM", imageName: "https://images.unsplash.com/photo-1544027993-37dbfe43562a?auto=format&fit=crop&q=80&w=800",
                        emoji: "😊", location: "Cocina", mood: .great),
            PhotoMemory(date: today, time: "3:45 PM", imageName: "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80&w=800",
                        emoji: "❤️", relatedPerson: "Hija", mood: .great),
            PhotoMemory(date: today, time: "5:20 PM", imageName: "https://images.unsplash.com/photo-1416879598555-5380572ddad7?auto=format&fit=crop&q=80&w=800",
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
    var icon: String
    var isCompleted: Bool = false
    var accentColor: Color

    static func sampleData() -> [Reminder] {
        [
            Reminder(title: "Medicamento", detail: "Tomar pastilla azul con agua",
                     time: "9:00 AM", icon: "pills.fill", accentColor: Color("AccentBlue")),
            Reminder(title: "Cita médica", detail: "Con el Dr. Ramírez en el consultorio",
                     time: "2:00 PM", icon: "stethoscope", accentColor: Color("AccentGreen")),
            Reminder(title: "Llamada", detail: "Tu hija te llamará hoy",
                     time: "4:30 PM", icon: "phone.fill", accentColor: Color("AccentPeach"))
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
