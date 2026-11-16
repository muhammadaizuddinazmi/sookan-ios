import SwiftUI

private struct PlayerProfile: Identifiable {
    let id: String
    let email: String
    let name: String
    let initials: String
    let level: String
    let distance: String
    let availability: String
    let color: Color
}

struct HomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedLevel = "All levels"
    @State private var connectionStatuses: [String: ConnectionRequestStatus] = [:]
    @State private var invitationStatuses: [String: GameInvitationStatus] = [:]
    @State private var connectionError: String?
    @State private var invitationRecipient: PlayerProfile?

    let sport: String
    let locationName: String?
    let currentUser: SookanUserProfile
    let connectionService: any ConnectionServicing
    let gameInvitationService: any GameInvitationServicing

    init(
        sport: String = "Badminton",
        locationName: String? = nil,
        currentUser: SookanUserProfile = MockAuthService.demoAccounts[0],
        connectionService: any ConnectionServicing = MockConnectionService(),
        gameInvitationService: (any GameInvitationServicing)? = nil
    ) {
        self.sport = sport
        self.locationName = locationName
        self.currentUser = currentUser
        self.connectionService = connectionService
        self.gameInvitationService = gameInvitationService
            ?? MockGameInvitationService(connectionService: connectionService)
    }

    private let levels = ["All levels", "Beginner", "Intermediate", "Advanced"]
    private let players = [
        PlayerProfile(
            id: "aina@sookan.app",
            email: "aina@sookan.app",
            name: "Aina N.",
            initials: "AN",
            level: "Intermediate",
            distance: "0.8 km",
            availability: "Free this evening",
            color: Color(red: 0.95, green: 0.75, blue: 0.57)
        ),
        PlayerProfile(
            id: "daniel@sookan.app",
            email: "daniel@sookan.app",
            name: "Daniel T.",
            initials: "DT",
            level: "Beginner",
            distance: "1.4 km",
            availability: "Available today",
            color: Color(red: 0.66, green: 0.81, blue: 0.75)
        ),
        PlayerProfile(
            id: "farah@sookan.app",
            email: "farah@sookan.app",
            name: "Farah Z.",
            initials: "FZ",
            level: "Advanced",
            distance: "2.1 km",
            availability: "Usually plays weekends",
            color: Color(red: 0.85, green: 0.75, blue: 0.91)
        )
    ]

    private var filteredPlayers: [PlayerProfile] {
        players.filter { player in
            guard player.email != currentUser.email else {
                return false
            }
            let matchesLevel = selectedLevel == "All levels" || player.level == selectedLevel
            let matchesSearch = searchText.isEmpty
                || player.name.localizedCaseInsensitiveContains(searchText)
                || player.distance.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }

    private var sportEmoji: String {
        switch sport {
        case "Badminton": "🏸"
        case "Tennis": "🎾"
        case "Football": "⚽️"
        case "Running": "🏃"
        default: "🏅"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    searchBar
                    levelFilters
                    playerResults
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshConnectionStatuses)
        .sheet(item: $invitationRecipient) { player in
            GameInvitationComposer(
                currentUser: currentUser,
                recipientEmail: player.email,
                recipientName: player.name,
                sport: sport,
                invitationService: gameInvitationService,
                onInvitationSent: refreshInvitationStatuses
            )
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SookanStyle.ink)
                    .frame(width: 42, height: 42)
                    .background(.white, in: Circle())
            }
            .accessibilityLabel("Go back")

            Spacer()

            Text("DISCOVER")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(SookanStyle.green)

            Spacer()

            Image(systemName: "map")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SookanStyle.ink)
                .frame(width: 42, height: 42)
                .background(.white, in: Circle())
                .accessibilityLabel("Map")
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(sportEmoji)  \(sport.uppercased()) · \(locationName?.uppercased() ?? "LOCATION NOT SET")")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(SookanStyle.green)
                .accessibilityIdentifier("discoverySport")

            Text("Sample profiles; distances are demo values.")
                .font(.system(size: 14))
                .foregroundStyle(SookanStyle.muted)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SookanStyle.green)
            TextField("Search players or distance", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(SookanStyle.ink)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 15)
        .frame(height: 50)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.8), lineWidth: 1)
        }
    }

    private var levelFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(levels, id: \.self) { level in
                    let isSelected = selectedLevel == level
                    Button {
                        selectedLevel = level
                    } label: {
                        Text(level)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : SookanStyle.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 35)
                            .background(
                                isSelected ? SookanStyle.green : .white,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule().stroke(
                                    isSelected ? .clear : SookanStyle.line,
                                    lineWidth: 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var playerResults: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Players nearby")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(SookanStyle.ink)
                Spacer()
                Text("\(filteredPlayers.count) found")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SookanStyle.muted)
            }

            if filteredPlayers.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)
            } else {
                if let connectionError {
                    Label(connectionError, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(filteredPlayers) { player in
                    playerCard(player)
                }
            }
        }
    }

    private func playerCard(_ player: PlayerProfile) -> some View {
        let status = connectionStatuses[player.email]
        let invitationStatus = invitationStatuses[player.email]
        let actionTitle = playerActionTitle(connectionStatus: status, invitationStatus: invitationStatus)
        let isActionDisabled = actionIsDisabled(
            connectionStatus: status,
            invitationStatus: invitationStatus
        )
        return HStack(spacing: 12) {
            Text(player.initials)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)
                .frame(width: 48, height: 48)
                .background(player.color, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(player.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                    Circle()
                        .fill(SookanStyle.green)
                        .frame(width: 5, height: 5)
                    Text(player.distance)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SookanStyle.muted)
                }

                Text("\(player.level) · \(player.availability)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)

                HStack(spacing: 5) {
                    Image(systemName: "figure.badminton")
                        .font(.system(size: 10, weight: .semibold))
                    Text(sport)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(SookanStyle.green)
            }

            Spacer(minLength: 4)

            Button {
                if status == .accepted {
                    invitationRecipient = player
                } else {
                    sendConnectionRequest(to: player)
                }
            } label: {
                Text(actionTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isActionDisabled ? SookanStyle.green : .white)
                    .padding(.horizontal, 12)
                    .frame(height: 33)
                    .background(
                        isActionDisabled ? SookanStyle.lime : SookanStyle.green,
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
            .disabled(isActionDisabled)
            .accessibilityIdentifier("connect-\(player.email)")
        }
        .padding(13)
        .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.75), lineWidth: 1)
        }
    }

    private func playerActionTitle(
        connectionStatus: ConnectionRequestStatus?,
        invitationStatus: GameInvitationStatus?
    ) -> String {
        return switch connectionStatus {
        case .pending:
            "Connection sent"
        case .accepted:
            switch invitationStatus {
            case .pending:
                "Invite sent"
            case .accepted:
                "Game set"
            case .declined, .cancelled, .none:
                "Invite"
            }
        case .declined, .none:
            "Connect"
        }
    }

    private func actionIsDisabled(
        connectionStatus: ConnectionRequestStatus?,
        invitationStatus: GameInvitationStatus?
    ) -> Bool {
        return switch connectionStatus {
        case .pending:
            true
        case .accepted:
            invitationStatus == .pending || invitationStatus == .accepted
        case .declined, .none:
            false
        }
    }

    private func sendConnectionRequest(to player: PlayerProfile) {
        connectionError = nil
        do {
            try connectionService.sendRequest(
                from: currentUser,
                to: player.email,
                recipientName: player.name
            )
            refreshConnectionStatuses()
        } catch let error as LocalizedError {
            connectionError = error.errorDescription ?? "Couldn't send the connection request."
        } catch {
            connectionError = "Couldn't send the connection request."
        }
    }

    private func refreshConnectionStatuses() {
        connectionStatuses = [:]
        invitationStatuses = [:]
        for player in players {
            if let status = connectionService.status(from: currentUser.email, to: player.email) {
                connectionStatuses[player.email] = status
            }
            if let status = gameInvitationService.status(
                from: currentUser.email,
                to: player.email
            ) {
                invitationStatuses[player.email] = status
            }
        }
    }

    private func refreshInvitationStatuses() {
        for player in players {
            if let status = gameInvitationService.status(
                from: currentUser.email,
                to: player.email
            ) {
                invitationStatuses[player.email] = status
            } else {
                invitationStatuses.removeValue(forKey: player.email)
            }
        }
    }
}

#Preview {
    HomeView()
}
