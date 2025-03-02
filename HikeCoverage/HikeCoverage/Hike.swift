import Foundation
import CoreLocation

// A model representing a recorded hike.
struct Hike: Codable, Identifiable {
    var id: UUID = UUID()  // Unique identifier
    var date: Date = Date()  // Timestamp for the hike
    var coordinates: [CLLocationCoordinate2D] = []
    var notes: String = ""  // 📝 New field to store notes

    // Helper struct for encoding/decoding coordinates.
    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    func decodeCoordinates(_ locationString: String) -> [CLLocationCoordinate2D] {
        return locationString.split(separator: ";").compactMap { coord in
            let parts = coord.split(separator: ",")
            if parts.count == 2, let lat = Double(parts[0]), let lon = Double(parts[1]) {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            return nil
        }
    }

    init(from record: HikeRecord) {
        self.id = UUID(uuidString: record.hike_id ?? "") ?? UUID()
        self.date = Date(timeIntervalSince1970: record.start_time?.doubleValue ?? 0)
        self.coordinates = decodeCoordinates(record.location ?? "")
        self.notes = record.notes ?? ""
    }

    // Custom encoding.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(notes, forKey: .notes) // Save notes
        let codableCoords = coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        try container.encode(codableCoords, forKey: .coordinates)
    }
    
    // Custom decoding.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        notes = try container.decode(String.self, forKey: .notes)  // Load notes
        let codableCoords = try container.decode([Coordinate].self, forKey: .coordinates)
        coordinates = codableCoords.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    // Default initializer.
    init(coordinates: [CLLocationCoordinate2D] = [], notes: String = "") {
        self.coordinates = coordinates
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, coordinates, notes
    }
}
