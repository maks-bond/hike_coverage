import SwiftUI

// A view that lists recorded hikes. When a route is tapped, it calls onSelect.
struct RoutesListView: View {
    var hikes: [Hike]
    var onSelect: (Hike) -> Void
    
    var body: some View {
        NavigationView {
            List(hikes) { hike in
                Button(action: {
                    onSelect(hike)
                }) {
                    VStack(alignment: .leading) {
                        Text("Hike on \(formattedDate(hike.date))")
                        Text("\(hike.coordinates.count) points")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Recorded Hikes")
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
