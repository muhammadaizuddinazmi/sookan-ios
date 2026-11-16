import SwiftUI

protocol AuthServicing {
    var currentUser: SookanUserProfile? { get }
    func signIn(email: String, password: String) throws
    func signUp(email: String, password: String, role: SookanUserRole) throws
    func updateDisplayName(_ displayName: String) throws
    func signOut()
}

extension AuthServicing {
    func signUp(email: String, password: String) throws {
        try signUp(email: email, password: password, role: .player)
    }
}

enum SookanUserRole: String, CaseIterable, Identifiable {
    case player
    case venueManager

    var id: String { rawValue }

    var title: String {
        switch self {
        case .player:
            "Player"
        case .venueManager:
            "Court/field manager"
        }
    }

    var description: String {
        switch self {
        case .player:
            "Find players and book available courts."
        case .venueManager:
            "List your venue and manage available times."
        }
    }
}

struct SookanUserProfile: Equatable, Identifiable {
    let email: String
    var displayName: String
    var role: SookanUserRole = .player

    var id: String { email }
}

enum MockAuthError: LocalizedError, Equatable {
    case invalidEmail
    case passwordTooShort
    case emailAlreadyRegistered
    case accountNotFound
    case incorrectPassword
    case notAuthenticated
    case invalidDisplayName

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            "Enter a valid email address."
        case .passwordTooShort:
            "Use a password with at least 8 characters."
        case .emailAlreadyRegistered:
            "That email is already registered. Try signing in."
        case .accountNotFound:
            "No demo account found for that email. Create an account first."
        case .incorrectPassword:
            "That password doesn't match this demo account."
        case .notAuthenticated:
            "Sign in before editing your profile."
        case .invalidDisplayName:
            "Enter a name to show on your profile."
        }
    }
}

final class MockAuthService: AuthServicing {
    static let demoAccounts = [
        SookanUserProfile(email: "demo@sookan.app", displayName: "Demo player"),
        SookanUserProfile(email: "aina@sookan.app", displayName: "Aina N."),
        SookanUserProfile(email: "daniel@sookan.app", displayName: "Daniel T."),
        SookanUserProfile(email: "farah@sookan.app", displayName: "Farah Z."),
        SookanUserProfile(
            email: "manager@sookan.app",
            displayName: "Court Manager",
            role: .venueManager
        )
    ]

    private var accounts = Dictionary(
        uniqueKeysWithValues: MockAuthService.demoAccounts.map { ($0.email, "Play1234") }
    )
    private var displayNames = Dictionary(
        uniqueKeysWithValues: MockAuthService.demoAccounts
            .filter { $0.email != "demo@sookan.app" }
            .map { ($0.email, $0.displayName) }
    )
    private var roles = Dictionary(
        uniqueKeysWithValues: MockAuthService.demoAccounts.map { ($0.email, $0.role) }
    )
    private(set) var currentUser: SookanUserProfile?

    func signIn(email: String, password: String) throws {
        let email = normalized(email)
        guard let savedPassword = accounts[email] else {
            throw MockAuthError.accountNotFound
        }
        guard savedPassword == password else {
            throw MockAuthError.incorrectPassword
        }
        currentUser = SookanUserProfile(
            email: email,
            displayName: displayNames[email] ?? email,
            role: roles[email] ?? .player
        )
    }

    func signUp(email: String, password: String, role: SookanUserRole) throws {
        let email = normalized(email)
        guard email.contains("@"), email.split(separator: "@").count == 2 else {
            throw MockAuthError.invalidEmail
        }
        guard password.count >= 8 else {
            throw MockAuthError.passwordTooShort
        }
        guard accounts[email] == nil else {
            throw MockAuthError.emailAlreadyRegistered
        }
        accounts[email] = password
        roles[email] = role
        currentUser = SookanUserProfile(
            email: email,
            displayName: displayNames[email] ?? email,
            role: role
        )
    }

    func updateDisplayName(_ displayName: String) throws {
        guard let currentUser else {
            throw MockAuthError.notAuthenticated
        }
        let displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayName.isEmpty else {
            throw MockAuthError.invalidDisplayName
        }

        displayNames[currentUser.email] = displayName
        self.currentUser = SookanUserProfile(
            email: currentUser.email,
            displayName: displayName,
            role: currentUser.role
        )
    }

    func signOut() {
        currentUser = nil
    }

    private func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private enum AuthField: Hashable {
    case email
    case password
    case confirmPassword
}

struct AuthenticationView: View {
    let authService: any AuthServicing
    let onAuthenticated: (SookanUserProfile) -> Void

    @State private var isCreatingAccount = false
    @State private var selectedRole: SookanUserRole = .player
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: AuthField?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                brand
                welcome
                authForm
                demoNotice
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 30)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var brand: some View {
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
            Text(
                "\(Text("s").foregroundColor(SookanStyle.green))\(Text("ookan").foregroundColor(SookanStyle.ink))"
            )
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🏸  YOUR PEOPLE ARE OUT THERE")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(SookanStyle.green)

            Text(
                isCreatingAccount
                    ? (selectedRole == .player ? "Join the\nplayers." : "List your\ncourts.")
                    : "Find your next game."
            )
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .tracking(-1.2)
                .lineSpacing(-1)
                .foregroundStyle(SookanStyle.ink)

            Text(
                isCreatingAccount
                    ? selectedRole.description
                    : "Sign in to continue to your player community."
            )
            .font(.system(size: 14))
            .foregroundStyle(SookanStyle.muted)
        }
    }

    private var authForm: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(spacing: 4) {
                authModeButton("Sign in", isSelected: !isCreatingAccount) {
                    switchMode(createAccount: false)
                }
                authModeButton("Create account", isSelected: isCreatingAccount) {
                    switchMode(createAccount: true)
                }
            }
            .padding(4)
            .background(SookanStyle.canvas, in: Capsule())

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("EMAIL")
                TextField("you@example.com", text: $email)
                    .font(.system(size: 15))
                    .foregroundStyle(SookanStyle.ink)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(SookanStyle.canvas, in: RoundedRectangle(cornerRadius: 13))
            }

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("PASSWORD")
                SecureField("At least 8 characters", text: $password)
                    .font(.system(size: 15))
                    .foregroundStyle(SookanStyle.ink)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(isCreatingAccount ? .next : .go)
                    .onSubmit {
                        if isCreatingAccount {
                            focusedField = .confirmPassword
                        } else {
                            submit()
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(SookanStyle.canvas, in: RoundedRectangle(cornerRadius: 13))
            }

            if isCreatingAccount {
                VStack(alignment: .leading, spacing: 9) {
                    fieldLabel("I'M SIGNING UP AS")
                    ForEach(SookanUserRole.allCases) { role in
                        roleOption(role)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel("CONFIRM PASSWORD")
                    SecureField("Re-enter your password", text: $confirmPassword)
                        .font(.system(size: 15))
                        .foregroundStyle(SookanStyle.ink)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit(submit)
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(SookanStyle.canvas, in: RoundedRectangle(cornerRadius: 13))
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("authErrorMessage")
            }

            Button(action: submit) {
                HStack(spacing: 9) {
                    Text(isCreatingAccount ? "Create account" : "Sign in")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(SookanStyle.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(SookanStyle.lime, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("authSubmitButton")
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.7), lineWidth: 1)
        }
    }

    private var demoNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "flask")
                    .font(.system(size: 12, weight: .bold))
                Text("PROTOTYPE MODE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
            }
            .foregroundStyle(SookanStyle.green)

            Text("This demo keeps accounts in memory only. They reset when the app closes. Don’t use a real password.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text("Manager sign-up is open in this prototype. Verify venue ownership before launch.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text("Demo users share the password Play1234:")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(MockAuthService.demoAccounts) { account in
                        let label = account.email == "demo@sookan.app"
                            ? "Try demo account"
                            : account.role == .venueManager
                                ? "Try manager account"
                            : "Try \(account.displayName.split(separator: " ").first ?? "player") account"
                        Button {
                            email = account.email
                            password = "Play1234"
                            isCreatingAccount = false
                            errorMessage = nil
                        } label: {
                            Text(label)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SookanStyle.green)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(demoButtonIdentifier(for: account))
                    }
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SookanStyle.lime.opacity(0.2), in: RoundedRectangle(cornerRadius: 17))
    }

    private func authModeButton(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? SookanStyle.ink : SookanStyle.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if isSelected {
                        Capsule().fill(.white)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func roleOption(_ role: SookanUserRole) -> some View {
        let isSelected = selectedRole == role
        return Button {
            selectedRole = role
        } label: {
            HStack(spacing: 10) {
                Image(systemName: role == .player ? "figure.badminton" : "building.2")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SookanStyle.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(role.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                    Text(role.description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SookanStyle.muted)
                }

                Spacer()

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? SookanStyle.green : SookanStyle.line)
            }
            .padding(12)
            .background(
                isSelected ? SookanStyle.lime.opacity(0.2) : SookanStyle.canvas,
                in: RoundedRectangle(cornerRadius: 13)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isSelected ? SookanStyle.green : SookanStyle.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("signupRole-\(role.rawValue)")
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(SookanStyle.muted)
    }

    private func switchMode(createAccount: Bool) {
        isCreatingAccount = createAccount
        errorMessage = nil
        confirmPassword = ""
    }

    private func demoButtonIdentifier(for account: SookanUserProfile) -> String {
        if account.role == .venueManager {
            return "tryManagerAccount"
        }
        if account.email == "demo@sookan.app" {
            return "tryDemoAccount"
        }
        let firstName = account.displayName.split(separator: " ").first ?? "player"
        return "try\(firstName)Account"
    }

    private func submit() {
        errorMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if isCreatingAccount {
                guard password == confirmPassword else {
                    errorMessage = "Your passwords don’t match."
                    return
                }
                try authService.signUp(
                    email: cleanEmail,
                    password: password,
                    role: selectedRole
                )
            } else {
                try authService.signIn(email: cleanEmail, password: password)
            }

            focusedField = nil
            guard let currentUser = authService.currentUser else {
                errorMessage = "Unable to load your demo profile. Please try again."
                return
            }
            onAuthenticated(currentUser)
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Something went wrong. Please try again."
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}

#Preview {
    AuthenticationView(authService: MockAuthService()) { _ in }
}
