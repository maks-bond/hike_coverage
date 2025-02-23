import SwiftUI

struct RoutesListView: View {
    @ObservedObject var recorder: HikeRecorder
    var onSelect: (Hike) -> Void

    @State private var hikeToDelete: Hike?  // Store selected hike for deletion
    @State private var showDeleteConfirmation = false  // Show confirmation alert

    var body: some View {
        NavigationView {
            List {
                ForEach(recorder.allHikes) { hike in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hike on \(formattedDate(hike.date))")
                            Text("\(hike.coordinates.count) points")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Makes text fully occupy available space
                        .contentShape(Rectangle()) // Ensures tap is recognized only inside text area
                        .onTapGesture { onSelect(hike) }

                        // Delete Button
                        Button(action: {
                            hikeToDelete = hike  // Store hike to be deleted
                            showDeleteConfirmation = true  // Show alert
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding(10)
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevents SwiftUI from adding extra button padding behavior
                    }
                }
            }
            .navigationTitle("Recorded Hikes")
            .alert("Are you sure you want to delete this hike?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    hikeToDelete = nil  // Cancel deletion
                }
                Button("Delete", role: .destructive) {
                    if let hike = hikeToDelete {
                        recorder.deleteHike(hike)
                    }
                    hikeToDelete = nil
                }
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
