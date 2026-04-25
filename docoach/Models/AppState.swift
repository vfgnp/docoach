import SwiftUI
import Observation

@Observable
final class AppState {
    var selectedGrade: Int = {
        let stored = UserDefaults.standard.integer(forKey: "selectedGrade")
        return stored == 0 ? 4 : stored
    }() {
        didSet {
            UserDefaults.standard.set(selectedGrade, forKey: "selectedGrade")
        }
    }

    var dailyLimit: Int? = {
        let stored = UserDefaults.standard.integer(forKey: "dailyLimit")
        return stored == 0 ? nil : stored
    }() {
        didSet {
            if let limit = dailyLimit {
                UserDefaults.standard.set(limit, forKey: "dailyLimit")
            } else {
                UserDefaults.standard.removeObject(forKey: "dailyLimit")
            }
        }
    }

    var gradeName: String { "小学\(selectedGrade)年生" }
}
