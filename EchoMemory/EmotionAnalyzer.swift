import UIKit

class EmotionAnalyzer {

    static func analyze(image: UIImage, completion: @escaping (String) -> Void) {

        // MVP SIMULADO (suficiente para hackathon)
        let emotions = ["Feliz", "Tranquilo", "Acompañado", "Neutro"]

        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let result = emotions.randomElement()!
            completion(result)
        }
    }
}
