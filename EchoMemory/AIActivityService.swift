import Foundation
import SwiftUI


@MainActor
class AIActivityService: ObservableObject {
    

    private let apiKey = "TU_API_KEY_AQUI"
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    func generateActivities(for emotion: String, userName: String) async throws -> [Activity] {
        let prompt = buildPrompt(emotion: emotion, userName: userName)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "Eres un asistente especializado en actividades terapéuticas para personas mayores con deterioro cognitivo leve. Tus respuestas deben ser claras, empáticas y en español."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIError.invalidRequest
        }
        
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parsingError
        }
        
        return parseActivities(from: content, emotion: emotion)
    }
    

    private func buildPrompt(emotion: String, userName: String) -> String {
        let emotionContext = emotion.lowercased() == "feliz" || emotion.lowercased() == "sorprendido"
            ? "está de buen ánimo y queremos potenciar ese estado positivo"
            : "está pasando por un momento difícil y necesita apoyo emocional"
        
        return """
        La persona \(userName) \(emotionContext). Su emoción detectada fue: \(emotion).
        
        Por favor, genera exactamente 4 actividades terapéuticas personalizadas siguiendo este formato EXACTO:
        
        ACTIVIDAD 1:
        Título: [nombre corto de la actividad]
        Descripción: [descripción breve]
        Duración: [tiempo estimado, ej: 5 min]
        Categoría: [una de: Física, Mental, Social, Creativa, Relajación]
        Icono: [nombre de SF Symbol, ej: leaf.fill, music.note, book.fill]
        Pasos:
        - Paso 1
        - Paso 2
        - Paso 3
        
        ACTIVIDAD 2:
        [mismo formato]
        
        Consideraciones:
        - Las actividades deben ser simples y fáciles de seguir
        - Adecuadas para personas mayores con deterioro cognitivo leve
        - Si la emoción es positiva: actividades que mantengan el ánimo
        - Si la emoción es negativa: actividades calmantes y reconfortantes
        - Usa pasos claros y cortos (máximo 5 pasos)
        """
    }
    

    private func parseActivities(from text: String, emotion: String) -> [Activity] {
        var activities: [Activity] = []
        
        let sections = text.components(separatedBy: "ACTIVIDAD").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        for section in sections {
            guard let activity = parseActivity(from: section) else { continue }
            activities.append(activity)
        }
        
        if activities.isEmpty {
            return getFallbackActivities(for: emotion)
        }
        
        return activities
    }
    
    private func parseActivity(from text: String) -> Activity? {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var title = ""
        var description = ""
        var duration = "10 min"
        var categoryString = "Mental"
        var icon = "star.fill"
        var steps: [String] = []
        var collectingSteps = false
        
        for line in lines {
            if line.hasPrefix("Título:") {
                title = line.replacingOccurrences(of: "Título:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("Descripción:") {
                description = line.replacingOccurrences(of: "Descripción:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("Duración:") {
                duration = line.replacingOccurrences(of: "Duración:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("Categoría:") {
                categoryString = line.replacingOccurrences(of: "Categoría:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("Icono:") {
                icon = line.replacingOccurrences(of: "Icono:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("Pasos:") {
                collectingSteps = true
            } else if collectingSteps && line.hasPrefix("-") {
                let step = line.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !step.isEmpty {
                    steps.append(step)
                }
            }
        }
        
        guard !title.isEmpty else { return nil }
        
        let category: Activity.Category
        switch categoryString.lowercased() {
        case "física": category = .physical
        case "mental": category = .mental
        case "social": category = .social
        case "creativa": category = .creative
        case "relajación": category = .relaxation
        default: category = .mental
        }
        
        return Activity(
            title: title,
            description: description,
            icon: icon,
            duration: duration,
            category: category,
            steps: steps.isEmpty ? ["Realizar la actividad"] : steps
        )
    }
    
    /// Actividades de respaldo cuando la IA falla
    private func getFallbackActivities(for emotion: String) -> [Activity] {
        let isPositive = ["feliz", "sorprendido"].contains(emotion.lowercased())
        
        if isPositive {
            return [
                Activity(
                    title: "Caminar por el jardín",
                    description: "Disfruta de un paseo relajante",
                    icon: "leaf.fill",
                    duration: "15 min",
                    category: .physical,
                    steps: [
                        "Ponte zapatos cómodos",
                        "Sal al jardín o parque",
                        "Camina despacio y respira profundo",
                        "Observa las plantas y flores"
                    ]
                ),
                Activity(
                    title: "Escuchar música favorita",
                    description: "Disfruta de tus canciones preferidas",
                    icon: "music.note",
                    duration: "20 min",
                    category: .relaxation,
                    steps: [
                        "Busca tus canciones favoritas",
                        "Siéntate cómodamente",
                        "Cierra los ojos y disfruta",
                        "Canta si te apetece"
                    ]
                ),
                Activity(
                    title: "Llamar a un ser querido",
                    description: "Comparte tu alegría con alguien especial",
                    icon: "phone.fill",
                    duration: "10 min",
                    category: .social,
                    steps: [
                        "Piensa en alguien que te gustaría saludar",
                        "Realiza la llamada",
                        "Cuéntale cómo te sientes",
                        "Escucha sus noticias"
                    ]
                )
            ]
        } else {
            return [
                Activity(
                    title: "Respiración profunda",
                    description: "Ejercicio de respiración calmante",
                    icon: "wind",
                    duration: "5 min",
                    category: .relaxation,
                    steps: [
                        "Siéntate cómodamente",
                        "Inhala por la nariz (cuenta hasta 4)",
                        "Mantén el aire (cuenta hasta 4)",
                        "Exhala lentamente (cuenta hasta 6)",
                        "Repite 5 veces"
                    ]
                ),
                Activity(
                    title: "Ver álbum de fotos",
                    description: "Reconforta tu corazón con recuerdos felices",
                    icon: "photo.on.rectangle",
                    duration: "15 min",
                    category: .mental,
                    steps: [
                        "Busca tu álbum de fotos favorito",
                        "Siéntate en un lugar cómodo",
                        "Mira cada foto con calma",
                        "Recuerda los momentos felices"
                    ]
                ),
                Activity(
                    title: "Té o infusión relajante",
                    description: "Prepara una bebida caliente reconfortante",
                    icon: "cup.and.saucer.fill",
                    duration: "10 min",
                    category: .relaxation,
                    steps: [
                        "Calienta agua",
                        "Prepara tu té o infusión favorita",
                        "Siéntate tranquilamente",
                        "Disfruta cada sorbo"
                    ]
                )
            ]
        }
    }
    
    enum AIError: LocalizedError {
        case invalidRequest
        case serverError
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .invalidRequest: return "Error al crear la solicitud"
            case .serverError: return "Error del servidor"
            case .parsingError: return "Error al procesar la respuesta"
            }
        }
    }
}
