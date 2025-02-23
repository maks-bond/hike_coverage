import SwiftUI

struct RoutesListView: View {
    @ObservedObject var recorder: HikeRecorder
    var onSelect: (Hike) -> Void
    
    var body: some View {
        List {
            ForEach(recorder.allHikes) { hike in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hike on \(formattedDate(hike.date))")
                        Text("\(hike.coordinates.count) points")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { recorder.deleteHike(hike) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .onTapGesture { onSelect(hike) }
            }
        }
        .navigationTitle("Recorded Hikes")
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
