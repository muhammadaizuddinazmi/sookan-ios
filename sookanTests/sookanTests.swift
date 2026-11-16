//
//  sookanTests.swift
//  sookanTests
//
//  Created by Muhammad Aizuddin on 07/08/2026.
//

import Foundation
import Testing
@testable import sookan

struct sookanTests {

    @MainActor
    @Test func mockAuthAllowsNewAccountToSignIn() throws {
        let auth = MockAuthService()

        try auth.signUp(email: " Player@Example.com ", password: "play1234")
        try auth.signIn(email: "player@example.com", password: "play1234")
        #expect(auth.currentUser == SookanUserProfile(
            email: "player@example.com",
            displayName: "player@example.com"
        ))

        try auth.updateDisplayName("Aina")
        #expect(auth.currentUser?.displayName == "Aina")

        auth.signOut()
        #expect(auth.currentUser == nil)
        try auth.signIn(email: "player@example.com", password: "play1234")
        #expect(auth.currentUser?.displayName == "Aina")
    }

    @MainActor
    @Test func mockAuthRetainsSelectedAccountRole() throws {
        let auth = MockAuthService()

        try auth.signUp(
            email: "manager@example.com",
            password: "play1234",
            role: .venueManager
        )
        #expect(auth.currentUser?.role == .venueManager)

        auth.signOut()
        try auth.signIn(email: "manager@example.com", password: "play1234")
        #expect(auth.currentUser?.role == .venueManager)
    }

    @MainActor
    @Test func mockAuthRejectsDuplicateAccountsAndIncorrectPasswords() throws {
        let auth = MockAuthService()
        try auth.signUp(email: "player@example.com", password: "play1234")

        #expect(throws: MockAuthError.emailAlreadyRegistered) {
            try auth.signUp(email: "PLAYER@example.com", password: "play1234")
        }
        #expect(throws: MockAuthError.incorrectPassword) {
            try auth.signIn(email: "player@example.com", password: "wrongpass")
        }
    }

    @MainActor
    @Test func mockAuthRejectsInvalidSignUpDetails() {
        let auth = MockAuthService()

        #expect(throws: MockAuthError.invalidEmail) {
            try auth.signUp(email: "not-an-email", password: "play1234")
        }
        #expect(throws: MockAuthError.passwordTooShort) {
            try auth.signUp(email: "player@example.com", password: "short")
        }
    }

    @Test func connectionRequestCanBeAcceptedByRecipient() throws {
        let service = MockConnectionService()
        let sender = SookanUserProfile(
            email: "demo@sookan.app",
            displayName: "Demo player"
        )

        try service.sendRequest(
            from: sender,
            to: "aina@sookan.app",
            recipientName: "Aina N."
        )

        let incoming = service.requests(for: "aina@sookan.app")
        #expect(incoming.count == 1)
        #expect(incoming[0].status == .pending)

        try service.respond(to: incoming[0].id, as: "aina@sookan.app", accept: true)
        #expect(service.status(from: sender.email, to: "aina@sookan.app") == .accepted)
    }

    @Test func connectionRequestCannotBeAcceptedByAnotherUserOrSentTwice() throws {
        let service = MockConnectionService()
        let sender = SookanUserProfile(
            email: "demo@sookan.app",
            displayName: "Demo player"
        )
        try service.sendRequest(
            from: sender,
            to: "aina@sookan.app",
            recipientName: "Aina N."
        )
        let request = try #require(service.requests(for: "aina@sookan.app").first)

        #expect(throws: ConnectionServiceError.notRequestRecipient) {
            try service.respond(to: request.id, as: "farah@sookan.app", accept: true)
        }
        #expect(throws: ConnectionServiceError.requestAlreadyExists) {
            try service.sendRequest(
                from: sender,
                to: "aina@sookan.app",
                recipientName: "Aina N."
            )
        }
    }

    @MainActor
    @Test func connectedUsersCanSendAndAcceptGameInvitations() throws {
        let connectionService = MockConnectionService()
        let sender = SookanUserProfile(
            email: "demo@sookan.app",
            displayName: "Demo player"
        )
        try connectionService.sendRequest(
            from: sender,
            to: "aina@sookan.app",
            recipientName: "Aina N."
        )
        let connectionRequest = try #require(
            connectionService.requests(for: "aina@sookan.app").first
        )
        try connectionService.respond(
            to: connectionRequest.id,
            as: "aina@sookan.app",
            accept: true
        )

        let invitationService = MockGameInvitationService(connectionService: connectionService)
        let scheduledAt = Date().addingTimeInterval(60 * 60 * 24)
        try invitationService.sendInvitation(
            from: sender,
            to: "aina@sookan.app",
            recipientName: "Aina N.",
            sport: "Badminton",
            scheduledAt: scheduledAt,
            venue: "KL Sports Hub"
        )

        let incoming = try #require(
            invitationService.invitations(for: "aina@sookan.app").first
        )
        #expect(incoming.sport == "Badminton")
        #expect(incoming.scheduledAt == scheduledAt)
        #expect(incoming.venue == "KL Sports Hub")
        #expect(incoming.status == .pending)

        try invitationService.respond(
            to: incoming.id,
            as: "aina@sookan.app",
            accept: true
        )
        #expect(
            invitationService.status(
                from: "demo@sookan.app",
                to: "aina@sookan.app"
            ) == .accepted
        )
    }

    @MainActor
    @Test func gameInvitationRequiresConnectionAndVenue() throws {
        let connectionService = MockConnectionService()
        let invitationService = MockGameInvitationService(connectionService: connectionService)
        let sender = SookanUserProfile(
            email: "demo@sookan.app",
            displayName: "Demo player"
        )

        #expect(throws: GameInvitationError.usersNotConnected) {
            try invitationService.sendInvitation(
                from: sender,
                to: "aina@sookan.app",
                recipientName: "Aina N.",
                sport: "Badminton",
                scheduledAt: Date().addingTimeInterval(60 * 60 * 24),
                venue: "KL Sports Hub"
            )
        }

        try connectionService.sendRequest(
            from: sender,
            to: "aina@sookan.app",
            recipientName: "Aina N."
        )
        let request = try #require(
            connectionService.requests(for: "aina@sookan.app").first
        )
        try connectionService.respond(
            to: request.id,
            as: "aina@sookan.app",
            accept: true
        )
        #expect(throws: GameInvitationError.missingVenue) {
            try invitationService.sendInvitation(
                from: sender,
                to: "aina@sookan.app",
                recipientName: "Aina N.",
                sport: "Badminton",
                scheduledAt: Date().addingTimeInterval(60 * 60 * 24),
                venue: "  "
            )
        }
    }

    @MainActor
    @Test func demoInvitationSeedHasTenAcceptedGamesWithThreeToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 11, day: 16, hour: 10)
        )!
        let service = MockGameInvitationService(connectionService: MockConnectionService())
        service.seedDemoAcceptedInvitations(now: now, calendar: calendar)

        let invitations = service.invitations(for: "demo@sookan.app")
        let todaysInvitations = invitations.filter {
            calendar.isDate($0.scheduledAt, inSameDayAs: now)
        }
        let scheduledDays = Set(invitations.map {
            calendar.startOfDay(for: $0.scheduledAt)
        })

        #expect(invitations.count == 10)
        #expect(invitations.allSatisfy { $0.status == .accepted })
        #expect(todaysInvitations.count == 3)
        #expect(todaysInvitations.allSatisfy { $0.scheduledAt > now })
        #expect(scheduledDays.count == 8)
    }

    @MainActor
    @Test func eitherParticipantCanCancelAnAcceptedGameAndOtherUsersSeeIt() throws {
        let service = MockGameInvitationService(connectionService: MockConnectionService())
        service.seedDemoAcceptedInvitations()
        let invitations = service.invitations(for: "demo@sookan.app")
        let senderCancelledGame = try #require(invitations.first)
        let recipientCancelledGame = try #require(invitations.dropFirst().first)

        #expect(throws: GameInvitationError.notInvitationParticipant) {
            try service.cancelInvitation(senderCancelledGame.id, as: "other@sookan.app")
        }

        try service.cancelInvitation(senderCancelledGame.id, as: "demo@sookan.app")
        try service.cancelInvitation(
            recipientCancelledGame.id,
            as: recipientCancelledGame.recipientEmail
        )
        #expect(throws: GameInvitationError.invitationAlreadyResolved) {
            try service.cancelInvitation(senderCancelledGame.id, as: "demo@sookan.app")
        }

        let senderView = try #require(
            service.invitations(for: senderCancelledGame.recipientEmail)
                .first { $0.id == senderCancelledGame.id }
        )
        let recipientView = try #require(
            service.invitations(for: recipientCancelledGame.recipientEmail)
                .first { $0.id == recipientCancelledGame.id }
        )
        #expect(senderView.status == .cancelled)
        #expect(senderView.cancelledByEmail == "demo@sookan.app")
        #expect(senderView.cancelledAt != nil)
        #expect(
            service.invitations(for: senderCancelledGame.recipientEmail).first?.id
                == senderCancelledGame.id
        )
        #expect(recipientView.status == .cancelled)
        #expect(recipientView.cancelledByEmail == recipientCancelledGame.recipientEmail)
    }

    @Test func homeShowsEveryAcceptedGameTodayWhenThereAreSeveral() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let startOfToday = calendar.startOfDay(for: Date())
        let now = calendar.date(byAdding: .hour, value: 1, to: startOfToday)!
        let firstToday = makeInvitation(
            scheduledAt: calendar.date(byAdding: .hour, value: 2, to: startOfToday)!,
            status: .accepted
        )
        let secondToday = makeInvitation(
            scheduledAt: calendar.date(byAdding: .hour, value: 4, to: startOfToday)!,
            status: .accepted
        )
        let tomorrow = makeInvitation(
            scheduledAt: calendar.date(byAdding: .day, value: 1, to: now)!,
            status: .accepted
        )

        let games = gamesToShowOnHome(
            [tomorrow, secondToday, firstToday],
            now: now,
            calendar: calendar
        )

        #expect(games.map(\.id) == [firstToday.id, secondToday.id])
    }

    @Test func homeShowsOnlyTheClosestUpcomingAcceptedGameOtherwise() {
        let now = Date()
        let closestGame = makeInvitation(
            scheduledAt: now.addingTimeInterval(60 * 60 * 24),
            status: .accepted
        )
        let laterGame = makeInvitation(
            scheduledAt: now.addingTimeInterval(60 * 60 * 48),
            status: .accepted
        )
        let pendingGame = makeInvitation(
            scheduledAt: now.addingTimeInterval(60 * 30),
            status: .pending
        )
        let pastGame = makeInvitation(
            scheduledAt: now.addingTimeInterval(-60 * 30),
            status: .accepted
        )

        let games = gamesToShowOnHome([
            laterGame,
            pendingGame,
            pastGame,
            closestGame
        ], now: now)

        #expect(games.map(\.id) == [closestGame.id])
    }

    private func makeInvitation(
        scheduledAt: Date,
        status: GameInvitationStatus
    ) -> GameInvitation {
        GameInvitation(
            id: UUID(),
            senderEmail: "demo@sookan.app",
            senderName: "Demo player",
            recipientEmail: "aina@sookan.app",
            recipientName: "Aina N.",
            sport: "Badminton",
            scheduledAt: scheduledAt,
            venue: "KL Sports Hub",
            createdAt: Date(),
            status: status
        )
    }

    @MainActor
    @Test func managerCanPublishAvailabilityAndPlayerCanBookIt() throws {
        let service = MockCourtBookingService()
        let manager = SookanUserProfile(
            email: "manager@sookan.app",
            displayName: "Court Manager",
            role: .venueManager
        )
        let player = SookanUserProfile(
            email: "demo@sookan.app",
            displayName: "Demo player"
        )

        try service.addListing(
            manager: manager,
            venueName: "KL Sports Hub",
            courtName: "Court 1",
            address: "Kuala Lumpur",
            sport: "Badminton"
        )
        let listing = try #require(service.listings(managedBy: manager.email).first)
        try service.addAvailability(
            for: listing.id,
            as: manager.email,
            startsAt: Date().addingTimeInterval(60 * 60 * 24),
            durationMinutes: 60
        )
        let slot = try #require(service.slots(for: listing.id).first)

        try service.book(slotID: slot.id, by: player)

        let bookedSlot = try #require(service.slots(for: listing.id).first)
        #expect(bookedSlot.isAvailable == false)
        #expect(bookedSlot.bookedByEmail == player.email)
        #expect(bookedSlot.bookedByName == player.displayName)
    }

    @MainActor
    @Test func courtBookingsRejectInvalidRolesAndOverlappingAvailability() throws {
        let service = MockCourtBookingService()
        let player = SookanUserProfile(
            email: "demo@sookan.app",
            displayName: "Demo player"
        )
        let manager = SookanUserProfile(
            email: "manager@sookan.app",
            displayName: "Court Manager",
            role: .venueManager
        )

        #expect(throws: CourtBookingError.managersOnly) {
            try service.addListing(
                manager: player,
                venueName: "KL Sports Hub",
                courtName: "Court 1",
                address: "Kuala Lumpur",
                sport: "Badminton"
            )
        }

        try service.addListing(
            manager: manager,
            venueName: "KL Sports Hub",
            courtName: "Court 1",
            address: "Kuala Lumpur",
            sport: "Badminton"
        )
        let listing = try #require(service.listings(managedBy: manager.email).first)
        let startsAt = Date().addingTimeInterval(60 * 60 * 24)
        try service.addAvailability(
            for: listing.id,
            as: manager.email,
            startsAt: startsAt,
            durationMinutes: 60
        )

        #expect(throws: CourtBookingError.overlappingAvailability) {
            try service.addAvailability(
                for: listing.id,
                as: manager.email,
                startsAt: startsAt.addingTimeInterval(30 * 60),
                durationMinutes: 60
            )
        }
        #expect(service.slots(for: listing.id).count == 1)
    }
}
