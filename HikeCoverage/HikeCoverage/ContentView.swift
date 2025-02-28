import SwiftUI
import MapKit  // Ensure MapKit is imported

struct ContentView: View {
    @StateObject var recorder = HikeRecorder()
    @State private var showRoutesList = false
    @State private var selectedHike: Hike? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                // ✅ Ensure MapView only loads if userLocation is valid
                if let userLocation = recorder.userLocation {
                    MapView(
                        hikes: $recorder.allHikes,
                        currentHike: $recorder.currentHike,
                        selectedHike: $selectedHike,
                        userLocation: Binding.constant(userLocation)  // Use constant to prevent SwiftUI crashes
                    )
                    .edgesIgnoringSafeArea(.all)
                } else {
                    VStack {
                        Text("Loading map...")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        ProgressView()  // Show spinner while waiting
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
                }

                VStack {
                    HStack {
                        // Recording Status Indicator
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
                        
                        // Routes Button - Opens List of Saved Hikes
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
                        // Start Recording Button
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
                        
                        // Stop Recording Button
                        Button(action: {
                            recorder.stopRecording()
                        }) {
                            Text("Stop Recording")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!recorder.isRecording)
                        
                        // Re-Center Button - Centers map on user's location
                        Button(action: {
                            if recorder.userLocation != nil {
                                recorder.shouldRecenterOnLocationUpdate = true  // ✅ Triggers ONE re-center on next location update
                            }
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
                RoutesListView(recorder: recorder) { hike in
                    selectedHike = hike
                    showRoutesList = false
                }
            }
        }
        .onAppear {
            // ✅ Ensure userLocation is requested early
            recorder.requestInitialLocation()
        }
    }
}
