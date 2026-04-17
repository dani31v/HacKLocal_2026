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
        return [
            EmotionalEntry(date: calendar.date(byAdding: .day, value: -6, to: today)!, mood: .neutral),
            EmotionalEntry(date: calendar.date(byAdding: .day, value: -5, to: today)!, mood: .sad),
            EmotionalEntry(date: calendar.date(byAdding: .day, value: -4, to: today)!, mood: .neutral, note: "Tomé mi medicina"),
            EmotionalEntry(date: calendar.date(byAdding: .day, value: -3, to: today)!, mood: .great, note: "Llamé a mi hija"),
            EmotionalEntry(date: calendar.date(byAdding: .day, value: -2, to: today)!, mood: .great, note: "Salí al jardín"),
            EmotionalEntry(date: calendar.date(byAdding: .day, value: -1, to: today)!, mood: .neutral),
            EmotionalEntry(date: today, mood: .great, note: "Me sentí con energía")
        ]
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
            PhotoMemory(date: today, time: "10:15 AM", imageName: "cup.and.saucer.fill",
                        emoji: "😊", location: "Cocina", mood: .great),
            PhotoMemory(date: today, time: "3:45 PM", imageName: "heart.fill",
                        emoji: "❤️", relatedPerson: "Hija", mood: .great),
            PhotoMemory(date: today, time: "5:20 PM", imageName: "leaf.fill",
                        emoji: "😊", location: "Jardín", mood: .great),
            PhotoMemory(date: calendar.date(byAdding: .day, value: -1, to: today)!, time: "7:10 AM",
                        imageName: "sunrise.fill", emoji: "😊", location: "Ventana", mood: .great),
            PhotoMemory(date: calendar.date(byAdding: .day, value: -1, to: today)!, time: "6:30 PM",
                        imageName: "house.fill", emoji: "❤️", relatedPerson: "Familia", mood: .neutral)
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

    static func sampleMessages() -> [VoiceMessage] {
        [
            VoiceMessage(senderName: "Tu hija", senderEmoji: "👩🏽",
                         duration: "0:18", date: Date(), isFromCaregiver: true,
                         text: "Hola mami, me dio mucho gusto escucharte. Te quiero ❤️")
        ]
    }
}
