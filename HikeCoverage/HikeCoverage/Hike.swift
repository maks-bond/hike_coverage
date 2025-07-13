import Foundation
import CoreLocation

// A model representing a recorded hike.
struct Hike: Codable, Identifiable {
    var id: UUID = UUID()  // Unique identifier
    var date: Date = Date()  // Timestamp for the hike
    var coordinates: [CLLocationCoordinate2D] = []
    var notes: String = ""  // 📝 New field to store notes

    // New struct to hold location with timestamp
    struct LocationPoint: Codable {
        let coordinate: CLLocationCoordinate2D
        let timestamp: Date
        
        // Custom coding keys
        private enum CodingKeys: String, CodingKey {
            case latitude, longitude, timestamp
        }
        
        init(coordinate: CLLocationCoordinate2D, timestamp: Date) {
            self.coordinate = coordinate
            self.timestamp = timestamp
        }
        
        // Custom encoding
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(coordinate.latitude, forKey: .latitude)
            try container.encode(coordinate.longitude, forKey: .longitude)
            try container.encode(timestamp, forKey: .timestamp)
        }
        
        // Custom decoding
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let lat = try container.decode(Double.self, forKey: .latitude)
            let lon = try container.decode(Double.self, forKey: .longitude)
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    var locationPoints: [LocationPoint] = []  // New property for timestamped locations
    var version: String = "v2"  // Version identifier

    // Helper struct for encoding/decoding coordinates.
    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    func decodeCoordinates(_ locationString: String) -> [CLLocationCoordinate2D] {
        // Handle v2 format with timestamps
        if locationString.contains("|") {
            return locationString.split(separator: ";").compactMap { point in
                let parts = point.split(separator: "|")
                guard parts.count >= 2 else { return nil }
                let coords = parts[0].split(separator: ",")
                if coords.count == 2,
                   let lat = Double(coords[0]),
                   let lon = Double(coords[1]) {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                return nil
            }
        }
        
        // Handle v1 format (backward compatibility)
        return locationString.split(separator: ";").compactMap { coord in
            let parts = coord.split(separator: ",")
            if parts.count == 2,
               let lat = Double(parts[0]),
               let lon = Double(parts[1]) {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            return nil
        }
    }
    
    func decodeLocationPoints(_ locationString: String) -> [LocationPoint] {
        // Only parse timestamps for v2 format
        guard locationString.contains("|") else { return [] }
        
        return locationString.split(separator: ";").compactMap { point in
            let parts = point.split(separator: "|")
            guard parts.count == 2,
                  let timestamp = Double(parts[1]) else { return nil }
            
            let coords = parts[0].split(separator: ",")
            if coords.count == 2,
               let lat = Double(coords[0]),
               let lon = Double(coords[1]) {
                return LocationPoint(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    timestamp: Date(timeIntervalSince1970: timestamp)
                )
            }
            return nil
        }
    }

    init(from record: HikeRecord) {
        self.id = UUID(uuidString: record.hike_id ?? "") ?? UUID()
        self.date = Date(timeIntervalSince1970: record.start_time?.doubleValue ?? 0)
        self.notes = record.notes ?? ""
        self.version = record.version ?? "v1"
        
        if let locationString = record.location {
            self.coordinates = decodeCoordinates(locationString)
            if version == "v2" {
                self.locationPoints = decodeLocationPoints(locationString)
            }
        }
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
