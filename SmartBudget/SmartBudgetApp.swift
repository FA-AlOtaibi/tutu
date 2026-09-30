import SwiftUI

@main
struct SmartBudgetApp: App {
    @StateObject private var store = BudgetStore()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store).environment(\.layoutDirection, .rightToLeft) }
    }
}