import CoreLocation
import Combine
import MapKit
import SwiftUI

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var accuracyAuthorization: CLAccuracyAuthorization = .reducedAccuracy
    @Published private(set) var locality: String?
    @Published private(set) var isLoading = false
    @Published private(set) var hasLocationFix = false
    @Published private(set) var errorMessage: String?

    private let manager = CLLocationManager()
    private var hasRequestedLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        authorizationStatus = manager.authorizationStatus
        accuracyAuthorization = manager.accuracyAuthorization
    }

    var title: String {
        if let locality {
            return locality.uppercased()
        }
        if hasLocationFix {
            return "LOCATION FOUND"
        }
        if authorizationStatus == .notDetermined {
            return "USE MY LOCATION"
        } else if authorizationStatus == .denied {
            return "LOCATION ACCESS OFF"
        } else if authorizationStatus == .restricted {
            return "LOCATION UNAVAILABLE"
        } else if isLoading {
            return "FINDING LOCATION"
        }
        return "LOCATION NOT FOUND"
    }

    var subtitle: String {
        if authorizationStatus == .notDetermined {
            return "Tap to allow location while using Sookan"
        } else if authorizationStatus == .denied {
            return "Access off · Tap to open Settings"
        } else if authorizationStatus == .restricted {
            return "Location access is restricted"
        } else if isLoading {
            return "Finding your nearby area…"
        } else if accuracyAuthorization == .reducedAccuracy {
            return "Approximate · Tap to enable precise location"
        }
        return "Precise location · While using the app"
    }

    func requestPermission() {
        hasRequestedLocation = true
        errorMessage = nil
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        hasRequestedLocation = true
        errorMessage = nil
        guard authorizationStatus == .authorizedAlways
                || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        guard !isLoading else {
            return
        }

        isLoading = true
        manager.requestLocation()
    }

    func refreshAuthorizationStatus() {
        let previousStatus = authorizationStatus
        let previousAccuracy = accuracyAuthorization
        updateAuthorizationStatus(from: manager)
        if (previousStatus != authorizationStatus || previousAccuracy != accuracyAuthorization),
           hasRequestedLocation,
           isAuthorized {
            requestCurrentLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus(from: manager)
        if hasRequestedLocation, isAuthorized {
            requestCurrentLocation()
        } else if !isAuthorized {
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            errorMessage = "No location was returned. Please try again."
            return
        }

        hasLocationFix = true
        Task {
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    errorMessage = "Couldn't prepare a request for your location."
                    isLoading = false
                    return
                }
                let mapItems = try await request.mapItems
                locality = mapItems.first?.addressRepresentations?.cityName
                    ?? mapItems.first?.addressRepresentations?.regionName
                if locality == nil {
                    errorMessage = "Your location was found, but its area name is unavailable."
                }
            } catch {
                errorMessage = "Your location was found, but its area name couldn't be loaded."
            }
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Couldn't determine your location. Check Location Services and try again."
    }

    private var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    private func updateAuthorizationStatus(from manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        accuracyAuthorization = manager.accuracyAuthorization
    }
}
