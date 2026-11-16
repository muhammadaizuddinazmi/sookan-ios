import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case home
    case activity
    case explore
    case chat
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .activity: "Activity"
        case .explore: "Explore"
        case .chat: "Chat"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .activity: "clock.arrow.circlepath"
        case .explore: "map.fill"
        case .chat: "message.fill"
        case .profile: "person.crop.circle"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    private let selectedColor = Color(red: 57.0 / 255.0, green: 184.0 / 255.0, blue: 0)
    private let unselectedColor = Color(red: 153.0 / 255.0, green: 153.0 / 255.0, blue: 153.0 / 255.0)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    guard selectedTab != tab else {
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 19, weight: .semibold))
                            .frame(height: 22)
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? selectedColor : unselectedColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityIdentifier("tab-\(tab.rawValue)")
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(.white, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 5)
    }
}
