import SwiftUI

struct NameEntryView: View {
    @Binding var userName: String
    @Environment(\.presentationMode) var presentationMode

    @State private var tempName: String = ""

    var body: some View {
        VStack {
            Text("Enter Your Name")
                .font(.title)
                .bold()
                .padding()

            TextField("Your name", text: $tempName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.words)

            Button("Save") {
                if !tempName.isEmpty {
                    userName = tempName
                    UserSettings.shared.userName = tempName
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}
