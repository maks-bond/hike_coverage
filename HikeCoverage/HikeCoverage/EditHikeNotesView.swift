import SwiftUI

struct EditHikeNotesView: View {
    @ObservedObject var recorder: HikeRecorder
    var hike: Hike
    
    @State private var notes: String  // Stores the user's notes
    @Environment(\.presentationMode) var presentationMode  // Allows dismissing the view
    
    init(recorder: HikeRecorder, hike: Hike) {
        self.recorder = recorder
        self.hike = hike
        _notes = State(initialValue: hike.notes)  // Preload existing notes
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $notes)
                    .padding()
                    .frame(minHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                
                HStack {
                    Button("Discard Changes") {
                        presentationMode.wrappedValue.dismiss()  // Close without saving
                    }
                    .padding()
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save Notes") {
                        recorder.updateHikeNotes(hike: hike, newNotes: notes)
                        presentationMode.wrappedValue.dismiss()  // Close after saving
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Edit Notes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
