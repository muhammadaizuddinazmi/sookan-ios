import SwiftUI

struct VenueManagerDashboardView: View {
    let profile: SookanUserProfile
    let bookingService: any CourtBookingServicing
    let isActive: Bool

    @State private var listings: [CourtListing] = []
    @State private var slotsByListing: [UUID: [CourtTimeSlot]] = [:]
    @State private var isAddingListing = false
    @State private var selectedListing: CourtListing?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header

                VStack(alignment: .leading, spacing: 7) {
                    Text("Manage your courts.")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(SookanStyle.ink)
                    Text("List a venue, publish open times, and see player bookings.")
                        .font(.system(size: 14))
                        .foregroundStyle(SookanStyle.muted)
                }

                Button {
                    isAddingListing = true
                } label: {
                    Label("Add a court or field", systemImage: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SookanStyle.lime, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("addCourtListing")

                if let errorMessage {
                    errorBanner(errorMessage)
                }

                VStack(alignment: .leading, spacing: 13) {
                    Text("Your listings")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(SookanStyle.ink)

                    if listings.isEmpty {
                        Text("You haven't listed a court yet. Add one to make it available for players to book.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SookanStyle.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(listings) { listing in
                            listingCard(listing)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(SookanStyle.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshListings)
        .onChange(of: isActive) { _, isActive in
            if isActive {
                refreshListings()
            }
        }
        .sheet(isPresented: $isAddingListing) {
            AddCourtListingView(
                manager: profile,
                bookingService: bookingService,
                onListingAdded: refreshListings
            )
        }
        .sheet(item: $selectedListing) { listing in
            AddCourtAvailabilityView(
                listing: listing,
                bookingService: bookingService,
                onAvailabilityAdded: refreshListings
            )
        }
    }

    private var header: some View {
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

            Text("sookan")
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundStyle(SookanStyle.ink)

            Spacer()

            Text("MANAGER")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(SookanStyle.green)
        }
    }

    private func listingCard(_ listing: CourtListing) -> some View {
        let slots = slotsByListing[listing.id, default: []]
            .filter { $0.endsAt > Date() }

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.venueName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                    Text(listing.courtName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SookanStyle.green)
                }
                Spacer()
                Text(listing.sport.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(SookanStyle.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(SookanStyle.lime.opacity(0.4), in: Capsule())
            }

            Label(listing.address, systemImage: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
                .fixedSize(horizontal: false, vertical: true)

            if slots.isEmpty {
                Text("No upcoming availability")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
            } else {
                ForEach(slots) { slot in
                    HStack {
                        Text(slot.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SookanStyle.ink)
                        Spacer()
                        Text(slot.bookedByName.map { "Booked · \($0)" } ?? "Available")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(slot.isAvailable ? SookanStyle.green : SookanStyle.muted)
                    }
                }
            }

            Button {
                selectedListing = listing
            } label: {
                Label("Add available time", systemImage: "calendar.badge.plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SookanStyle.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(SookanStyle.canvas, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("addAvailability-\(listing.id)")
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.8), lineWidth: 1)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func refreshListings() {
        listings = bookingService.listings(managedBy: profile.email)
        slotsByListing = Dictionary(
            uniqueKeysWithValues: listings.map { ($0.id, bookingService.slots(for: $0.id)) }
        )
    }
}

private struct AddCourtListingView: View {
    @Environment(\.dismiss) private var dismiss

    let manager: SookanUserProfile
    let bookingService: any CourtBookingServicing
    let onListingAdded: () -> Void

    @State private var venueName = ""
    @State private var courtName = ""
    @State private var address = ""
    @State private var sport = "Badminton"
    @State private var errorMessage: String?

    private let sports = ["Badminton", "Tennis", "Football", "Running"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Add your bookable space")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(SookanStyle.ink)

                    inputField("VENUE NAME", placeholder: "e.g. KL Sports Hub", text: $venueName)
                    inputField("COURT OR FIELD", placeholder: "e.g. Court 1", text: $courtName)
                    inputField("ADDRESS", placeholder: "Street, city", text: $address)

                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("SPORT")
                        Picker("Sport", selection: $sport) {
                            ForEach(sports, id: \.self) { sport in
                                Text(sport).tag(sport)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(.white, in: RoundedRectangle(cornerRadius: 13))
                    }

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }

                    Button(action: addListing) {
                        Text("Publish court listing")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SookanStyle.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SookanStyle.lime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("publishCourtListing")
                }
                .padding(22)
            }
            .background(SookanStyle.canvas.ignoresSafeArea())
            .navigationTitle("New listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SookanStyle.green)
                }
            }
        }
        .tint(SookanStyle.green)
        .presentationDetents([.large])
    }

    private func inputField(
        _ title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        let identifier = switch title {
        case "VENUE NAME":
            "venueNameField"
        case "COURT OR FIELD":
            "courtNameField"
        case "ADDRESS":
            "venueAddressField"
        default:
            title
        }

        return VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(SookanStyle.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 13)
                .frame(height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 13))
                .accessibilityIdentifier(identifier)
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(SookanStyle.line, lineWidth: 1)
                }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(SookanStyle.muted)
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func addListing() {
        do {
            try bookingService.addListing(
                manager: manager,
                venueName: venueName,
                courtName: courtName,
                address: address,
                sport: sport
            )
            onListingAdded()
            dismiss()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't publish this listing."
        } catch {
            errorMessage = "Couldn't publish this listing."
        }
    }
}

private struct AddCourtAvailabilityView: View {
    @Environment(\.dismiss) private var dismiss

    let listing: CourtListing
    let bookingService: any CourtBookingServicing
    let onAvailabilityAdded: () -> Void

    @State private var startsAt = Calendar.current.date(
        byAdding: .day,
        value: 1,
        to: Date()
    ) ?? Date().addingTimeInterval(60 * 60 * 24)
    @State private var durationMinutes = 60
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(listing.courtName)
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .foregroundStyle(SookanStyle.ink)
                    Text(listing.venueName)
                        .font(.system(size: 14))
                        .foregroundStyle(SookanStyle.muted)
                }

                DatePicker(
                    "Available from",
                    selection: $startsAt,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 8) {
                    Text("BOOKING LENGTH")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(SookanStyle.muted)
                    Picker("Booking length", selection: $durationMinutes) {
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                    }
                    .pickerStyle(.segmented)
                }

                Text("Players can book this time as soon as you publish it.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: addAvailability) {
                    Text("Publish availability")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SookanStyle.lime, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("publishAvailability")

                Spacer()
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SookanStyle.canvas.ignoresSafeArea())
            .navigationTitle("Open time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SookanStyle.green)
                }
            }
        }
        .tint(SookanStyle.green)
        .presentationDetents([.large])
    }

    private func addAvailability() {
        do {
            try bookingService.addAvailability(
                for: listing.id,
                as: listing.managerEmail,
                startsAt: startsAt,
                durationMinutes: durationMinutes
            )
            onAvailabilityAdded()
            dismiss()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't publish this time."
        } catch {
            errorMessage = "Couldn't publish this time."
        }
    }
}

struct CourtBookingBrowseView: View {
    @Environment(\.dismiss) private var dismiss

    let player: SookanUserProfile
    let bookingService: any CourtBookingServicing

    @State private var listings: [CourtListing] = []
    @State private var slotsByListing: [UUID: [CourtTimeSlot]] = [:]
    @State private var errorMessage: String?
    @State private var bookingMessage = ""
    @State private var isBookingConfirmed = false

    private var myBookings: [(listing: CourtListing, slot: CourtTimeSlot)] {
        listings.flatMap { listing in
            slotsByListing[listing.id, default: []]
                .filter { $0.bookedByEmail == player.email && $0.endsAt > Date() }
                .map { (listing, $0) }
        }
        .sorted { $0.slot.startsAt < $1.slot.startsAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Book a court.")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(SookanStyle.ink)
                        Text("Only manager-listed courts and open times appear here.")
                            .font(.system(size: 14))
                            .foregroundStyle(SookanStyle.muted)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 0.72, green: 0.25, blue: 0.19))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !myBookings.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your bookings")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundStyle(SookanStyle.ink)
                            ForEach(myBookings, id: \.slot.id) { booking in
                                playerBookingCard(booking.listing, slot: booking.slot)
                            }
                        }
                    }

                    if listings.isEmpty {
                        Text("No courts are listed yet. Check back after a manager publishes one.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SookanStyle.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(listings) { listing in
                            listingCard(listing)
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
        .onAppear(perform: refreshListings)
        .alert("Booking confirmed", isPresented: $isBookingConfirmed) {
            Button("Done", role: .cancel) {}
        } message: {
            Text(bookingMessage)
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
            Text("COURTS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(SookanStyle.green)
            Spacer()

            Image(systemName: "sportscourt")
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

    private func listingCard(_ listing: CourtListing) -> some View {
        let availableSlots = slotsByListing[listing.id, default: []]
            .filter { $0.isAvailable && $0.startsAt > Date() }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.venueName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SookanStyle.ink)
                    Text(listing.courtName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SookanStyle.green)
                }
                Spacer()
                Text(listing.sport.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(SookanStyle.green)
            }

            Label(listing.address, systemImage: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
                .fixedSize(horizontal: false, vertical: true)

            if availableSlots.isEmpty {
                Text("No available times")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SookanStyle.muted)
            } else {
                ForEach(availableSlots) { slot in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(slot.startsAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SookanStyle.ink)
                            Text("Until \(slot.endsAt.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(SookanStyle.muted)
                        }
                        Spacer()
                        Button {
                            book(slot)
                        } label: {
                            Text("Book")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SookanStyle.ink)
                                .padding(.horizontal, 14)
                                .frame(height: 32)
                                .background(SookanStyle.lime, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("bookSlot-\(slot.id)")
                    }
                    .padding(.top, 5)
                }
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SookanStyle.line.opacity(0.8), lineWidth: 1)
        }
    }

    private func playerBookingCard(
        _ listing: CourtListing,
        slot: CourtTimeSlot
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(listing.venueName) · \(listing.courtName)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SookanStyle.ink)
            Label(
                slot.startsAt.formatted(date: .abbreviated, time: .shortened),
                systemImage: "calendar"
            )
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(SookanStyle.muted)
            Label(listing.address, systemImage: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SookanStyle.muted)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SookanStyle.lime.opacity(0.2), in: RoundedRectangle(cornerRadius: 15))
    }

    private func book(_ slot: CourtTimeSlot) {
        errorMessage = nil
        do {
            try bookingService.book(slotID: slot.id, by: player)
            bookingMessage = "Your time is booked. You can see the booking in the manager's listing."
            isBookingConfirmed = true
            refreshListings()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't book this time."
        } catch {
            errorMessage = "Couldn't book this time."
        }
    }

    private func refreshListings() {
        listings = bookingService.listings()
        slotsByListing = Dictionary(
            uniqueKeysWithValues: listings.map { ($0.id, bookingService.slots(for: $0.id)) }
        )
    }
}
