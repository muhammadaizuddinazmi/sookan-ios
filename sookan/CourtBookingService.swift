import Foundation

struct CourtListing: Identifiable, Equatable {
    let id: UUID
    let managerEmail: String
    let venueName: String
    let courtName: String
    let address: String
    let sport: String
}

struct CourtTimeSlot: Identifiable, Equatable {
    let id: UUID
    let courtID: UUID
    let startsAt: Date
    let endsAt: Date
    var bookedByEmail: String?
    var bookedByName: String?
    var bookedAt: Date?

    var isAvailable: Bool { bookedByEmail == nil }
}

enum CourtBookingError: LocalizedError, Equatable {
    case managersOnly
    case playersOnly
    case invalidListing
    case listingNotFound
    case notListingManager
    case invalidAvailability
    case overlappingAvailability
    case slotNotFound
    case slotUnavailable

    var errorDescription: String? {
        switch self {
        case .managersOnly:
            "Only court/field managers can list a venue or add availability."
        case .playersOnly:
            "Only player accounts can book a court."
        case .invalidListing:
            "Enter a venue, court/field name, address, and sport."
        case .listingNotFound:
            "This court listing is no longer available."
        case .notListingManager:
            "Only the manager who listed this court can update its availability."
        case .invalidAvailability:
            "Choose a future start time and a valid booking duration."
        case .overlappingAvailability:
            "This time overlaps an existing availability on this court."
        case .slotNotFound:
            "This time slot is no longer available."
        case .slotUnavailable:
            "This time slot has already been booked."
        }
    }
}

@MainActor
protocol CourtBookingServicing {
    func listings() -> [CourtListing]
    func listings(managedBy email: String) -> [CourtListing]
    func slots(for courtID: UUID) -> [CourtTimeSlot]
    func addListing(
        manager: SookanUserProfile,
        venueName: String,
        courtName: String,
        address: String,
        sport: String
    ) throws
    func addAvailability(
        for courtID: UUID,
        as managerEmail: String,
        startsAt: Date,
        durationMinutes: Int
    ) throws
    func book(slotID: UUID, by player: SookanUserProfile) throws
}

@MainActor
final class MockCourtBookingService: CourtBookingServicing {
    private var storedListings: [CourtListing] = []
    private var storedSlots: [CourtTimeSlot] = []

    func listings() -> [CourtListing] {
        storedListings
    }

    func listings(managedBy email: String) -> [CourtListing] {
        storedListings.filter { $0.managerEmail == email }
    }

    func slots(for courtID: UUID) -> [CourtTimeSlot] {
        storedSlots
            .filter { $0.courtID == courtID }
            .sorted { $0.startsAt < $1.startsAt }
    }

    func addListing(
        manager: SookanUserProfile,
        venueName: String,
        courtName: String,
        address: String,
        sport: String
    ) throws {
        guard manager.role == .venueManager else {
            throw CourtBookingError.managersOnly
        }

        let venueName = venueName.trimmingCharacters(in: .whitespacesAndNewlines)
        let courtName = courtName.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let sport = sport.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !venueName.isEmpty, !courtName.isEmpty, !address.isEmpty, !sport.isEmpty else {
            throw CourtBookingError.invalidListing
        }

        storedListings.append(
            CourtListing(
                id: UUID(),
                managerEmail: manager.email,
                venueName: venueName,
                courtName: courtName,
                address: address,
                sport: sport
            )
        )
    }

    func addAvailability(
        for courtID: UUID,
        as managerEmail: String,
        startsAt: Date,
        durationMinutes: Int
    ) throws {
        guard let listing = storedListings.first(where: { $0.id == courtID }) else {
            throw CourtBookingError.listingNotFound
        }
        guard listing.managerEmail == managerEmail else {
            throw CourtBookingError.notListingManager
        }
        guard startsAt > Date(), (30...240).contains(durationMinutes) else {
            throw CourtBookingError.invalidAvailability
        }

        let endsAt = startsAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let overlapsExistingSlot = storedSlots.contains {
            $0.courtID == courtID && startsAt < $0.endsAt && endsAt > $0.startsAt
        }
        guard !overlapsExistingSlot else {
            throw CourtBookingError.overlappingAvailability
        }

        storedSlots.append(
            CourtTimeSlot(
                id: UUID(),
                courtID: courtID,
                startsAt: startsAt,
                endsAt: endsAt
            )
        )
    }

    func book(slotID: UUID, by player: SookanUserProfile) throws {
        guard player.role == .player else {
            throw CourtBookingError.playersOnly
        }
        guard let index = storedSlots.firstIndex(where: { $0.id == slotID }) else {
            throw CourtBookingError.slotNotFound
        }
        guard storedSlots[index].isAvailable, storedSlots[index].startsAt > Date() else {
            throw CourtBookingError.slotUnavailable
        }

        storedSlots[index].bookedByEmail = player.email
        storedSlots[index].bookedByName = player.displayName
        storedSlots[index].bookedAt = Date()
    }
}
