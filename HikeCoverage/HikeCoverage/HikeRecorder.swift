import Foundation
import CoreLocation
import Combine

class HikeRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentHike: Hike = Hike()
    @Published var allHikes: [Hike] = []
    @Published var isRecording: Bool = false
    @Published var userLocation: CLLocationCoordinate2D? = nil  // Store current location
    @Published var shouldFollowUser: Bool = true  // Track if the map should follow user

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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        DispatchQueue.main.async {
            // ✅ Only update userLocation if auto-follow is enabled
            if self.shouldRecenterOnLocationUpdate {
                self.userLocation = newLocation.coordinate
            }

            if self.isRecording {
                self.currentHike.coordinates.append(newLocation.coordinate)
                self.currentHike.locationPoints.append(
                    Hike.LocationPoint(
                        coordinate: newLocation.coordinate,
                        timestamp: newLocation.timestamp
                    )
                )
                self.objectWillChange.send()
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
        // Insert new hikes at the beginning to keep the list sorted by date descending.
        allHikes.insert(hike, at: 0)
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
            // Sort hikes by date to ensure they are always displayed in descending order.
            allHikes = hikes.sorted { $0.date > $1.date }
        }
    }
}
