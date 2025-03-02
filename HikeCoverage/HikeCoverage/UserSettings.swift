import Foundation

class UserSettings {
    static let shared = UserSettings()
    private let userNameKey = "user_name"

    var userName: String? {
        get { UserDefaults.standard.string(forKey: userNameKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: userNameKey) }
    }
}
