import Foundation
import SwiftUI

struct Expense: Identifiable, Codable, Hashable {
    var id = UUID(); var amount: Double; var category: String; var note: String = ""; var date = Date()
}
struct Commitment: Identifiable, Codable, Hashable {
    var id = UUID(); var title: String; var amount: Double; var category: String = "أخرى"; var dueDay: Int = 1; var isActive = true
}
struct SavingGoal: Identifiable, Codable, Hashable {
    var id = UUID(); var title: String; var target: Double; var current: Double = 0
}

@MainActor final class BudgetStore: ObservableObject {
    @Published var salary: Double { didSet { save() } }
    @Published var endGoal: Double { didSet { save() } }
    @Published var savingRate: Double { didSet { save() } }
    @Published var expenses: [Expense] { didSet { save() } }
    @Published var commitments: [Commitment] { didSet { save() } }
    @Published var goals: [SavingGoal] { didSet { save() } }
    @Published var payday: Int { didSet { save() } }
    @Published var haptics: Bool { didSet { save() } }
    private let key = "smartBudget.data.v3"

    init() {
        if let d = UserDefaults.standard.data(forKey: key), let x = try? JSONDecoder().decode(Snapshot.self, from: d) {
            salary=x.salary; endGoal=x.endGoal; savingRate=x.savingRate; expenses=x.expenses; commitments=x.commitments; goals=x.goals; payday=x.payday; haptics=x.haptics
        } else {
            salary=0; endGoal=0; savingRate=0.10; expenses=[]; commitments=[]; goals=[]; payday=27; haptics=true
        }
    }
    struct Snapshot: Codable { var salary:Double; var endGoal:Double; var savingRate:Double; var expenses:[Expense]; var commitments:[Commitment]; var goals:[SavingGoal]; var payday:Int; var haptics:Bool }
    func save(){ let x=Snapshot(salary:salary,endGoal:endGoal,savingRate:savingRate,expenses:expenses,commitments:commitments,goals:goals,payday:payday,haptics:haptics); if let d=try? JSONEncoder().encode(x){UserDefaults.standard.set(d,forKey:key)} }

    var calendar: Calendar { .current }
    var monthExpenses: [Expense] { expenses.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) && calendar.isDate($0.date, equalTo: Date(), toGranularity: .year) } }
    var fixed: Double { commitments.filter(\.isActive).reduce(0){$0+$1.amount} }
    var spent: Double { monthExpenses.reduce(0){$0+$1.amount} }
    var todaySpent: Double { monthExpenses.filter{calendar.isDateInToday($0.date)}.reduce(0){$0+$1.amount} }
    var suggestedSaving: Double { max(0, salary-fixed) * savingRate }
    var spendable: Double { max(0, salary-fixed-endGoal-suggestedSaving) }
    var remaining: Double { spendable-spent }
    var daysLeft: Int { let r=calendar.range(of:.day,in:.month,for:Date())!; return max(1,r.count-calendar.component(.day,from:Date())+1) }
    var dailyLimit: Double { max(0, remaining) / Double(daysLeft) }
    var safeTodayRemaining: Double { max(0, dailyLimit-todaySpent) }
    var savingsTotal: Double { goals.reduce(0){$0+$1.current} }
    var health: Double { guard spendable > 0 else { return 0 }; return max(0,min(1,remaining/spendable)) }
    var projectedEndBalance: Double {
        let elapsed=max(1,calendar.component(.day,from:Date())); let avg=spent/Double(elapsed); return salary-fixed-suggestedSaving-(avg*Double(calendar.range(of:.day,in:.month,for:Date())!.count))
    }
    var categoryTotals: [(String,Double)] {
        Dictionary(grouping:monthExpenses,by:{$0.category}).map{($0.key,$0.value.reduce(0){$0+$1.amount})}.sorted{$0.1>$1.1}
    }
    var last7Days: [(Date,Double)] {
        (0..<7).reversed().map { offset in let d=calendar.date(byAdding:.day,value:-offset,to:calendar.startOfDay(for:Date()))!; return (d, monthExpenses.filter{calendar.isDate($0.date,inSameDayAs:d)}.reduce(0){$0+$1.amount}) }
    }
    func deleteExpense(_ id: UUID){ expenses.removeAll{$0.id==id} }
    func resetMonth(){ expenses.removeAll { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) && calendar.isDate($0.date, equalTo: Date(), toGranularity: .year) } }
}