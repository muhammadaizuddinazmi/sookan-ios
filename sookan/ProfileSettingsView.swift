import SwiftUI

struct ProfileSettingsView: View {
    let profile: SookanUserProfile
    let authService: any AuthServicing
    let onProfileUpdated: (SookanUserProfile) -> Void
    let onSignOut: () -> Void
    @State private var displayName: String
    @State private var errorMessage: String?

    init(
        profile: SookanUserProfile,
        authService: any AuthServicing,
        onProfileUpdated: @escaping (SookanUserProfile) -> Void,
        onSignOut: @escaping () -> Void = {}
    ) {
        self.profile = profile
        self.authService = authService
        self.onProfileUpdated = onProfileUpdated
        self.onSignOut = onSignOut
        _displayName = State(initialValue: profile.displayName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it yours.")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(SookanStyle.ink)
                    Text("Manage your Sookan account.")
                        .font(.system(size: 14))
                        .foregroundStyle(SookanStyle.muted)
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("DISPLAY NAME")
                    TextField("Your name", text: $displayName)
                        .font(.system(size: 15))
                        .foregroundStyle(SookanStyle.ink)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 15)
                        .frame(height: 52)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(SookanStyle.line, lineWidth: 1)
                        }
                        .accessibilityIdentifier("profileDisplayNameField")
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("EMAIL")
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundStyle(SookanStyle.muted)
                        Text(profile.email)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SookanStyle.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 52)
                    .background(SookanStyle.line.opacity(0.45), in: RoundedRectangle(cornerRadius: 15))
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("ACCOUNT TYPE")
                    HStack(spacing: 10) {
                        Image(systemName: profile.role == .player ? "figure.badminton" : "building.2")
                            .foregroundStyle(SookanStyle.green)
                        Text(profile.role.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SookanStyle.muted)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 52)
                    .background(SookanStyle.line.opacity(0.45), in: RoundedRectangle(cornerRadius: 15))
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: save) {
                    Text("Save changes")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SookanStyle.lime, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("saveProfileButton")

                Button(role: .destructive, action: onSignOut) {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("signOutButton")
            }
            .padding(22)
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: profile.displayName) { _, name in
            displayName = name
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(SookanStyle.muted)
    }

    private func save() {
        do {
            try authService.updateDisplayName(displayName)
            guard let updatedProfile = authService.currentUser else {
                errorMessage = "Unable to load your updated profile. Please try again."
                return
            }
            onProfileUpdated(updatedProfile)
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Something went wrong. Please try again."
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
