import UIKit
import Vision
import CoreML

/// Servicio de detección de emociones usando Vision Framework
/// NOTA: Requiere un modelo CoreML entrenado (no incluido)
/// 
/// Para crear el modelo:
/// 1. Descargar dataset de emociones (FER-2013, AffectNet, etc.)
/// 2. Usar Create ML para entrenar clasificador de imágenes
/// 3. Categorías: Feliz, Triste, Enojado, Sorprendido, Neutral, Asustado, Disgustado
/// 4. Exportar como .mlmodel y agregarlo al proyecto
class EmotionDetectionService {
    
    // MARK: - Properties
    
    /// Modelo CoreML (reemplazar con tu modelo)
    /// Ejemplo: private var model: VNCoreMLModel?
    
    // MARK: - Detection Methods
    
    /// Detecta emoción usando Vision Framework y CoreML
    /// - Parameter image: Imagen del usuario
    /// - Returns: String con la emoción detectada
    func detectEmotion(from image: UIImage) async throws -> String {
        
        // OPCIÓN 1: Usar modelo CoreML custom
        // return try await detectWithCoreML(image)
        
        // OPCIÓN 2: Usar detección facial básica de Vision
        return try await detectWithVisionFaceDetection(image)
        
        // OPCIÓN 3: Heurística simple (actual - para desarrollo)
        // return detectWithHeuristic(image)
    }
    
    // MARK: - CoreML Detection (Recomendado)
    
    /// Detecta emoción usando modelo CoreML entrenado
    private func detectWithCoreML(_ image: UIImage) async throws -> String {
        /*
        // TODO: Descomentar cuando tengas el modelo
        
        guard let model = try? VNCoreMLModel(for: EmotionClassifier().model) else {
            throw EmotionError.modelNotFound
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            // Procesar resultados
        }
        
        guard let cgImage = image.cgImage else {
            throw EmotionError.invalidImage
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        // Obtener clasificación con mayor confianza
        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            throw EmotionError.noResults
        }
        
        return mapEmotionToSpanish(topResult.identifier)
        */
        
        throw EmotionError.notImplemented
    }
    
    // MARK: - Vision Face Detection (Alternativa)
    
    /// Detecta emoción usando análisis facial de Vision
    private func detectWithVisionFaceDetection(_ image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: EmotionError.invalidImage)
                return
            }
            
            // Usar VNDetectFaceLandmarksRequest en lugar de VNDetectFaceExpressionsRequest
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation],
                      let faceObservation = observations.first else {
                    // No se detectó rostro, usar heurística
                    continuation.resume(returning: self.detectWithHeuristic(image))
                    return
                }
                
                // Analizar expresiones faciales
                let emotion = self.analyzeExpression(faceObservation)
                continuation.resume(returning: emotion)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Analiza expresiones faciales detectadas
    private func analyzeExpression(_ face: VNFaceObservation) -> String {
        // Vision no provee clasificación directa de emociones,
        // pero podemos usar características faciales como proxy
        
        // Obtener landmarks faciales si están disponibles
        guard let landmarks = face.landmarks else {
            print("⚠️ No se detectaron landmarks faciales")
            return "Neutral"
        }
        
        print("✅ Landmarks detectados")
        
        // Analizar características faciales básicas
        var emotionScore = 0.0
        var detailLog: [String] = []
        
        // 1. Analizar boca (sonrisa vs tristeza) - PESO AUMENTADO
        if let outerLips = landmarks.outerLips {
            let points = outerLips.normalizedPoints
            if points.count >= 8 {
                // Obtener puntos clave de la boca
                let leftCorner = points[0]
                let rightCorner = points[6]
                let topCenter = points[3]
                let bottomCenter = points[9 % points.count]
                
                // Calcular curvatura de la boca
                let mouthMidY = (leftCorner.y + rightCorner.y) / 2
                let mouthCenterY = (topCenter.y + bottomCenter.y) / 2
                
                // Calcular apertura vertical de la boca
                let mouthHeight = abs(topCenter.y - bottomCenter.y)
                
                // Si las esquinas están más bajas que el centro = sonrisa
                let smileIndicator = mouthMidY - mouthCenterY
                
                if smileIndicator > 0.005 {
                    // Sonrisa detectada
                    emotionScore += 3.0
                    detailLog.append("😊 Sonrisa detectada (score: +3.0)")
                } else if smileIndicator < -0.005 {
                    // Boca hacia abajo = tristeza
                    emotionScore -= 2.5
                    detailLog.append("😔 Tristeza detectada (score: -2.5)")
                }
                
                // Boca muy abierta puede indicar sorpresa o felicidad
                if mouthHeight > 0.03 {
                    emotionScore += 0.5
                    detailLog.append("😮 Boca abierta (score: +0.5)")
                }
            }
        }
        
        // 2. Analizar cejas (arriba = sorprendido/feliz, abajo = triste/enojado)
        if let leftEyebrow = landmarks.leftEyebrow, let rightEyebrow = landmarks.rightEyebrow {
            let leftBrowPoints = leftEyebrow.normalizedPoints
            let rightBrowPoints = rightEyebrow.normalizedPoints
            
            if !leftBrowPoints.isEmpty && !rightBrowPoints.isEmpty {
                // Promedio de altura de cejas
                let leftBrowY = leftBrowPoints.map { $0.y }.reduce(0, +) / Double(leftBrowPoints.count)
                let rightBrowY = rightBrowPoints.map { $0.y }.reduce(0, +) / Double(rightBrowPoints.count)
                let avgBrowY = (leftBrowY + rightBrowY) / 2
                
                // Cejas levantadas = feliz/sorprendido
                if avgBrowY < 0.35 {
                    emotionScore += 1.0
                    detailLog.append("🤨 Cejas arriba (score: +1.0)")
                } else if avgBrowY > 0.42 {
                    emotionScore -= 1.0
                    detailLog.append("😠 Cejas abajo (score: -1.0)")
                }
            }
        }
        
        // 3. Analizar ojos (muy abiertos = sorprendido/feliz)
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftEyePoints = leftEye.normalizedPoints
            let rightEyePoints = rightEye.normalizedPoints
            
            if leftEyePoints.count >= 4 && rightEyePoints.count >= 4 {
                // Calcular apertura de ojos
                let leftTop = leftEyePoints.min(by: { $0.y < $1.y })?.y ?? 0
                let leftBottom = leftEyePoints.max(by: { $0.y < $1.y })?.y ?? 0
                let rightTop = rightEyePoints.min(by: { $0.y < $1.y })?.y ?? 0
                let rightBottom = rightEyePoints.max(by: { $0.y < $1.y })?.y ?? 0
                
                let leftEyeHeight = abs(leftBottom - leftTop)
                let rightEyeHeight = abs(rightBottom - rightTop)
                let avgEyeHeight = (leftEyeHeight + rightEyeHeight) / 2
                
                // Ojos bien abiertos = positivo
                if avgEyeHeight > 0.015 {
                    emotionScore += 0.5
                    detailLog.append("👀 Ojos abiertos (score: +0.5)")
                } else if avgEyeHeight < 0.008 {
                    emotionScore -= 0.3
                    detailLog.append("😑 Ojos cerrados (score: -0.3)")
                }
            }
        }
        
        // Log detallado
        print("📊 Análisis facial:")
        detailLog.forEach { print("  \($0)") }
        print("  Score total: \(emotionScore)")
        
        // Mapear score a emoción con umbrales más sensibles
        let detectedEmotion: String
        switch emotionScore {
        case 2...:
            detectedEmotion = "Feliz"
        case 0.5..<2:
            detectedEmotion = "Neutral"
        case ..<(-1.5):
            detectedEmotion = "Triste"
        default:
            detectedEmotion = "Neutral"
        }
        
        print("  ✨ Emoción detectada: \(detectedEmotion)")
        return detectedEmotion
    }
    
    // MARK: - Heuristic Detection (Fallback)
    
    /// Detección simple basada en brillo promedio
    /// NOTA: Método básico, reemplazar con ML real
    func detectWithHeuristic(_ image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "Neutral" }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return "Neutral"
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return "Neutral" }
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        var totalBrightness: Int = 0
        let sampleStep = max(1, (width * height) / 5000)
        
        for i in stride(from: 0, to: width * height, by: sampleStep) {
            let pixelIndex = i * 4
            let r = Int(pointer[pixelIndex])
            let g = Int(pointer[pixelIndex + 1])
            let b = Int(pointer[pixelIndex + 2])
            totalBrightness += (r + g + b) / 3
        }
        
        let averageBrightness = totalBrightness / max(1, (width * height) / sampleStep)
        
        // Mapeo simple: brillo alto = feliz, bajo = triste
        switch averageBrightness {
        case 170...: return "Feliz"
        case ..<80: return "Triste"
        default: return "Neutral"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Mapea nombre de emoción en inglés a español
    private func mapEmotionToSpanish(_ emotion: String) -> String {
        let mapping: [String: String] = [
            "happy": "Feliz",
            "sad": "Triste",
            "angry": "Enojado",
            "surprised": "Sorprendido",
            "neutral": "Neutral",
            "fear": "Asustado",
            "disgust": "Disgustado"
        ]
        
        return mapping[emotion.lowercased()] ?? "Neutral"
    }
    
    // MARK: - Errors
    
    enum EmotionError: LocalizedError {
        case modelNotFound
        case invalidImage
        case noResults
        case notImplemented
        
        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Modelo CoreML no encontrado. Agrega el modelo al proyecto."
            case .invalidImage:
                return "Imagen inválida"
            case .noResults:
                return "No se pudo clasificar la emoción"
            case .notImplemented:
                return "Método no implementado. Usa detección con Vision o heurística."
            }
        }
    }
}

// MARK: - Integration Example

/*
 CÓMO USAR EN HomeView:
 
 1. Crear instancia del servicio:
    private let emotionService = EmotionDetectionService()
 
 2. Reemplazar función detectEmotion:
    private func detectEmotion(from image: UIImage) async -> String {
        do {
            return try await emotionService.detectEmotion(from: image)
        } catch {
            print("Error detectando emoción: \(error)")
            return "Neutral"
        }
    }
 
 3. Actualizar onChange de capturedImage:
    .onChange(of: capturedImage) { _, newImage in
        Task {
            guard let img = newImage else { return }
            let emotion = await detectEmotion(from: img)
            await MainActor.run {
                detectedEmotion = emotion
                onCapture(img, emotion)
            }
        }
    }
*/

// MARK: - Create ML Training Guide

/*
 ENTRENAR MODELO PROPIO CON CREATE ML:
 
 1. Recolectar Dataset:
    - Descargar FER-2013 o AffectNet
    - Organizar en carpetas por emoción:
      Dataset/
        ├── Feliz/
        ├── Triste/
        ├── Enojado/
        ├── Sorprendido/
        ├── Neutral/
        └── ...
 
 2. Abrir Create ML:
    - Xcode → Open Developer Tool → Create ML
    - New Document → Image Classification
 
 3. Configurar:
    - Training Data: Seleccionar carpeta Dataset
    - Validation: 20%
    - Augmentation: Habilitar (flip, rotate, crop)
    - Algorithm: Transfer Learning con SqueezeNet o MobileNet
 
 4. Entrenar:
    - Presionar Train
    - Esperar ~30-60 min (depende de tamaño)
    - Verificar accuracy > 70%
 
 5. Exportar:
    - Output → EmotionClassifier.mlmodel
    - Arrastrar a proyecto Xcode
 
 6. Generar código:
    - Xcode auto-genera clase EmotionClassifier
    - Usar en detectWithCoreML()
*/

// MARK: - Pre-trained Models (Alternativas)

/*
 MODELOS PRE-ENTRENADOS DISPONIBLES:
 
 1. Apple's Vision Framework (Face Landmarks)
    - ✅ Incluido en iOS - NO requiere modelo custom
    - Detecta características faciales (boca, cejas, ojos)
    - Analiza geometría facial para inferir emociones
    - Limitado a inferencias básicas (no es clasificación directa)
    
 2. FER+ (Microsoft)
    - Modelo open-source de clasificación de emociones
    - Convertir de ONNX a CoreML con coremltools
    - 7 categorías de emociones
    
 3. DeepFace
    - Modelo robusto para reconocimiento facial
    - Requiere conversión a CoreML
    
 4. Entrenar modelo custom con Create ML
    - Usar dataset FER-2013 o AffectNet
    - Transfer learning con MobileNet/SqueezeNet
    - Export como .mlmodel
    
 CONVERSIÓN ONNX → CoreML:
 
 # Python script
 import coremltools as ct
 
 model = ct.converters.onnx.convert(
     model='emotion_model.onnx',
     minimum_ios_deployment_target='15.0'
 )
 
 model.save('EmotionClassifier.mlmodel')
 
 NOTA IMPORTANTE:
 El método actual (detectWithVisionFaceDetection) usa VNDetectFaceLandmarksRequest
 que está disponible en iOS sin necesidad de modelo custom. Analiza la geometría
 facial (posición de boca, cejas, ojos) para inferir emociones básicas.
 
 Para mejor precisión, entrena un modelo custom con Create ML.
*/
