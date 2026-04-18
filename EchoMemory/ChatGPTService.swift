import Foundation

/// Servicio para generar consejos y actividades usando ChatGPT
/// Basado en la emoción detectada del usuario
class ChatGPTService {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - Initialization
    
    /// Inicializa el servicio con la API key de OpenAI
    /// - Parameter apiKey: Tu API key de OpenAI (obtener en platform.openai.com)
    init(apiKey: String = "") {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    /// Genera consejos y actividades personalizadas basadas en la emoción
    /// - Parameters:
    ///   - emotion: Emoción detectada (ej: "Feliz", "Triste", "Neutral")
    ///   - userName: Nombre del usuario
    /// - Returns: Respuesta con consejo y actividades sugeridas
    func generateAdviceAndActivities(for emotion: String, userName: String) async throws -> AIResponse {
        
        // Validar que tenemos API key
        guard !apiKey.isEmpty else {
            // Si no hay API key, retornar respuesta de fallback
            return generateFallbackResponse(for: emotion, userName: userName)
        }
        
        // Crear el prompt
        let prompt = createPrompt(emotion: emotion, userName: userName)
        
        // Hacer la petición a ChatGPT
        let request = try createRequest(prompt: prompt)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Si falla la API, usar fallback
            return generateFallbackResponse(for: emotion, userName: userName)
        }
        
        // Parse la respuesta
        let chatGPTResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
        
        guard let content = chatGPTResponse.choices.first?.message.content else {
            return generateFallbackResponse(for: emotion, userName: userName)
        }
        
        // Parsear el contenido JSON de la respuesta
        return try parseAIResponse(from: content, emotion: emotion)
    }
    
    // MARK: - Private Methods
    
    private func createPrompt(emotion: String, userName: String) -> String {
        """
        Eres un asistente compasivo para adultos mayores con deterioro cognitivo leve. 
        El usuario se llama \(userName) y acaba de capturar una foto donde se detectó que se siente: \(emotion).
        
        Genera:
        1. Un mensaje breve y cálido de 1-2 líneas máximo
        2. Exactamente 3 actividades específicas, simples y cortas (5-10 minutos cada una)
        
        Las actividades deben ser:
        - Muy específicas y fáciles de seguir
        - Apropiadas para la emoción detectada
        - Sin riesgos físicos
        - Que se puedan hacer en casa
        
        Si está feliz: actividades que mantengan ese estado positivo
        Si está triste: actividades suaves que ayuden a sentirse mejor
        Si está neutral: actividades que estimulen y motiven
        
        IMPORTANTE: Responde SOLO en formato JSON válido, sin texto adicional:
        {
          "message": "tu mensaje aquí",
          "activities": [
            {
              "title": "título corto",
              "description": "descripción breve",
              "duration": "5 min",
              "icon": "nombre de SF Symbol como figure.walk o music.note"
            }
          ]
        }
        """
    }
    
    private func createRequest(prompt: String) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw ChatGPTError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini", // Modelo más económico y rápido
            "messages": [
                [
                    "role": "system",
                    "content": "Eres un asistente especializado en salud mental para adultos mayores. Respondes siempre en español y en formato JSON."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func parseAIResponse(from content: String, emotion: String) throws -> AIResponse {
        // Limpiar posible markdown
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            throw ChatGPTError.invalidResponse
        }
        
        let response = try JSONDecoder().decode(AIResponse.self, from: data)
        return response
    }
    
    private func generateFallbackResponse(for emotion: String, userName: String) -> AIResponse {
        let lower = emotion.lowercased()
        
        if lower.contains("feliz") || lower.contains("alegr") {
            return AIResponse(
                message: "¡Qué alegría verte tan feliz, \(userName)! Aprovecha este momento para compartir esa energía positiva.",
                activities: [
                    SuggestedActivity(
                        title: "Llama a un ser querido",
                        description: "Comparte tu buen momento con alguien especial por teléfono",
                        duration: "5 min",
                        icon: "phone.fill"
                    ),
                    SuggestedActivity(
                        title: "Escribe 3 cosas positivas",
                        description: "Anota tres cosas por las que te sientes agradecido hoy",
                        duration: "5 min",
                        icon: "pencil.and.list.clipboard"
                    ),
                    SuggestedActivity(
                        title: "Paseo corto",
                        description: "Da una vuelta por tu vecindario o jardín",
                        duration: "10 min",
                        icon: "figure.walk"
                    )
                ]
            )
        } else if lower.contains("triste") || lower.contains("baj") {
            return AIResponse(
                message: "Entiendo que no te sientes del todo bien, \(userName). Pequeñas acciones pueden ayudarte a sentirte mejor.",
                activities: [
                    SuggestedActivity(
                        title: "Respiración consciente",
                        description: "Inhala 4 segundos, retén 4, exhala 4. Repite 5 veces",
                        duration: "3 min",
                        icon: "wind"
                    ),
                    SuggestedActivity(
                        title: "Escucha música relajante",
                        description: "Pon una canción que te guste y descansa",
                        duration: "10 min",
                        icon: "music.note"
                    ),
                    SuggestedActivity(
                        title: "Contacta a alguien",
                        description: "Envía un mensaje o llama a alguien de confianza",
                        duration: "5 min",
                        icon: "message.fill"
                    )
                ]
            )
        } else {
            return AIResponse(
                message: "Hola \(userName), veo que estás tranquilo. Aquí hay algunas actividades para tu día.",
                activities: [
                    SuggestedActivity(
                        title: "Hidratación",
                        description: "Bebe un vaso de agua fresca",
                        duration: "2 min",
                        icon: "drop.fill"
                    ),
                    SuggestedActivity(
                        title: "Estiramiento suave",
                        description: "Estira brazos y piernas suavemente, sin forzar",
                        duration: "5 min",
                        icon: "figure.flexibility"
                    ),
                    SuggestedActivity(
                        title: "Lee algo ligero",
                        description: "Lee un artículo o capítulo de un libro que te guste",
                        duration: "10 min",
                        icon: "book.fill"
                    )
                ]
            )
        }
    }
    
    // MARK: - Errors
    
    enum ChatGPTError: LocalizedError {
        case invalidURL
        case invalidResponse
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL inválida"
            case .invalidResponse:
                return "Respuesta inválida de ChatGPT"
            case .apiError(let message):
                return "Error de API: \(message)"
            }
        }
    }
}

// MARK: - Models

struct AIResponse: Codable {
    let message: String
    let activities: [SuggestedActivity]
}

struct SuggestedActivity: Codable, Identifiable {
    var id = UUID()
    let title: String
    let description: String
    let duration: String
    let icon: String
    
    enum CodingKeys: String, CodingKey {
        case title, description, duration, icon
    }
}

// MARK: - ChatGPT API Response Models

private struct ChatGPTResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

// MARK: - Usage Example

/*
 CONFIGURACIÓN:
 
 1. Obtener API Key de OpenAI:
    - Ir a https://platform.openai.com/api-keys
    - Crear cuenta o iniciar sesión
    - Crear nueva API key
    - Copiar la key (empieza con "sk-...")
 
 2. Guardar la API Key de forma segura:
 
    OPCIÓN 1 - Archivo de configuración (NO subir a git):
    - Crear archivo Config.plist en tu proyecto
    - Agregar key "OPENAI_API_KEY" con tu API key
    - Agregar Config.plist a .gitignore
 
    OPCIÓN 2 - Variable de entorno:
    - En Xcode: Edit Scheme > Run > Arguments > Environment Variables
    - Agregar OPENAI_API_KEY = tu_key_aquí
 
    OPCIÓN 3 - Hardcoded (solo para pruebas, NUNCA en producción):
    let service = ChatGPTService(apiKey: "sk-tu-key-aquí")
 
 3. Uso en HomeView:
 
    private func generateActivitiesWithAI(_ emotion: String) async {
        let service = ChatGPTService(apiKey: loadAPIKey())
        
        do {
            let response = try await service.generateAdviceAndActivities(
                for: emotion,
                userName: appState.userName
            )
            
            await MainActor.run {
                // Mostrar mensaje
                self.aiAdviceMessage = response.message
                
                // Crear actividades
                self.suggestedActivities = response.activities
            }
        } catch {
            print("Error generando actividades: \(error)")
            // Fallback ya está incluido en el servicio
        }
    }
 
 COSTOS ESTIMADOS:
 - GPT-4o-mini: ~$0.00015 por solicitud (muy económico)
 - GPT-4: ~$0.03 por solicitud (más caro pero más preciso)
 
 ALTERNATIVA GRATUITA:
 Si no quieres usar la API de pago, el servicio automáticamente usa
 respuestas de fallback predefinidas cuando apiKey está vacío.
*/
// MARK: - Conversión a Activity

extension SuggestedActivity {
    /// Convierte una actividad sugerida a Activity para el AppState
    func toActivity() -> Activity {
        // Determinar categoría según el icono o título
        let category: Activity.Category = {
            let lowerTitle = title.lowercased()
            let lowerIcon = icon.lowercased()
            
            if lowerIcon.contains("figure") || lowerIcon.contains("walk") || lowerTitle.contains("paseo") {
                return .physical
            } else if lowerIcon.contains("book") || lowerIcon.contains("pencil") || lowerTitle.contains("escribir") || lowerTitle.contains("lista") {
                return .mental
            } else if lowerIcon.contains("message") || lowerIcon.contains("phone") || lowerIcon.contains("person") || lowerTitle.contains("llama") || lowerTitle.contains("contacta") {
                return .social
            } else if lowerIcon.contains("wind") || lowerIcon.contains("sparkles") || lowerTitle.contains("respir") || lowerTitle.contains("música") {
                return .relaxation
            } else {
                return .creative
            }
        }()
        
        return Activity(
            title: title,
            description: description,
            icon: icon,
            duration: duration,
            category: category,
            steps: [
                "Prepárate en un lugar cómodo",
                description,
                "Tómate tu tiempo y disfruta"
            ],
            isCompleted: false,
            completedAt: nil
        )
    }
}


