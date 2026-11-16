import SwiftUI

struct ConnectionRequestsView: View {
    @Environment(\.dismiss) private var dismiss

    let currentUser: SookanUserProfile
    let connectionService: any ConnectionServicing
    let gameInvitationService: any GameInvitationServicing

    @State private var requests: [ConnectionRequest] = []
    @State private var gameInvitations: [GameInvitation] = []
    @State private var errorMessage: String?
    @State private var invitationToCancel: GameInvitation?
    @State private var isCancellationConfirmationPresented = false

    private var incomingRequests: [ConnectionRequest] {
        requests.filter { $0.recipientEmail == currentUser.email }
    }

    private var outgoingRequests: [ConnectionRequest] {
        requests.filter { $0.senderEmail == currentUser.email }
    }

    private var incomingGameInvitations: [GameInvitation] {
        gameInvitations.filter { $0.recipientEmail == currentUser.email }
    }

    private var outgoingGameInvitations: [GameInvitation] {
        gameInvitations.filter { $0.senderEmail == currentUser.email }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    introduction

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    requestSection(
                        title: "Connection requests · Incoming",
                        emptyMessage: "No incoming requests yet.",
                        items: incomingRequests,
                        isIncoming: true
                    )

                    requestSection(
                        title: "Connection requests · Sent",
                        emptyMessage: "You haven't sent any requests yet.",
                        items: outgoingRequests,
                        isIncoming: false
                    )

                    gameInvitationSection(
                        title: "Game invitations · Incoming",
                        emptyMessage: "No game invitations yet.",
                        items: incomingGameInvitations,
                        isIncoming: true
                    )

                    gameInvitationSection(
                        title: "Game invitations · Sent",
                        emptyMessage: "You haven't invited anyone to a game yet.",
                        items: outgoingGameInvitations,
                        isIncoming: false
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshRequests)
        .confirmationDialog(
            "Cancel this game?",
            isPresented: $isCancellationConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Cancel game", role: .destructive, action: cancelSelectedInvitation)
                .accessibilityIdentifier("confirmGameInvitationCancellation")
            Button("Keep game", role: .cancel) {}
        } message: {
            Text("The other player will see a cancellation notice in Notifications.")
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

            Text("NOTIFICATIONS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(SookanStyle.green)

            Spacer()

            Image(systemName: "person.2")
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

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stay in the loop.")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .tracking(-1)
                .foregroundStyle(SookanStyle.ink)

            Text("Connection requests and game invitations will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(SookanStyle.muted)
        }
    }

    private func requestSection(
        title: String,
        emptyMessage: String,
        items: [ConnectionRequest],
        isIncoming: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title, count: items.count)

            if items.isEmpty {
                emptyState(emptyMessage)
            } else {
                ForEach(items) { request in
                    requestCard(request, isIncoming: isIncoming)
                }
            }
        }
    }

    private func gameInvitationSection(
        title: String,
        emptyMessage: String,
        items: [GameInvitation],
        isIncoming: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title, count: items.count)

            if items.isEmpty {
                emptyState(emptyMessage)
            } else {
                ForEach(items) { invitation in
                    gameInvitationCard(invitation, isIncoming: isIncoming)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SookanStyle.green)
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(SookanStyle.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private func requestCard(
        _ request: ConnectionRequest,
        isIncoming: Bool
    ) -> some View {
        let displayName = isIncoming ? request.senderName : request.recipientName
        let email = isIncoming ? request.senderEmail : request.recipientEmail

        return HStack(spacing: 12) {
            Text(initials(for: displayName))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)
                .frame(width: 44, height: 44)
                .background(SookanStyle.lime.opacity(0.55), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SookanStyle.ink)
                Text(email)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(statusDescription(request.status, isIncoming: isIncoming))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(SookanStyle.green)
            }

            Spacer(minLength: 4)

            if isIncoming && request.status == .pending {
                VStack(spacing: 6) {
                    Button {
                        respond(to: request, accept: true)
                    } label: {
                        Text("Accept")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SookanStyle.ink)
                            .padding(.horizontal, 11)
                            .frame(height: 30)
                            .background(SookanStyle.lime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("acceptConnectionRequest")

                    Button {
                        respond(to: request, accept: false)
                    } label: {
                        Text("Decline")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(SookanStyle.muted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("declineConnectionRequest")
                }
            } else {
                Image(systemName: request.status == .accepted ? "checkmark.circle.fill" : "clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(request.status == .accepted ? SookanStyle.green : SookanStyle.muted)
            }
        }
        .padding(13)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.75), lineWidth: 1)
        }
    }

    private func gameInvitationCard(
        _ invitation: GameInvitation,
        isIncoming: Bool
    ) -> some View {
        let displayName = isIncoming ? invitation.senderName : invitation.recipientName
        let email = isIncoming ? invitation.senderEmail : invitation.recipientEmail

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Text(initials(for: displayName))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(SookanStyle.ink)
                    .frame(width: 42, height: 42)
                    .background(SookanStyle.lime.opacity(0.55), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                    Text(email)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SookanStyle.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 4)

                Text(gameInvitationStatus(invitation, isIncoming: isIncoming))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(
                        invitation.status == .cancelled
                            ? Color(red: 0.72, green: 0.25, blue: 0.19)
                            : SookanStyle.green
                    )
            }

            Label(invitation.sport, systemImage: "sportscourt")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SookanStyle.ink)

            Label(
                invitation.scheduledAt.formatted(date: .abbreviated, time: .shortened),
                systemImage: "calendar"
            )
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(SookanStyle.muted)

            Label(invitation.venue, systemImage: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
                .fixedSize(horizontal: false, vertical: true)

            if isIncoming && invitation.status == .pending {
                HStack(spacing: 9) {
                    Button {
                        respond(to: invitation, accept: true)
                    } label: {
                        Text("Accept game")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SookanStyle.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(SookanStyle.lime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("acceptGameInvitation")

                    Button {
                        respond(to: invitation, accept: false)
                    } label: {
                        Text("Decline")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SookanStyle.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(SookanStyle.canvas, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("declineGameInvitation")
                }
            }

            if invitation.status == .accepted {
                Button {
                    invitationToCancel = invitation
                    isCancellationConfirmationPresented = true
                } label: {
                    Label("Cancel game", systemImage: "xmark.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(SookanStyle.canvas, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cancelGameInvitation-\(invitation.id)")
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.75), lineWidth: 1)
        }
    }

    private func statusDescription(
        _ status: ConnectionRequestStatus,
        isIncoming: Bool
    ) -> String {
        return switch status {
        case .pending:
            isIncoming ? "Wants to connect with you" : "Waiting for a response"
        case .accepted:
            "Connected"
        case .declined:
            isIncoming ? "Request declined" : "Request not accepted"
        }
    }

    private func gameInvitationStatus(
        _ invitation: GameInvitation,
        isIncoming: Bool
    ) -> String {
        return switch invitation.status {
        case .pending:
            isIncoming ? "Needs your response" : "Waiting for response"
        case .accepted:
            "Accepted"
        case .declined:
            "Declined"
        case .cancelled:
            invitation.cancelledByEmail == currentUser.email
                ? "Cancelled by you"
                : "Cancelled by \(isIncoming ? invitation.senderName : invitation.recipientName)"
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    private func respond(to request: ConnectionRequest, accept: Bool) {
        errorMessage = nil
        do {
            try connectionService.respond(
                to: request.id,
                as: currentUser.email,
                accept: accept
            )
            refreshRequests()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't update this request."
        } catch {
            errorMessage = "Couldn't update this request."
        }
    }

    private func respond(to invitation: GameInvitation, accept: Bool) {
        errorMessage = nil
        do {
            try gameInvitationService.respond(
                to: invitation.id,
                as: currentUser.email,
                accept: accept
            )
            refreshRequests()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't update this game invitation."
        } catch {
            errorMessage = "Couldn't update this game invitation."
        }
    }

    private func cancelSelectedInvitation() {
        guard let invitationToCancel else {
            return
        }

        errorMessage = nil
        do {
            try gameInvitationService.cancelInvitation(
                invitationToCancel.id,
                as: currentUser.email
            )
            self.invitationToCancel = nil
            refreshRequests()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't cancel this game."
        } catch {
            errorMessage = "Couldn't cancel this game."
        }
    }

    private func refreshRequests() {
        requests = connectionService.requests(for: currentUser.email)
        gameInvitations = gameInvitationService.invitations(for: currentUser.email)
    }
}
