import SwiftUI

struct RoutesListView: View {
    @ObservedObject var recorder: HikeRecorder
    var onSelect: (Hike) -> Void

    @State private var hikeToDelete: Hike?  // Store selected hike for deletion
    @State private var showDeleteConfirmation = false  // Show confirmation alert
    @State private var selectedHikeForNotes: Hike?  // Store hike for notes editing
    
    var body: some View {
        NavigationView {
            List {
                ForEach(recorder.allHikes) { hike in
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Hike on \(formattedDate(hike.date))")
                                Text("\(hike.coordinates.count) points")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture { onSelect(hike) }
                            
                            // Delete Button
                            Button(action: {
                                hikeToDelete = hike
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Edit Notes Button
                        Button(action: {
                            selectedHikeForNotes = hike
                        }) {
                            HStack {
                                Image(systemName: "note.text")
                                Text(hike.notes.isEmpty ? "Add Notes" : "Edit Notes")
                            }
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Recorded Hikes")
            .alert("Are you sure you want to delete this hike?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    hikeToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let hike = hikeToDelete {
                        recorder.deleteHike(hike)
                    }
                    hikeToDelete = nil
                }
            }
            .sheet(item: $selectedHikeForNotes) { hike in
                EditHikeNotesView(recorder: recorder, hike: hike)
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
