import SwiftUI

struct ActivityView: View {
    let currentUser: SookanUserProfile
    let connectionService: any ConnectionServicing
    let gameInvitationService: any GameInvitationServicing
    let courtBookingService: any CourtBookingServicing
    let isActive: Bool

    @State private var connectionRequests: [ConnectionRequest] = []
    @State private var gameInvitations: [GameInvitation] = []
    @State private var courtBookings: [CourtBookingActivity] = []

    private var activities: [ActivityRecord] {
        let connectionRecords = connectionRequests.map(connectionRecord)
        let invitationRecords = gameInvitations.map(invitationRecord)
        let bookingRecords = courtBookings.map(bookingRecord)
        return (connectionRecords + invitationRecords + bookingRecords)
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Your activity")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(SookanStyle.ink)
                        Text("A record of your connection requests and game invitations.")
                            .font(.system(size: 14))
                            .foregroundStyle(SookanStyle.muted)
                    }

                    if activities.isEmpty {
                        Text("Your requests and invitations will appear here.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SookanStyle.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(activities) { activity in
                            activityCard(activity)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshActivities)
        .onChange(of: isActive) { _, isActive in
            if isActive {
                refreshActivities()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Color.clear
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

            Spacer()

            Text("ACTIVITY")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(SookanStyle.green)

            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SookanStyle.ink)
                .frame(width: 42, height: 42)
                .background(.white, in: Circle())
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }

    private func activityCard(_ activity: ActivityRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                Image(systemName: activity.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SookanStyle.green)
                    .frame(width: 42, height: 42)
                    .background(SookanStyle.lime.opacity(0.4), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                    Text(activity.counterparty)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SookanStyle.muted)
                }

                Spacer(minLength: 4)

                Text(activity.status)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(SookanStyle.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(SookanStyle.lime.opacity(0.35), in: Capsule())
            }

            if let sport = activity.sport {
                Label(sport, systemImage: "sportscourt")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SookanStyle.ink)
            }

            if let scheduledAt = activity.scheduledAt {
                Label(
                    scheduledAt.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "calendar"
                )
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
            }

            if let venue = activity.venue {
                Label(venue, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let recordedAt = activity.recordedAt {
                Text(recordedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.75), lineWidth: 1)
        }
    }

    private func connectionRecord(_ request: ConnectionRequest) -> ActivityRecord {
        let isOutgoing = request.senderEmail == currentUser.email
        let counterparty = isOutgoing ? request.recipientName : request.senderName
        let status: String = switch request.status {
        case .pending:
            isOutgoing ? "Pending" : "Needs response"
        case .accepted:
            "Connected"
        case .declined:
            "Declined"
        }

        return ActivityRecord(
            id: "connection-\(request.id)",
            title: isOutgoing ? "Connection request sent" : "Connection request received",
            counterparty: isOutgoing ? "To \(counterparty)" : "From \(counterparty)",
            status: status,
            systemImage: "person.2.fill",
            createdAt: request.createdAt,
            recordedAt: request.createdAt
        )
    }

    private func invitationRecord(_ invitation: GameInvitation) -> ActivityRecord {
        let isOutgoing = invitation.senderEmail == currentUser.email
        let counterparty = isOutgoing ? invitation.recipientName : invitation.senderName
        let status: String = switch invitation.status {
        case .pending:
            isOutgoing ? "Pending" : "Needs response"
        case .accepted:
            "Accepted"
        case .declined:
            "Declined"
        case .cancelled:
            invitation.cancelledByEmail == currentUser.email
                ? "Cancelled by you"
                : "Cancelled by \(counterparty)"
        }

        let recordedAt = invitation.cancelledAt ?? invitation.createdAt
        return ActivityRecord(
            id: "invitation-\(invitation.id)",
            title: isOutgoing ? "Game invitation sent" : "Game invitation received",
            counterparty: isOutgoing ? "To \(counterparty)" : "From \(counterparty)",
            status: status,
            systemImage: "sportscourt",
            createdAt: recordedAt,
            recordedAt: recordedAt,
            sport: invitation.sport,
            scheduledAt: invitation.scheduledAt,
            venue: invitation.venue
        )
    }

    private func bookingRecord(_ booking: CourtBookingActivity) -> ActivityRecord {
        ActivityRecord(
            id: "booking-\(booking.slot.id)",
            title: "Court booked",
            counterparty: booking.listing.courtName,
            status: "Booked",
            systemImage: "sportscourt",
            createdAt: booking.slot.bookedAt ?? booking.slot.startsAt,
            recordedAt: booking.slot.bookedAt,
            sport: booking.listing.sport,
            scheduledAt: booking.slot.startsAt,
            venue: booking.listing.venueName
        )
    }

    private func refreshActivities() {
        connectionRequests = connectionService.requests(for: currentUser.email)
        gameInvitations = gameInvitationService.invitations(for: currentUser.email)
        courtBookings = courtBookingService.listings().flatMap { listing in
            courtBookingService.slots(for: listing.id)
                .filter { $0.bookedByEmail == currentUser.email }
                .map { CourtBookingActivity(listing: listing, slot: $0) }
        }
    }
}

private struct CourtBookingActivity {
    let listing: CourtListing
    let slot: CourtTimeSlot
}

private struct ActivityRecord: Identifiable {
    let id: String
    let title: String
    let counterparty: String
    let status: String
    let systemImage: String
    let createdAt: Date
    var recordedAt: Date?
    var sport: String?
    var scheduledAt: Date?
    var venue: String?
}
