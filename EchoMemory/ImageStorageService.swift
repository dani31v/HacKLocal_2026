import UIKit
import Foundation

class ImageStorageService {
    
    static let shared = ImageStorageService()
    
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("SavedImages", isDirectory: true)
    }
    
    private init() {
        createImagesDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createImagesDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Image
    
    func saveImage(_ image: UIImage) -> String? {
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Error guardando imagen: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Image
    
  
    func loadImage(named filename: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // MARK: - Delete Image
    
  
    func deleteImage(named filename: String) {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Get File URL
    
    /// Obtiene la URL completa del archivo de imagen
    func imageURL(for filename: String) -> URL {
        return imagesDirectory.appendingPathComponent(filename)
    }
}

// MARK: - PhotoMemory Extension

extension PhotoMemory {

    var savedImage: UIImage? {

        if imageName.starts(with: "http") {
            return nil
        }
  
        return ImageStorageService.shared.loadImage(named: imageName)
    }
}
