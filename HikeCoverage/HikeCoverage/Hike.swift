import Foundation
import CoreLocation

// A simple model representing a hike.
struct Hike: Codable {
    var coordinates: [CLLocationCoordinate2D] = []
    
    // Since CLLocationCoordinate2D isn’t Codable, we use a helper struct.
    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    private var codableCoordinates: [Coordinate] {
        return coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    // Custom encoding.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(codableCoordinates, forKey: .coordinates)
    }
    
    // Custom decoding.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let codableCoords = try container.decode([Coordinate].self, forKey: .coordinates)
        coordinates = codableCoords.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    // Default initializer.
    init(coordinates: [CLLocationCoordinate2D] = []) {
        self.coordinates = coordinates
    }
    
    enum CodingKeys: String, CodingKey {
        case coordinates
    }
}
