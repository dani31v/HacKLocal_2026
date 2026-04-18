import SwiftUI

struct PhotosView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: PhotoFilter = .day
    @State private var selectedMemory: PhotoMemory? = nil

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
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fotos del Día")
                        .font(.echoHeadline)
                        .foregroundColor(Color.echoTextPrimary)
                    Text("Tus recuerdos de hoy")
                        .font(.echoCaption)
                        .foregroundColor(Color.echoTextSecondary)
                }
                Spacer()
                Button {
                    // ImagePicker would open here
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.echoTeal.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.echoTeal)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)

            // MARK: - Filter Pills
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
                Spacer(minLength: 20)
            }
        }
        .sheet(item: $selectedMemory) { memory in
            PhotoDetailSheet(memory: memory)
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
            // Photo placeholder (replace with actual image)
            Group {
                if photo.imageName.starts(with: "http"), let url = URL(string: photo.imageName) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16).fill(photoBackground)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(photoBackground)
                        .overlay(
                            Image(systemName: photo.imageName)
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.85))
                        )
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()

            // Time + emoji overlay
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
            return LinearGradient(colors: [Color.echoTeal, Color.echoBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
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

            // Info
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

                // Mood tag
                HStack {
                    Image(systemName: "face.smiling")
                    Text("Te sentiste: \(memory.mood.emoji) \(memory.mood.rawValue)")
                        .font(.echoCaption)
                }
                .foregroundColor(memory.mood.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(memory.mood.color.opacity(0.1))
                .cornerRadius(20)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.echoCream.ignoresSafeArea())
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
                .background(isSelected ? Color.echoTeal : Color.white)
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
