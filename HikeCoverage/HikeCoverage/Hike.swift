import Foundation
import CoreLocation

// A simple model representing a hike.
struct Hike: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var coordinates: [CLLocationCoordinate2D] = []
    
    // Helper struct for encoding/decoding coordinates.
    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    // Custom encoding.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        let codableCoords = coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        try container.encode(codableCoords, forKey: .coordinates)
    }
    
    // Custom decoding.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        let codableCoords = try container.decode([Coordinate].self, forKey: .coordinates)
        coordinates = codableCoords.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    // Default initializer.
    init(coordinates: [CLLocationCoordinate2D] = []) {
        self.coordinates = coordinates
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, coordinates
    }
}
