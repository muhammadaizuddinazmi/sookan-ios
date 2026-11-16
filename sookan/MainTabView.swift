import SwiftUI

struct MainTabView: View {
    let authService: any AuthServicing
    let connectionService: any ConnectionServicing
    let gameInvitationService: any GameInvitationServicing
    let courtBookingService: any CourtBookingServicing
    let locationService: LocationService
    let onProfileUpdated: (SookanUserProfile) -> Void
    let onLocationTap: () -> Void
    let onSignOut: () -> Void

    @State private var profile: SookanUserProfile
    @State private var selectedTab: MainTab = .home
    @State private var homePath = NavigationPath()
    @State private var activityPath = NavigationPath()
    @State private var explorePath = NavigationPath()
    @State private var chatPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    init(
        profile: SookanUserProfile,
        authService: any AuthServicing,
        connectionService: any ConnectionServicing,
        gameInvitationService: any GameInvitationServicing,
        courtBookingService: any CourtBookingServicing,
        locationService: LocationService,
        onProfileUpdated: @escaping (SookanUserProfile) -> Void,
        onLocationTap: @escaping () -> Void,
        onSignOut: @escaping () -> Void
    ) {
        self.authService = authService
        self.connectionService = connectionService
        self.gameInvitationService = gameInvitationService
        self.courtBookingService = courtBookingService
        self.locationService = locationService
        self.onProfileUpdated = onProfileUpdated
        self.onLocationTap = onLocationTap
        self.onSignOut = onSignOut
        _profile = State(initialValue: profile)
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $homePath) {
                homeScreen
            }
            .opacity(selectedTab == .home ? 1 : 0)
            .allowsHitTesting(selectedTab == .home)
            .accessibilityHidden(selectedTab != .home)

            NavigationStack(path: $activityPath) {
                ActivityView(
                    currentUser: profile,
                    connectionService: connectionService,
                    gameInvitationService: gameInvitationService,
                    courtBookingService: courtBookingService,
                    isActive: selectedTab == .activity
                )
            }
            .opacity(selectedTab == .activity ? 1 : 0)
            .allowsHitTesting(selectedTab == .activity)
            .accessibilityHidden(selectedTab != .activity)

            NavigationStack(path: $explorePath) {
                ExploreTabScreen(
                    profile: profile,
                    connectionService: connectionService,
                    gameInvitationService: gameInvitationService,
                    courtBookingService: courtBookingService,
                    onHomeSelected: { selectTab(.home) }
                )
            }
            .opacity(selectedTab == .explore ? 1 : 0)
            .allowsHitTesting(selectedTab == .explore)
            .accessibilityHidden(selectedTab != .explore)

            NavigationStack(path: $chatPath) {
                ChatTabScreen()
            }
            .opacity(selectedTab == .chat ? 1 : 0)
            .allowsHitTesting(selectedTab == .chat)
            .accessibilityHidden(selectedTab != .chat)

            NavigationStack(path: $profilePath) {
                ProfileSettingsView(
                    profile: profile,
                    authService: authService,
                    onProfileUpdated: updateProfile,
                    onSignOut: onSignOut
                )
            }
            .opacity(selectedTab == .profile ? 1 : 0)
            .allowsHitTesting(selectedTab == .profile)
            .accessibilityHidden(selectedTab != .profile)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(.clear)
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .tint(SookanStyle.green)
    }

    @ViewBuilder
    private var homeScreen: some View {
        if profile.role == .venueManager {
            VenueManagerDashboardView(
                profile: profile,
                bookingService: courtBookingService,
                isActive: selectedTab == .home
            )
        } else {
            PlayerHomeTabScreen(
                profile: profile,
                connectionService: connectionService,
                gameInvitationService: gameInvitationService,
                isActive: selectedTab == .home,
                locationService: locationService,
                onLocationTap: onLocationTap
            )
        }
    }

    private func updateProfile(_ updatedProfile: SookanUserProfile) {
        profile = updatedProfile
        onProfileUpdated(updatedProfile)
    }

    private func selectTab(_ tab: MainTab) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
    }
}

private struct PlayerHomeTabScreen: View {
    let profile: SookanUserProfile
    let connectionService: any ConnectionServicing
    let gameInvitationService: any GameInvitationServicing
    let isActive: Bool
    @ObservedObject var locationService: LocationService
    let onLocationTap: () -> Void

    @State private var acceptedGames: [GameInvitation] = []
    @State private var isShowingAllAcceptedGames = false
    @State private var gameToCancel: GameInvitation?
    @State private var isCancellationConfirmationPresented = false
    @State private var cancellationError: String?

    private var compactAcceptedGames: [GameInvitation] {
        gamesToShowOnHome(acceptedGames)
    }

    private var displayedAcceptedGames: [GameInvitation] {
        isShowingAllAcceptedGames ? acceptedGames : compactAcceptedGames
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                header
                introduction
                locationInformation
                upcomingGames
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshAcceptedGames)
        .onChange(of: isActive) { _, isActive in
            if isActive {
                refreshAcceptedGames()
            }
        }
        .confirmationDialog(
            "Cancel this game?",
            isPresented: $isCancellationConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Cancel game", role: .destructive, action: cancelSelectedGame)
                .accessibilityIdentifier("confirmHomeGameCancellation")
            Button("Keep game", role: .cancel) {}
        } message: {
            Text("The other player will see a cancellation notice in Notifications.")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(SookanStyle.green)
                    .frame(width: 42, height: 42)
                Text("s")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(SookanStyle.lime)
                    .offset(y: -1)
            }

            Text("sookan")
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)

            Spacer()

            NavigationLink {
                ConnectionRequestsView(
                    currentUser: profile,
                    connectionService: connectionService,
                    gameInvitationService: gameInvitationService
                )
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SookanStyle.green)
                    .frame(width: 42, height: 42)
                    .background(.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
            .accessibilityIdentifier("homeNotifications")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Hi, \(profile.displayName)!")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(SookanStyle.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityIdentifier("profileGreeting")

            Text("Find a game, meet your people, and get out to play.")
                .font(.system(size: 14))
                .foregroundStyle(SookanStyle.muted)
        }
        .padding(.top, 5)
    }

    private var locationInformation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onLocationTap) {
                HStack(spacing: 8) {
                    Image(systemName: locationService.isLoading ? "location.circle" : "location.fill")
                        .font(.system(size: 12, weight: .bold))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(locationService.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(0.6)
                        Text(locationService.subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .tracking(0)
                    }
                    .lineLimit(1)

                    Spacer(minLength: 0)

                    if locationService.isLoading {
                        ProgressView().controlSize(.mini)
                    }
                }
                .foregroundStyle(SookanStyle.green)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("locationPermissionButton")
            .accessibilityHint("Allow Sookan to use your location while the app is in use")

            if let errorMessage = locationService.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var upcomingGames: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                sectionHeading(
                    isShowingAllAcceptedGames
                        ? "Upcoming games"
                        : compactAcceptedGames.count > 1
                            ? "Today's games"
                            : "Your next game"
                )
                Spacer()
                if acceptedGames.count > compactAcceptedGames.count {
                    Button(isShowingAllAcceptedGames ? "Show less" : "View all") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingAllAcceptedGames.toggle()
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SookanStyle.green)
                    .accessibilityIdentifier(
                        isShowingAllAcceptedGames
                            ? "showFewerAcceptedGames"
                            : "viewAllAcceptedGames"
                    )
                }
            }

            if let cancellationError {
                Label(cancellationError, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if acceptedGames.isEmpty {
                Text("Accepted game invitations will appear here.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(displayedAcceptedGames) { game in
                    acceptedGameCard(game)
                }
            }
        }
    }

    private func acceptedGameCard(_ game: GameInvitation) -> some View {
        let opponent = game.senderEmail == profile.email ? game.recipientName : game.senderName
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(game.sport, systemImage: "sportscourt")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SookanStyle.ink)
                Spacer()
                Text("CONFIRMED")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(SookanStyle.green)
            }
            Label(
                game.scheduledAt.formatted(date: .abbreviated, time: .shortened),
                systemImage: "calendar"
            )
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(SookanStyle.muted)
            Label(game.venue, systemImage: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
            Text("Playing with \(opponent)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SookanStyle.green)

            Button {
                gameToCancel = game
                isCancellationConfirmationPresented = true
            } label: {
                Label("Cancel game", systemImage: "xmark.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("cancelHomeGame-\(game.id)")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 17))
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(SookanStyle.ink)
    }

    private func refreshAcceptedGames() {
        acceptedGames = upcomingAcceptedGames(
            gameInvitationService.invitations(for: profile.email)
        )
        if acceptedGames.count <= gamesToShowOnHome(acceptedGames).count {
            isShowingAllAcceptedGames = false
        }
    }

    private func cancelSelectedGame() {
        guard let gameToCancel else {
            return
        }

        cancellationError = nil
        do {
            try gameInvitationService.cancelInvitation(gameToCancel.id, as: profile.email)
            self.gameToCancel = nil
            refreshAcceptedGames()
        } catch let error as LocalizedError {
            cancellationError = error.errorDescription ?? "Couldn't cancel this game."
        } catch {
            cancellationError = "Couldn't cancel this game."
        }
    }
}

private struct ExploreTabScreen: View {
    let profile: SookanUserProfile
    let connectionService: any ConnectionServicing
    let gameInvitationService: any GameInvitationServicing
    let courtBookingService: any CourtBookingServicing
    let onHomeSelected: () -> Void

    @State private var selectedSport = "Badminton"

    private let sports = [
        ("Badminton", "🏸"),
        ("Tennis", "🎾"),
        ("Football", "⚽️"),
        ("Running", "🏃")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(profile.role == .player ? "Explore and play." : "Your Sookan network.")
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .foregroundStyle(SookanStyle.ink)
                    Text(
                        profile.role == .player
                            ? "Find the right people and the right place to play."
                            : "Manage your listings from the Home tab."
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(SookanStyle.muted)
                }

                if profile.role == .player {
                    sportPicker

                    NavigationLink {
                        HomeView(
                            sport: selectedSport,
                            currentUser: profile,
                            connectionService: connectionService,
                            gameInvitationService: gameInvitationService
                        )
                    } label: {
                        exploreCard(
                            icon: "person.2.fill",
                            title: "Find players",
                            detail: "Discover partners by sport and level"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("explorePlayers")

                    NavigationLink {
                        CourtBookingBrowseView(
                            player: profile,
                            bookingService: courtBookingService
                        )
                    } label: {
                        exploreCard(
                            icon: "sportscourt",
                            title: "Book a court",
                            detail: "Browse published courts and available times"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exploreCourts")
                } else {
                    Button(action: onHomeSelected) {
                        exploreCard(
                            icon: "building.2.fill",
                            title: "Manage your courts",
                            detail: "Return to your listings and availability"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sportPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your sport")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(sports, id: \.0) { sport, emoji in
                        let isSelected = selectedSport == sport
                        Button {
                            selectedSport = sport
                        } label: {
                            HStack(spacing: 6) {
                                Text(emoji)
                                Text(sport)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(isSelected ? .white : SookanStyle.ink)
                            .padding(.horizontal, 13)
                            .frame(height: 39)
                            .background(
                                isSelected ? SookanStyle.green : .white,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("exploreSport-\(sport)")
                    }
                }
            }
        }
    }

    private func exploreCard(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SookanStyle.green)
                .frame(width: 44, height: 44)
                .background(SookanStyle.lime.opacity(0.4), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SookanStyle.ink)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
            }

            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SookanStyle.green)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct ChatTabScreen: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(SookanStyle.green)
                .frame(width: 76, height: 76)
                .background(SookanStyle.lime.opacity(0.35), in: Circle())

            Text("Chat is coming soon")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)

            Text("Once you connect with players, you’ll be able to plan your next game here.")
                .font(.system(size: 14))
                .foregroundStyle(SookanStyle.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 290)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(SookanStyle.canvas.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}
