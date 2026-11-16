import Foundation

enum ConnectionRequestStatus: String, Equatable {
    case pending
    case accepted
    case declined
}

struct ConnectionRequest: Identifiable, Equatable {
    let id: UUID
    let senderEmail: String
    let senderName: String
    let recipientEmail: String
    let recipientName: String
    let createdAt: Date
    var status: ConnectionRequestStatus
}

enum ConnectionServiceError: LocalizedError, Equatable {
    case cannotConnectToYourself
    case requestAlreadyExists
    case requestNotFound
    case notRequestRecipient
    case requestAlreadyResolved

    var errorDescription: String? {
        switch self {
        case .cannotConnectToYourself:
            "You can't send a connection request to yourself."
        case .requestAlreadyExists:
            "You already have an active request with this player."
        case .requestNotFound:
            "This connection request is no longer available."
        case .notRequestRecipient:
            "Only the invited player can respond to this request."
        case .requestAlreadyResolved:
            "This connection request has already been resolved."
        }
    }
}

protocol ConnectionServicing {
    func requests(for email: String) -> [ConnectionRequest]
    func status(from senderEmail: String, to recipientEmail: String) -> ConnectionRequestStatus?
    func areConnected(_ firstEmail: String, _ secondEmail: String) -> Bool
    func sendRequest(
        from sender: SookanUserProfile,
        to recipientEmail: String,
        recipientName: String
    ) throws
    func respond(to requestID: UUID, as recipientEmail: String, accept: Bool) throws
}

final class MockConnectionService: ConnectionServicing {
    private var storedRequests: [ConnectionRequest] = []

    func requests(for email: String) -> [ConnectionRequest] {
        storedRequests
            .filter { $0.senderEmail == email || $0.recipientEmail == email }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func status(from senderEmail: String, to recipientEmail: String) -> ConnectionRequestStatus? {
        storedRequests.last {
            $0.senderEmail == senderEmail && $0.recipientEmail == recipientEmail
        }?.status
    }

    func areConnected(_ firstEmail: String, _ secondEmail: String) -> Bool {
        status(from: firstEmail, to: secondEmail) == .accepted
            || status(from: secondEmail, to: firstEmail) == .accepted
    }

    func sendRequest(
        from sender: SookanUserProfile,
        to recipientEmail: String,
        recipientName: String
    ) throws {
        guard sender.email != recipientEmail else {
            throw ConnectionServiceError.cannotConnectToYourself
        }
        if let status = status(from: sender.email, to: recipientEmail),
           status != .declined {
            throw ConnectionServiceError.requestAlreadyExists
        }

        storedRequests.append(
            ConnectionRequest(
                id: UUID(),
                senderEmail: sender.email,
                senderName: sender.displayName,
                recipientEmail: recipientEmail,
                recipientName: recipientName,
                createdAt: Date(),
                status: .pending
            )
        )
    }

    func respond(to requestID: UUID, as recipientEmail: String, accept: Bool) throws {
        guard let index = storedRequests.firstIndex(where: { $0.id == requestID }) else {
            throw ConnectionServiceError.requestNotFound
        }
        guard storedRequests[index].recipientEmail == recipientEmail else {
            throw ConnectionServiceError.notRequestRecipient
        }
        guard storedRequests[index].status == .pending else {
            throw ConnectionServiceError.requestAlreadyResolved
        }

        storedRequests[index].status = accept ? .accepted : .declined
    }
}
