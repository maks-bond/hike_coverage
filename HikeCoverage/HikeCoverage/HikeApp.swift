import SwiftUI

import AWSCore
import AWSCognitoIdentityProvider

@main
struct HikeApp: App {
    init() {
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: .USEast2, // Change to your AWS region
            identityPoolId: "us-east-2:8c2593f4-6c74-4321-8c38-5987c6ffcad9"
        )

        let configuration = AWSServiceConfiguration(
            region: .USEast2, credentialsProvider: credentialsProvider
        )

        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
