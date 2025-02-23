import SwiftUI

struct ContentView: View {
    @StateObject var recorder = HikeRecorder()
    @State private var showRoutesList = false
    @State private var selectedHike: Hike? = nil
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                MapView(
                    hikes: $recorder.allHikes,
                    currentHike: $recorder.currentHike,
                    selectedHike: $selectedHike,
                    userLocation: $recorder.userLocation
                )
                .edgesIgnoringSafeArea(.all)
                
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
                        }) {
                            Text("Stop Recording")
                                .padding()
                                .background(Color.red)
                                .f
