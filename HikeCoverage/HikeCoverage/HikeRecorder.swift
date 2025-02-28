import Foundation
import CoreLocation
import Combine

class HikeRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentHike: Hike = Hike()
    @Published var allHikes: [Hike] = []
    @Published var isRecording: Bool = false
    @Published var userLocation: CLLocationCoordinate2D? = nil  // Store current location
    
    private var locationManager = CLLocationManager()
    var shouldRecenterOnLocationUpdate = true
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()  // Request "Always" permission
        locationManager.allowsBackgroundLocationUpdates = true  // Enable background updates
        locationManager.distanceFilter = 10
        locationManager.pausesLocationUpdatesAutomatically = false  // Prevent auto-pausing
        locationManager.startUpdatingLocation()  // Get initial location
        loadHikes()
        
        // ✅ Explicitly request location permissions
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization() // Upgrade if needed
        }
            
        locationManager.startUpdatingLocation()
    }
    
    func startRecording() {
        currentHike = Hike()
        isRecording = true
        locationManager.startUpdatingLocation()
    }
    
    func stopRecording() {
        locationManager.stopUpdatingLocation()
        isRecording = false
        saveHike(currentHike)
        currentHike = Hike()
    }
    
    // Handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        DispatchQueue.main.async {
            // ✅ Only update userLocation ONCE unless manually requested
            if self.userLocation == nil || self.shouldRecenterOnLocationUpdate {
                self.userLocation = newLocation.coordinate
                self.shouldRecenterOnLocationUpdate = false  // Reset after re-centering
            }

            if self.isRecording {
                self.currentHike.coordinates.append(newLocation.coordinate)  // ✅ Keeps hike tracking
                self.objectWillChange.send()  // ✅ Ensure UI updates after each new coordinate
            } else {
                self.objectWillChange.send()  // ✅ Ensure live location updates in UI
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
    
    func applicationDidEnterBackground() {
        if isRecording {
            locationManager.startUpdatingLocation()  // Ensure tracking continues
        }
    }

    func applicationWillEnterForeground() {
        locationManager.startUpdatingLocation()  // Restart updates if needed
    }
    
    // Updates notes for a selected hike
    func updateHikeNotes(hike: Hike, newNotes: String) {
        if let index = allHikes.firstIndex(where: { $0.id == hike.id }) {
            allHikes[index].notes = newNotes
            saveHikesToFile()
        }
    }

    func requestInitialLocation() {
        if userLocation == nil {
            locationManager.requestLocation()  // Ensure at least one location update
        }
    }

    // MARK: - Delete Route
    func deleteHike(_ hike: Hike) {
        allHikes.removeAll { $0.id == hike.id }
        saveHikesToFile()
    }
    
    // MARK: - Persistence
    
    private func getHikesFileURL() -> URL? {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsURL.appendingPathComponent("hikes.json")
    }
    
    private func saveHike(_ hike: Hike) {
        allHikes.append(hike)
        saveHikesToFile()
    }
    
    private func saveHikesToFile() {
        if let url = getHikesFileURL() {
            do {
                let data = try JSONEncoder().encode(allHikes)
                try data.write(to: url)
                print("Hikes saved to \(url)")
            } catch {
                print("Error saving hikes: \(error)")
            }
        }
    }
    
    private func loadHikes() {
        if let url = getHikesFileURL(),
           let data = try? Data(contentsOf: url),
           let hikes = try? JSONDecoder().decode([Hike].self, from: data) {
            allHikes = hikes
        }
    }
}
