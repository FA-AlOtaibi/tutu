import Foundation
import SwiftUI

struct Expense: Identifiable, Codable, Hashable { var id=UUID(); var amount:Double; var category:String; var note:String=""; var date=Date() }
struct Commitment: Identifiable, Codable, Hashable { var id=UUID(); var title:String; var amount:Double; var category:String="أخرى"; var dueDay:Int=1; var isActive=true }
struct SavingGoal: Identifiable, Codable, Hashable { var id=UUID(); var title:String; var target:Double; var current:Double=0 }
struct CategoryBudget: Identifiable, Codable, Hashable { var id=UUID(); var category:String; var limit:Double }
struct RecurringExpense: Identifiable, Codable, Hashable { var id=UUID(); var title:String; var amount:Double; var category:String; var day:Int; var isActive=true }

@MainActor final class BudgetStore: ObservableObject {
 @Published var salary:Double{didSet{save()}}; @Published var reserve:Double{didSet{save()}}; @Published var savingRate:Double{didSet{save()}}
 @Published var expenses:[Expense]{didSet{save()}}; @Published var commitments:[Commitment]{didSet{save()}}; @Published var goals:[SavingGoal]{didSet{save()}}
 @Published var categoryBudgets:[CategoryBudget]{didSet{save()}}; @Published var recurring:[RecurringExpense]{didSet{save()}}
 @Published var payday:Int{didSet{save()}}; @Published var haptics:Bool{didSet{save()}}; @Published var notifications:Bool{didSet{save()}}
 private let key="smartBudget.data.v4"
 init(){
  if let d=UserDefaults.standard.data(forKey:key),let x=try? JSONDecoder().decode(Snapshot.self,from:d){salary=x.salary;reserve=x.reserve;savingRate=x.savingRate;expenses=x.expenses;commitments=x.commitments;goals=x.goals;categoryBudgets=x.categoryBudgets;recurring=x.recurring;payday=x.payday;haptics=x.haptics;notifications=x.notifications}
  else{salary=0;reserve=0;savingRate=0.10;expenses=[];commitments=[];goals=[];categoryBudgets=[];recurring=[];payday=27;haptics=true;notifications=true}
 }
 struct Snapshot:Codable{var salary:Double;var reserve:Double;var savingRate:Double;var expenses:[Expense];var commitments:[Commitment];var goals:[SavingGoal];var categoryBudgets:[CategoryBudget];var recurring:[RecurringExpense];var payday:Int;var haptics:Bool;var notifications:Bool}
 func save(){let x=Snapshot(salary:salary,reserve:reserve,savingRate:savingRate,expenses:expenses,commitments:commitments,goals:goals,categoryBudgets:categoryBudgets,recurring:recurring,payday:payday,haptics:haptics,notifications:notifications);if let d=try? JSONEncoder().encode(x){UserDefaults.standard.set(d,forKey:key)}}
 var cal:Calendar{.current}
 var cycleStart:Date{let now=Date(),day=cal.component(.day,from:now);var c=cal.dateComponents([.year,.month],from:now);c.day=min(payday,28);let this=cal.date(from:c)!;return day>=payday ? this : cal.date(byAdding:.month,value:-1,to:this)!}
 var cycleEnd:Date{cal.date(byAdding:.day,value:-1,to:cal.date(byAdding:.month,value:1,to:cycleStart)!)!}
 var cycleExpenses:[Expense]{expenses.filter{$0.date>=cal.startOfDay(for:cycleStart) && $0.date<cal.date(byAdding:.day,value:1,to:cal.startOfDay(for:cycleEnd))!}}
 var fixed:Double{commitments.filter(\.isActive).reduce(0){$0+$1.amount}}; var spent:Double{cycleExpenses.reduce(0){$0+$1.amount}}
 var todaySpent:Double{cycleExpenses.filter{cal.isDateInToday($0.date)}.reduce(0){$0+$1.amount}}
 var savingAmount:Double{max(0,salary-fixed-reserve)*savingRate}; var plannedAvailable:Double{max(0,salary-fixed-reserve-savingAmount)}
 var remaining:Double{plannedAvailable-spent}; var daysLeft:Int{max(1,cal.dateComponents([.day],from:cal.startOfDay(for:Date()),to:cal.startOfDay(for:cycleEnd)).day!+1)}
 var dailyLimit:Double{max(0,remaining)/Double(daysLeft)}; var safeToday:Double{max(0,dailyLimit-todaySpent)}
 var health:Double{plannedAvailable>0 ? max(0,min(1,remaining/plannedAvailable)):0}
 var categoryTotals:[(String,Double)]{Dictionary(grouping:cycleExpenses,by:{$0.category}).map{($0.key,$0.value.reduce(0){$0+$1.amount})}.sorted{$0.1>$1.1}}
 func spent(in category:String)->Double{cycleExpenses.filter{$0.category==category}.reduce(0){$0+$1.amount}}
 var nextCommitments:[Commitment]{commitments.filter(\.isActive).sorted{$0.dueDay<$1.dueDay}}
 var projectedEnd:Double{let total=max(1,cal.dateComponents([.day],from:cycleStart,to:cycleEnd).day!+1);let elapsed=max(1,total-daysLeft+1);return salary-fixed-savingAmount-(spent/Double(elapsed)*Double(total))}
 func deleteExpense(_ id:UUID){expenses.removeAll{$0.id==id}}
 func resetCycle(){expenses.removeAll{$0.date>=cycleStart && $0.date<=cycleEnd}}
}