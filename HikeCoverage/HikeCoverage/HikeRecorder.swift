import Foundation
import CoreLocation
import Combine

// ObservableObject that handles location tracking and persistence.
class HikeRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentHike: Hike = Hike()
    @Published var allHikes: [Hike] = []
    
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Request location permission.
        locationManager.requestWhenInUseAuthorization()
        loadHikes()
    }
    
    func startRecording() {
        currentHike = Hike()
        locationManager.startUpdatingLocation()
    }
    
    func stopRecording() {
        locationManager.stopUpdatingLocation()
        saveHike(currentHike)
    }
    
    // CLLocationManagerDelegate method.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        currentHike.coordinates.append(newLocation.coordinate)
        // Publish the updated hike.
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Persistence
    
    private func getHikesFileURL() -> URL? {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsURL.appendingPathComponent("hikes.json")
    }
    
    private func saveHike(_ hike: Hike) {
        allHikes.append(hike)
        if let url = getHikesFileURL() {
            do {
                let data = try JSONEncoder().encode(allHikes)
                try data.write(to: url)
                print("Hike saved to \(url)")
            } catch {
                print("Error saving hike: \(error)")
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
