import CoreLocation
import SwiftUI
import UIKit

enum SookanStyle {
    static let ink = Color(red: 0.08, green: 0.16, blue: 0.13)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.45)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.93)
    static let green = Color(red: 0.14, green: 0.37, blue: 0.27)
    static let lime = Color(red: 0.79, green: 0.94, blue: 0.34)
    static let line = Color(red: 0.89, green: 0.91, blue: 0.87)
}

struct ContentView: View {
    @State private var currentUser: SookanUserProfile?
    @StateObject private var locationService = LocationService()
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    private let authService: any AuthServicing
    private let connectionService: any ConnectionServicing
    private let gameInvitationService: any GameInvitationServicing
    private let courtBookingService: any CourtBookingServicing

    init(
        authService: any AuthServicing = MockAuthService(),
        connectionService: any ConnectionServicing = MockConnectionService(),
        gameInvitationService: (any GameInvitationServicing)? = nil,
        courtBookingService: (any CourtBookingServicing)? = nil
    ) {
        self.authService = authService
        self.connectionService = connectionService
        if let gameInvitationService {
            self.gameInvitationService = gameInvitationService
        } else {
            let demoGameInvitationService = MockGameInvitationService(
                connectionService: connectionService
            )
            demoGameInvitationService.seedDemoAcceptedInvitations()
            self.gameInvitationService = demoGameInvitationService
        }
        self.courtBookingService = courtBookingService ?? MockCourtBookingService()
    }

    var body: some View {
        Group {
            if let currentUser {
                MainTabView(
                    profile: currentUser,
                    authService: authService,
                    connectionService: connectionService,
                    gameInvitationService: gameInvitationService,
                    courtBookingService: courtBookingService,
                    locationService: locationService,
                    onProfileUpdated: { self.currentUser = $0 },
                    onLocationTap: handleLocationTap,
                    onSignOut: signOut
                )
            } else {
                AuthenticationView(authService: authService) {
                    currentUser = $0
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                locationService.refreshAuthorizationStatus()
            }
        }
        .tint(SookanStyle.green)
    }

    private func handleLocationTap() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestPermission()
        case .denied, .restricted:
            openAppSettings()
        case .authorizedAlways, .authorizedWhenInUse:
            if locationService.accuracyAuthorization == .reducedAccuracy {
                openAppSettings()
            } else {
                locationService.requestCurrentLocation()
            }
        @unknown default:
            locationService.requestPermission()
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(settingsURL)
    }

    private func signOut() {
        authService.signOut()
        currentUser = nil
    }
}

#Preview {
    ContentView()
}
