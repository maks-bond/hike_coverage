import SwiftUI

struct ContentView: View {
    @StateObject var recorder = HikeRecorder()
    
    var body: some View {
        VStack {
            // Map displaying recorded hikes and the current hike overlay.
            MapView(hikes: $recorder.allHikes, currentHike: $recorder.currentHike)
                .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 20) {
                Button(action: {
                    recorder.startRecording()
                }) {
                    Text("Start Recording")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                // Disable if a hike is already in progress.
                .disabled(!recorder.currentHike.coordinates.isEmpty)
                
                Button(action: {
                    recorder.stopRecording()
                }) {
                    Text("Stop Recording")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                // Disable if no hike is in progress.
                .disabled(recorder.currentHike.coordinates.isEmpty)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
