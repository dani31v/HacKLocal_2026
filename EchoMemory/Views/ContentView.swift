import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color.echoCream, Color.echoSoftPeach.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Tab content
            Group {
                switch appState.selectedTab {
                case .home:
                    HomeView()
                        .transition(.opacity)
                case .photos:
                    PhotosView()
                        .transition(.opacity)
                case .messages:
                    MessagesView()
                        .transition(.opacity)
                case .history:
                    HistoryView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appState.selectedTab)
            .padding(.bottom, 84)

            // Custom Tab Bar
            EchoTabBar()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar
struct EchoTabBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                TabBarItem(tab: tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.white.opacity(0.95)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .shadow(color: Color.echoTextPrimary.opacity(0.08), radius: 20, x: 0, y: -4)
        )
    }
}

struct TabBarItem: View {
    @EnvironmentObject var appState: AppState
    let tab: AppState.Tab
    var isSelected: Bool { appState.selectedTab == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.echoTeal.opacity(0.15))
                            .frame(width: 48, height: 48)
                    }

                    // Special mic button
                    if tab == .messages {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.echoTeal : Color.echoCream)
                                .frame(width: 54, height: 54)
                                .shadow(color: Color.echoTeal.opacity(0.3), radius: 8)
                            Image(systemName: tab.rawValue)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(isSelected ? .white : Color.echoTextSecondary)
                        }
                        .offset(y: -10)
                    } else {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color.echoTeal : Color.echoTextMuted)
                    }
                }

                if tab != .messages {
                    Text(tab.label)
                        .font(.echoSmall)
                        .foregroundColor(isSelected ? Color.echoTeal : Color.echoTextMuted)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
