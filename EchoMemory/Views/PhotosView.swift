import SwiftUI

// MARK: - Mood Model (use app's EmotionalEntry.Mood)
extension EmotionalEntry.Mood: Identifiable {
    public var id: String { rawValue }

    var uiEmoji: String {
        switch self {
        case .great: return "😊"
        case .neutral: return "😌"
        case .sad: return "😔"
        }
    }

    var uiColor: Color {
        switch self {
        case .great: return Color.echoTeal
        case .neutral: return Color.echoAmber
        case .sad: return Color.echoPurple
        }
    }
}

struct PhotosView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: PhotoFilter = .week
    @State private var selectedMemory: PhotoMemory? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showSaveMemorySheet = false

    enum PhotoFilter: String, CaseIterable {
        case day = "Día"
        case week = "Semana"
    }

    var filteredPhotos: [PhotoMemory] {
        switch selectedFilter {
        case .day:
            return appState.photoMemories.filter { Calendar.current.isDateInToday($0.date) }
        case .week:
            return appState.photoMemories
        }
    }

    var body: some View {
        NavigationStack {
            ZStack{
                Color.echoCream
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    
                    // MARK: - Header
                    HStack(alignment: .top) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Diario Digital")
                                .font(.echoTitle)
                                .foregroundColor(Color.echoTextPrimary)
                            
                            Text("Tus recuerdos")
                                .font(.echoSubheadline)
                                .foregroundColor(Color.echoTextSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.echoTeal.opacity(0.12))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.echoTeal)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 16)
                    
                    // MARK: - Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PhotoFilter.allCases, id: \.self) { filter in
                                FilterPill(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                    
                    // MARK: - Content
                    ScrollView(showsIndicators: false) {
                        if filteredPhotos.isEmpty {
                            EmptyPhotosState()
                                .padding(.top, 60)
                        } else {
                            PhotoGrid(photos: filteredPhotos, selectedMemory: $selectedMemory)
                                .padding(.horizontal, 20)
                        }
                        Spacer(minLength: 30)
                    }
                }
            }
            
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            
            
            .sheet(item: $selectedMemory) { memory in
                PhotoDetailSheet(memory: memory)
            }
            
            .sheet(isPresented: $showSaveMemorySheet) {
                if let image = selectedImage {
                    SimpleMemorySaveSheet(
                        image: image,
                        onSave: { location, relatedPerson, emoji in
                            saveMemory(image: image, location: location, relatedPerson: relatedPerson, emoji: emoji)
                            showSaveMemorySheet = false
                            selectedImage = nil
                        },
                        onCancel: {
                            showSaveMemorySheet = false
                            selectedImage = nil
                        }
                    )
                }
            }
            
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    showSaveMemorySheet = true
                    
                }
                
            }
        }
    }
    // MARK: - Save Memory (sin análisis de emoción)
    
    private func saveMemory(image: UIImage, location: String?, relatedPerson: String?, emoji: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        
        guard let squareImage = image.croppedToSquare(),
              let savedImageName = ImageStorageService.shared.saveImage(squareImage) else {
            print("Error: No se pudo guardar la imagen")
            return
        }
        
        let newMemory = PhotoMemory(
            date: Date(),
            time: timeString,
            imageName: savedImageName,
            emoji: emoji,
            location: location,
            relatedPerson: relatedPerson,
            mood: .great
        )
        
        withAnimation {
            appState.photoMemories.insert(newMemory, at: 0)
        }
        
    
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// MARK: - Simple Memory Save Sheet (sin análisis de emoción)
struct SimpleMemorySaveSheet: View {
    let image: UIImage
    let onSave: (String?, String?, String) -> Void
    let onCancel: () -> Void
    
    @State private var location: String = ""
    @State private var relatedPerson: String = ""
    @State private var selectedEmoji: String = "😊"
    
    let availableEmojis = ["😊", "❤️", "🎉", "🌸", "☀️", "🌈", "🎂", "🏡", "🌳", "📚", "🎨", "🎵"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    VStack(spacing: 16) {
            
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Selecciona un emoji")
                                    .font(.echoCaption)
                                    .foregroundColor(Color.echoTextSecondary)
                                Spacer()
                                Text(selectedEmoji)
                                    .font(.system(size: 28))
                            }
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                                ForEach(availableEmojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 32))
                                            .frame(width: 50, height: 50)
                                            .background(
                                                selectedEmoji == emoji 
                                                ? Color.echoTeal.opacity(0.2)
                                                : Color.white
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedEmoji == emoji
                                                        ? Color.echoTeal
                                                        : Color.echoTextMuted.opacity(0.2),
                                                        lineWidth: selectedEmoji == emoji ? 2 : 1
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(Color.echoTeal)
                                Text("Ubicación (opcional)")
                                    .font(.echoCaption)
                                    .foregroundColor(Color.echoTextSecondary)
                            }
                            
                            TextField("Ej: Casa, Jardín, Parque...", text: $location)
                                .font(.echoBody)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.echoTeal.opacity(0.2), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(Color.echoCoral)
                                Text("Con quién (opcional)")
                                    .font(.echoCaption)
                                    .foregroundColor(Color.echoTextSecondary)
                            }
                            
                            TextField("Ej: Mi hija, Amigos, Familia...", text: $relatedPerson)
                                .font(.echoBody)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.echoTeal.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                    HStack(spacing: 12) {
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancelar")
                                .font(.echoBody)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.echoTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.echoTextMuted.opacity(0.1))
                                .cornerRadius(14)
                        }
                        
                        Button {
                            let loc = location.isEmpty ? nil : location
                            let person = relatedPerson.isEmpty ? nil : relatedPerson
                            onSave(loc, person, selectedEmoji)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                Text("Guardar Recuerdo")
                            }
                            .font(.echoBody)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.echoTeal)
                            .cornerRadius(14)
                            .shadow(color: Color.echoTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.echoCream.ignoresSafeArea())
            .navigationTitle("Nuevo Recuerdo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Photo Grid
struct PhotoGrid: View {
    let photos: [PhotoMemory]
    @Binding var selectedMemory: PhotoMemory?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(photos) { photo in
                PhotoThumbnail(photo: photo)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4)) {
                            selectedMemory = photo
                        }
                    }
            }
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let photo: PhotoMemory
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
 
            Group {
                if photo.imageName.starts(with: "http"), let url = URL(string: photo.imageName) {
                
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16).fill(photoBackground)
                    }
                } else if let savedImage = photo.savedImage {
          
                    Image(uiImage: savedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                
                    RoundedRectangle(cornerRadius: 16)
                        .fill(photoBackground)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.85))
                        )
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()

            HStack(spacing: 4) {
                Text(photo.time)
                    .font(.echoSmall)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                Spacer()
                Text(photo.emoji)
                    .font(.system(size: 14))
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.echoTextPrimary.opacity(0.1), radius: 6, x: 0, y: 3)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double.random(in: 0...0.3))) {
                appeared = true
            }
        }
    }

    var photoBackground: LinearGradient {
        switch photo.mood {
        case .great:
            return LinearGradient(colors: [Color.echoTeal, Color.echoMint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neutral:
            return LinearGradient(colors: [Color.echoAmber, Color.echoCoral.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sad:
            return LinearGradient(colors: [Color.echoPurple, Color.echoBlue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Photo Detail Sheet
struct PhotoDetailSheet: View {
    let memory: PhotoMemory
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.echoTextMuted.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Large photo
            ZStack {
                if memory.imageName.starts(with: "http"), let url = URL(string: memory.imageName) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                } else if let savedImage = memory.savedImage {
                  
                    Image(uiImage: savedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.echoTeal, Color.echoBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 260)
                    Image(systemName: memory.imageName)
                        .font(.system(size: 72))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 20)

      
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memory.time)
                            .font(.echoHeadline)
                            .foregroundColor(Color.echoTextPrimary)
                        if let loc = memory.location {
                            Label(loc, systemImage: "mappin.circle.fill")
                                .font(.echoCaption)
                                .foregroundColor(Color.echoTextSecondary)
                        }
                    }
                    Spacer()
                    Text(memory.emoji)
                        .font(.system(size: 40))
                }

                if let person = memory.relatedPerson {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color.echoCoral)
                        Text("Con \(person)")
                            .font(.echoBody)
                            .foregroundColor(Color.echoTextPrimary)
                    }
                    .padding(12)
                    .background(Color(hex: "#FFF0F0"))
                    .cornerRadius(12)
                }

     
                HStack {
                    Image(systemName: "face.smiling")
                    Text("Te sentiste: \(memory.mood.uiEmoji) \(memory.mood.rawValue)")
                        .font(.echoCaption)
                }
                .foregroundColor(memory.mood.uiColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(memory.mood.uiColor.opacity(0.1))
                .cornerRadius(20)

    
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.echoAmber)
                        Text("Consejo del día")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextPrimary)
                    }
                    Text(advice(for: memory.mood))
                        .font(.echoCaption)
                        .foregroundColor(Color.echoTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .background(Color.echoTextMuted.opacity(0.08))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.echoCream.ignoresSafeArea())
    }

    private func advice(for mood: EmotionalEntry.Mood) -> String {
        switch mood {
        case .great:
            return "Aprovecha tu energía: escribe tres cosas por las que te sientes agradecido hoy."
        case .neutral:
            return "Regálate un respiro: 3 inhalaciones profundas pueden cambiar tu día."
        case .sad:
            return "Sé amable contigo: manda un mensaje a alguien de confianza o sal a dar un paseo corto."
        }
    }
}


// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.echoCaption)
                .foregroundColor(isSelected ? .white : Color.echoTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.echoAmber : Color.white)
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.echoTeal.opacity(0.3) : Color.clear, radius: 6)
        }
    }
}

// MARK: - Empty State
struct EmptyPhotosState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.echoTextMuted.opacity(0.5))
            Text("No hay fotos de hoy")
                .font(.echoSubheadline)
                .foregroundColor(Color.echoTextSecondary)
            Text("Toca el botón de cámara para agregar tu primer recuerdo del día")
                .font(.echoCaption)
                .foregroundColor(Color.echoTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Activities View

struct ActivitiesView: View {
    let mood: EmotionalEntry.Mood
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(titleForMood(mood))
                    .font(.echoHeadline)
                    .foregroundColor(Color.echoTextPrimary)
                    .padding(.top, 20)

                ForEach(activities(for: mood), id: \.title) { activity in
                    ActivityCard(title: activity.title, subtitle: activity.subtitle, icon: activity.icon, color: mood.uiColor)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color.echoCream.ignoresSafeArea())
        .navigationTitle("Actividades")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func titleForMood(_ mood: EmotionalEntry.Mood) -> String {
        switch mood {
        case .great: return "¡Potencia tu buena vibra! ✨"
        case .neutral: return "Mantén tu calma 🧘"
        case .sad: return "Pequeños pasos para sentirte mejor 💜"
        }
    }

    private func activities(for mood: EmotionalEntry.Mood) -> [(title: String, subtitle: String, icon: String)] {
        switch mood {
        case .great:
            return [
                ("Lista de gratitud", "Escribe 3 cosas que te alegran hoy", "list.bullet"),
                ("Captura tu momento", "Toma una foto que represente tu alegría", "camera.fill"),
                ("Comparte una sonrisa", "Envía un mensaje positivo a alguien", "message.fill")
            ]
        case .neutral:
            return [
                ("3 respiraciones profundas", "Inhala 3s, retén 3s, exhala 3s", "wind"),
                ("Estiramiento suave", "Libera tensión con 2 minutos de estiramientos", "figure.cooldown"),
                ("Journaling breve", "Escribe una frase sobre cómo te sientes", "pencil")
            ]
        case .sad:
            return [
                ("Conecta con alguien", "Escribe a un amigo o familiar", "person.2.fill"),
                ("Paseo corto", "5-10 minutos al aire libre", "figure.walk.motion"),
                ("Mini meditación", "2 minutos de respiración consciente", "sparkles")
            ]
        }
    }
}

struct ActivityCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(12)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.echoBody)
                    .foregroundColor(Color.echoTextPrimary)
                Text(subtitle)
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.echoTextPrimary.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

extension UIImage {
    func croppedToSquare() -> UIImage? {
        let originalWidth  = size.width
        let originalHeight = size.height
        
        let sideLength = min(originalWidth, originalHeight)
        
        let xOffset = (originalWidth - sideLength) / 2.0
        let yOffset = (originalHeight - sideLength) / 2.0
        
        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}
