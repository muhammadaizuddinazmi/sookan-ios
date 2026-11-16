import Foundation

enum GameInvitationStatus: String, Equatable {
    case pending
    case accepted
    case declined
    case cancelled
}

struct GameInvitation: Identifiable, Equatable {
    let id: UUID
    let senderEmail: String
    let senderName: String
    let recipientEmail: String
    let recipientName: String
    let sport: String
    let scheduledAt: Date
    let venue: String
    let createdAt: Date
    var status: GameInvitationStatus
    var cancelledByEmail: String? = nil
    var cancelledAt: Date? = nil
}

func upcomingAcceptedGames(
    _ invitations: [GameInvitation],
    now: Date = Date()
) -> [GameInvitation] {
    invitations
        .filter { $0.status == .accepted && $0.scheduledAt > now }
        .sorted { $0.scheduledAt < $1.scheduledAt }
}

func gamesToShowOnHome(
    _ invitations: [GameInvitation],
    now: Date = Date(),
    calendar: Calendar = .current
) -> [GameInvitation] {
    let upcomingGames = upcomingAcceptedGames(invitations, now: now)
    let gamesToday = upcomingGames.filter {
        calendar.isDate($0.scheduledAt, inSameDayAs: now)
    }

    if gamesToday.count > 1 {
        return gamesToday
    }
    return Array(upcomingGames.prefix(1))
}

enum GameInvitationError: LocalizedError, Equatable {
    case usersNotConnected
    case cannotInviteYourself
    case invalidDate
    case missingVenue
    case invitationAlreadyPending
    case invitationNotFound
    case notInvitationRecipient
    case notInvitationParticipant
    case invitationNotAccepted
    case invitationAlreadyResolved

    var errorDescription: String? {
        switch self {
        case .usersNotConnected:
            "You can invite players after you connect."
        case .cannotInviteYourself:
            "You can't invite yourself to a game."
        case .invalidDate:
            "Choose a future date and time for the game."
        case .missingVenue:
            "Enter a venue so the other player knows where to meet."
        case .invitationAlreadyPending:
            "You already have a pending game invitation for this player."
        case .invitationNotFound:
            "This game invitation is no longer available."
        case .notInvitationRecipient:
            "Only the invited player can respond to this invitation."
        case .notInvitationParticipant:
            "Only a player in this game can cancel it."
        case .invitationNotAccepted:
            "Only accepted games can be cancelled."
        case .invitationAlreadyResolved:
            "This game invitation has already been resolved."
        }
    }
}

protocol GameInvitationServicing {
    func invitations(for email: String) -> [GameInvitation]
    func status(from senderEmail: String, to recipientEmail: String) -> GameInvitationStatus?
    func sendInvitation(
        from sender: SookanUserProfile,
        to recipientEmail: String,
        recipientName: String,
        sport: String,
        scheduledAt: Date,
        venue: String
    ) throws
    func respond(to invitationID: UUID, as recipientEmail: String, accept: Bool) throws
    func cancelInvitation(_ invitationID: UUID, as participantEmail: String) throws
}

final class MockGameInvitationService: GameInvitationServicing {
    private let connectionService: any ConnectionServicing
    private var storedInvitations: [GameInvitation] = []

    init(connectionService: any ConnectionServicing) {
        self.connectionService = connectionService
    }

    func seedDemoAcceptedInvitations(
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        guard storedInvitations.isEmpty else {
            return
        }

        let todayStart = calendar.startOfDay(for: now)
        guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) else {
            return
        }

        let remainingToday = tomorrowStart.timeIntervalSince(now)
        let todayOffsets: [TimeInterval]
        if remainingToday > 15 * 60 {
            todayOffsets = [5, 10, 15].map { TimeInterval($0 * 60) }
        } else {
            todayOffsets = [0.25, 0.5, 0.75].map { remainingToday * $0 }
        }

        let demos: [
            (
                recipientEmail: String,
                recipientName: String,
                sport: String,
                venue: String,
                dayOffset: Int?
            )
        ] = [
            ("daniel@sookan.app", "Daniel T.", "Badminton", "Sookan Arena", nil),
            ("farah@sookan.app", "Farah Z.", "Tennis", "Kuala Lumpur Sports Hall", nil),
            ("daniel@sookan.app", "Daniel T.", "Badminton", "Green Court Center", nil),
            ("farah@sookan.app", "Farah Z.", "Football", "City Sports Park", 1),
            ("daniel@sookan.app", "Daniel T.", "Badminton", "Ampang Court", 3),
            ("farah@sookan.app", "Farah Z.", "Tennis", "KL Sports Hub", 5),
            ("daniel@sookan.app", "Daniel T.", "Running", "PJ Community Field", 7),
            ("farah@sookan.app", "Farah Z.", "Badminton", "Victory Badminton Hall", 10),
            ("daniel@sookan.app", "Daniel T.", "Tennis", "Bukit Jalil Sports Complex", 14),
            ("farah@sookan.app", "Farah Z.", "Badminton", "Sookan Sports Center", 21)
        ]

        storedInvitations = demos.enumerated().map { index, demo in
            let scheduledAt: Date
            if let dayOffset = demo.dayOffset {
                scheduledAt = calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: now
                ) ?? now.addingTimeInterval(TimeInterval(dayOffset * 24 * 60 * 60))
            } else {
                scheduledAt = now.addingTimeInterval(todayOffsets[index])
            }

            return GameInvitation(
                id: UUID(),
                senderEmail: "demo@sookan.app",
                senderName: "Demo Player",
                recipientEmail: demo.recipientEmail,
                recipientName: demo.recipientName,
                sport: demo.sport,
                scheduledAt: scheduledAt,
                venue: demo.venue,
                createdAt: now.addingTimeInterval(TimeInterval(-index)),
                status: .accepted
            )
        }
    }

    func invitations(for email: String) -> [GameInvitation] {
        storedInvitations
            .filter { $0.senderEmail == email || $0.recipientEmail == email }
            .sorted { ($0.cancelledAt ?? $0.createdAt) > ($1.cancelledAt ?? $1.createdAt) }
    }

    func status(from senderEmail: String, to recipientEmail: String) -> GameInvitationStatus? {
        storedInvitations.last {
            $0.senderEmail == senderEmail && $0.recipientEmail == recipientEmail
        }?.status
    }

    func sendInvitation(
        from sender: SookanUserProfile,
        to recipientEmail: String,
        recipientName: String,
        sport: String,
        scheduledAt: Date,
        venue: String
    ) throws {
        guard sender.email != recipientEmail else {
            throw GameInvitationError.cannotInviteYourself
        }
        guard connectionService.areConnected(sender.email, recipientEmail) else {
            throw GameInvitationError.usersNotConnected
        }
        guard scheduledAt > Date() else {
            throw GameInvitationError.invalidDate
        }
        let venue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !venue.isEmpty else {
            throw GameInvitationError.missingVenue
        }
        guard status(from: sender.email, to: recipientEmail) != .pending else {
            throw GameInvitationError.invitationAlreadyPending
        }

        storedInvitations.append(
            GameInvitation(
                id: UUID(),
                senderEmail: sender.email,
                senderName: sender.displayName,
                recipientEmail: recipientEmail,
                recipientName: recipientName,
                sport: sport,
                scheduledAt: scheduledAt,
                venue: venue,
                createdAt: Date(),
                status: .pending
            )
        )
    }

    func respond(to invitationID: UUID, as recipientEmail: String, accept: Bool) throws {
        guard let index = storedInvitations.firstIndex(where: { $0.id == invitationID }) else {
            throw GameInvitationError.invitationNotFound
        }
        guard storedInvitations[index].recipientEmail == recipientEmail else {
            throw GameInvitationError.notInvitationRecipient
        }
        guard storedInvitations[index].status == .pending else {
            throw GameInvitationError.invitationAlreadyResolved
        }

        storedInvitations[index].status = accept ? .accepted : .declined
    }

    func cancelInvitation(_ invitationID: UUID, as participantEmail: String) throws {
        guard let index = storedInvitations.firstIndex(where: { $0.id == invitationID }) else {
            throw GameInvitationError.invitationNotFound
        }

        let invitation = storedInvitations[index]
        guard invitation.senderEmail == participantEmail
                || invitation.recipientEmail == participantEmail else {
            throw GameInvitationError.notInvitationParticipant
        }
        guard invitation.status != .cancelled else {
            throw GameInvitationError.invitationAlreadyResolved
        }
        guard invitation.status == .accepted else {
            throw GameInvitationError.invitationNotAccepted
        }

        storedInvitations[index].status = .cancelled
        storedInvitations[index].cancelledByEmail = participantEmail
        storedInvitations[index].cancelledAt = Date()
    }
}
