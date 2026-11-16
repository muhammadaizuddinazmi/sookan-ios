import SwiftUI

struct GameInvitationComposer: View {
    @Environment(\.dismiss) private var dismiss

    let currentUser: SookanUserProfile
    let recipientEmail: String
    let recipientName: String
    let sport: String
    let invitationService: any GameInvitationServicing
    let onInvitationSent: () -> Void

    @State private var scheduledAt = Calendar.current.date(
        byAdding: .day,
        value: 1,
        to: Date()
    ) ?? Date().addingTimeInterval(60 * 60 * 24)
    @State private var venue = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite \(recipientName)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(SookanStyle.ink)
                        Text("Suggest a time and place for your \(sport.lowercased()) game.")
                            .font(.system(size: 14))
                            .foregroundStyle(SookanStyle.muted)
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        fieldLabel("DATE & TIME")
                        DatePicker(
                            "Game date and time",
                            selection: $scheduledAt,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15))
                        .accessibilityIdentifier("gameInvitationDatePicker")
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        fieldLabel("VENUE")
                        TextField("e.g. KL Sports Hub", text: $venue)
                            .font(.system(size: 15))
                            .foregroundStyle(SookanStyle.ink)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 15)
                            .frame(height: 52)
                            .background(.white, in: RoundedRectangle(cornerRadius: 15))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(SookanStyle.line, lineWidth: 1)
                            }
                            .accessibilityIdentifier("gameInvitationVenueField")
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: sendInvitation) {
                        Text("Send game invitation")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SookanStyle.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SookanStyle.lime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sendGameInvitationButton")
                }
                .padding(22)
            }
            .background(SookanStyle.canvas.ignoresSafeArea())
            .navigationTitle("New invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(SookanStyle.green)
                }
            }
        }
        .tint(SookanStyle.green)
        .presentationDetents([.large])
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(SookanStyle.muted)
    }

    private func sendInvitation() {
        errorMessage = nil
        do {
            try invitationService.sendInvitation(
                from: currentUser,
                to: recipientEmail,
                recipientName: recipientName,
                sport: sport,
                scheduledAt: scheduledAt,
                venue: venue
            )
            onInvitationSent()
            dismiss()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't send this game invitation."
        } catch {
            errorMessage = "Couldn't send this game invitation."
        }
    }
}
