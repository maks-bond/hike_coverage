import SwiftUI
import MapKit
import CoreLocation
import AWSCore
import AWSCognitoIdentityProvider
import AWSDynamoDB

struct ContentView: View {
    @StateObject var recorder = HikeRecorder()
    @State private var showRoutesList = false
    @State private var selectedHike: Hike? = nil
    @State private var userName: String = UserSettings.shared.userName ?? ""
    @State private var showNamePrompt = false
    @State private var isLoading = true  // ✅ Prevents UI freeze

    func testCognitoAuthentication() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast2, identityPoolId: "us-east-2:8c2593f4-6c74-4321-8c38-5987c6ffcad9")
        credentialsProvider.getIdentityId().continueWith { (task) -> Any? in
            DispatchQueue.main.async {
                if let error = task.error {
                    print("Error getting Cognito Identity ID: \(error)")
                } else if let identityId = task.result {
                    print("Cognito Identity ID: \(identityId)")
                }
            }
            return nil
        }
    }

    func calculateDistance(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0.0 }
        var distance: Double = 0
        for i in 1..<coordinates.count {
            let loc1 = CLLocation(latitude: coordinates[i-1].latitude, longitude: coordinates[i-1].longitude)
            let loc2 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            distance += loc1.distance(from: loc2)
        }
        return distance / 1000.0 // Convert to kilometers
    }

    func encodeCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> String {
        return coordinates.map { "\($0.latitude),\($0.longitude)" }.joined(separator: ";")
    }

    func saveHikeToDynamoDB(hike: Hike) {
        guard let dbHike = HikeRecord() else {
            print("Failed to create HikeRecord")
            return
        }
        
        guard !userName.isEmpty else {
            print("User name is empty. Cannot save hike.")
            return
        }

        dbHike.hike_id = hike.id.uuidString
        dbHike.user_uuid = userName  // ✅ Store hikes under the user’s name instead of UUID
        dbHike.hike_name = "Hike on \(hike.date)"
        dbHike.start_time = NSNumber(value: hike.date.timeIntervalSince1970)
        dbHike.distance = NSNumber(value: calculateDistance(hike.coordinates))
        dbHike.notes = hike.notes
        dbHike.location = encodeCoordinates(hike.coordinates)

        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.save(dbHike) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving hike: \(error)")
                } else {
                    print("Hike saved successfully!")
                }
            }
        }
    }

    func deleteHikeFromDynamoDB(hike: Hike) {
        guard let dbHike = HikeRecord() else {
            print("Failed to create HikeRecord for deletion")
            return
        }
        
        dbHike.hike_id = hike.id.uuidString

        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.remove(dbHike) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting hike: \(error)")
                } else {
                    print("Hike deleted successfully!")
                    recorder.allHikes.removeAll { $0.id == hike.id }  // ✅ Remove from local list
                }
            }
        }
    }
    
    func fetchHikesFromDynamoDB() {
        guard !userName.isEmpty else {
            print("User name is empty. Cannot fetch hikes.")
            return
        }

        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "user_uuid = :userName"
        scanExpression.expressionAttributeValues = [":userName": userName]

        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        DispatchQueue.global(qos: .userInitiated).async {  // ✅ Background thread
            dynamoDBObjectMapper.scan(HikeRecord.self, expression: scanExpression).continueWith { task -> Any? in
                DispatchQueue.main.async {
                    if let error = task.error {
                        print("Error fetching hikes: \(error)")
                    } else if let result = task.result {
                        let fetchedHikes = result.items as? [HikeRecord] ?? []
                        print("Fetched \(fetchedHikes.count) hikes from AWS for user: \(userName)")
                        recorder.allHikes = fetchedHikes.map { Hike(from: $0) }
                    }
                    isLoading = false  // ✅ Allow name prompt after AWS request completes
                }
                return nil
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                if let userLocation = recorder.userLocation {
                    MapView(
                        hikes: $recorder.allHikes,
                        currentHike: $recorder.currentHike,
                        selectedHike: $selectedHike,
                        userLocation: Binding.constant(userLocation),
                        shouldFollowUser: $recorder.shouldFollowUser
                    )
                    .edgesIgnoringSafeArea(.all)
                } else {
                    VStack {
                        Text("Loading map...")
                            .font(.headline)
                            .foregroundColor(.gray)
                        ProgressView()
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
                }

                VStack {
                    HStack {
                        if recorder.isRecording {
                            Label("Recording...", systemImage: "record.circle")
                                .padding(8)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        } else {
                            Label("Not Recording", systemImage: "stop.circle")
                                .padding(8)
                                .background(Color.gray.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Spacer()

                        Button(action: { showRoutesList = true }) {
                            Text("Routes")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()

                    Spacer()

                    HStack {
                        Button(action: {
                            recorder.startRecording()
                            selectedHike = nil
                        }) {
                            Text("Start Recording")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(recorder.isRecording)

                        Button(action: {
                            recorder.stopRecording()
                            if let lastHike = recorder.allHikes.last {
                                saveHikeToDynamoDB(hike: lastHike)
                            }
                        }) {
                            Text("Stop & Sync")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!recorder.isRecording)

                        Button(action: {
                            recorder.shouldRecenterOnLocationUpdate = true
                            recorder.userLocation = recorder.userLocation
                        }) {
                            Image(systemName: "location.fill")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRoutesList) {
                RoutesListView(recorder: recorder, userName: userName, onDeleteHike: deleteHikeFromDynamoDB) { hike in
                    selectedHike = hike
                    showRoutesList = false
                }
            }
        }
        .onAppear {
            recorder.requestInitialLocation()
            testCognitoAuthentication()
            fetchHikesFromDynamoDB()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if userName.isEmpty {
                    showNamePrompt = true
                }
            }
        }
        .sheet(isPresented: $showNamePrompt) {
            NameEntryView(userName: $userName)
        }
    }
}
