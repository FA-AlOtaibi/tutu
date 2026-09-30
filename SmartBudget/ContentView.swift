import SwiftUI
import Charts

let cats=["طعام","قهوة","وقود","تسوق","ترفيه","فواتير","أخرى"]
func money(_ x:Double)->String{"\(Int(x.rounded()).formatted()) ر.س"}

struct ContentView:View{
 @EnvironmentObject var s:BudgetStore; @State private var add=false; @State private var setup=false
 var body:some View{TabView{
  NavigationStack{HomeView(add:$add,setup:$setup)}.tabItem{Label("اليوم",systemImage:"house.fill")}
  NavigationStack{TransactionsView(add:$add)}.tabItem{Label("المصاريف",systemImage:"list.bullet.rectangle")}
  NavigationStack{PlanView()}.tabItem{Label("الخطة",systemImage:"slider.horizontal.3")}
  NavigationStack{ReportsView()}.tabItem{Label("التقارير",systemImage:"chart.pie.fill")}
 }.tint(.blue).sheet(isPresented:$add){AddExpense()}.sheet(isPresented:$setup){SalarySetup()}.onAppear{if s.salary<=0{setup=true}}}
}

struct HomeView:View{
 @EnvironmentObject var s:BudgetStore; @Binding var add:Bool; @Binding var setup:Bool
 var body:some View{ScrollView{VStack(spacing:16){
  HStack{VStack(alignment:.leading,spacing:3){Text("ميزانيتي").font(.largeTitle.bold());Text("من \(s.cycleStart.formatted(.dateTime.day().month())) إلى \(s.cycleEnd.formatted(.dateTime.day().month()))").font(.caption).foregroundStyle(.secondary)};Spacer();Button(action: { setup=true }) {Image(systemName:"pencil").frame(width:42,height:42).background(Color(.secondarySystemBackground),in:Circle())}}
  VStack(alignment:.leading,spacing:12){Text("المتاح لك اليوم").font(.subheadline).foregroundStyle(.secondary);Text(money(s.dailyLimit)).font(.system(size:44,weight:.bold,design:.rounded));Text(s.todaySpent>0 ? "صرفت اليوم \(money(s.todaySpent)) • باقي \(money(s.safeToday))":"ما صرفت شيء اليوم").font(.subheadline).foregroundStyle(s.todaySpent<=s.dailyLimit ? .green:.red);Button(action: { add=true }) {Label("سجّل مصروف",systemImage:"plus").font(.headline).frame(maxWidth:.infinity).padding(14)}.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius:16))}.card()
  HStack(spacing:10){SmallCard("المتبقي",money(s.remaining),"wallet.bifold");SmallCard("المصروف",money(s.spent),"arrow.up");SmallCard("الأيام","\(s.daysLeft)","calendar")}
  if s.salary<=0{Button(action: { setup=true }) {Label("أضف راتبك لبدء الخطة",systemImage:"banknote.fill").frame(maxWidth:.infinity).padding()}.buttonStyle(.borderedProminent)}
  VStack(alignment:.leading,spacing:13){HStack{Text("خطة الراتب").font(.headline);Spacer();Button("تعديل"){setup=true}};row("الراتب",s.salary);row("الالتزامات",s.fixed);row("ادخار \(Int(s.savingRate*100))٪",s.savingAmount);row("احتياطي نهاية الدورة",s.reserve);Divider();row("المتاح للصرف",s.plannedAvailable,bold:true)}.card()
  if let top=s.categoryTotals.first{VStack(alignment:.leading,spacing:8){Text("أكثر صرفك").font(.headline);HStack{Text(top.0);Spacer();Text(money(top.1)).bold()};ProgressView(value:s.spent>0 ? top.1/s.spent:0)}.card()}
  VStack(alignment:.leading,spacing:10){Text("نظرة سريعة").font(.headline);Text(insight).foregroundStyle(.secondary);ProgressView(value:s.health).tint(s.health>0.35 ? .green:.orange)}.card()
 }.padding()}.navigationBarHidden(true)}
 func row(_ t:String,_ v:Double,bold:Bool=false)->some View{HStack{Text(t).foregroundStyle(.secondary);Spacer();Text(money(v)).fontWeight(bold ? .bold:.medium)}}
 var insight:String{if s.salary<=0{return "ابدأ بإضافة راتبك. بعدها نحسب لك تلقائيًا كم تقدر تصرف كل يوم."};if s.remaining<0{return "تجاوزت المبلغ المخطط للصرف. راجع المصاريف الأخيرة أو خفّض الصرف لباقي الدورة."};if s.projectedEnd<s.reserve{return "بمعدل صرفك الحالي قد تنزل عن الاحتياطي الذي حددته."};return "أمورك ضمن الخطة. الحد اليومي يتحدث تلقائيًا بعد كل مصروف."}
}
struct SmallCard:View{let t:String,v:String,i:String;init(_ t:String,_ v:String,_ i:String){self.t=t;self.v=v;self.i=i};var body:some View{VStack(alignment:.leading,spacing:7){Image(systemName:i).foregroundStyle(.blue);Text(t).font(.caption).foregroundStyle(.secondary);Text(v).font(.subheadline.bold()).minimumScaleFactor(0.65)}.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(Color(.secondarySystemBackground),in:RoundedRectangle(cornerRadius:18))}}

struct SalarySetup: View {
    @EnvironmentObject var s: BudgetStore
    @Environment(\.dismiss) var dismiss
    @State private var salaryText = ""
    @State private var reserveText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("خلنا نضبط راتبك").font(.largeTitle.bold())
                    Text("أدخل راتبك مرة واحدة، وبعدها نحسب المتاح اليومي تلقائيًا.").foregroundStyle(.secondary)
                    InputBox(title: "صافي راتبك", text: $salaryText, icon: "banknote.fill")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("يوم نزول الراتب").font(.headline)
                        Picker("يوم الراتب", selection: $s.payday) {
                            ForEach(1...28, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel).frame(height: 100)
                    }.card()
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Text("نسبة الادخار").font(.headline); Spacer(); Text("\(Int(s.savingRate * 100))٪").bold() }
                        Slider(value: $s.savingRate, in: 0...0.5, step: 0.05)
                    }.card()
                    InputBox(title: "احتياطي نهاية الدورة", text: $reserveText, icon: "shield.fill")
                    Button(action: saveAndClose) {
                        Text("حفظ وابدأ").font(.headline).frame(maxWidth: .infinity).padding(15)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                }.padding()
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("إغلاق") { dismiss() } } }
            .onAppear {
                salaryText = s.salary > 0 ? String(Int(s.salary)) : ""
                reserveText = s.reserve > 0 ? String(Int(s.reserve)) : ""
            }
        }
    }
    private func saveAndClose() {
        if let x = Double(salaryText.replacingOccurrences(of: ",", with: "")) { s.salary = x }
        if let x = Double(reserveText.replacingOccurrences(of: ",", with: "")) { s.reserve = x }
        dismiss()
    }
}
struct InputBox:View{let title:String;@Binding var text:String;let icon:String;var body:some View{VStack(alignment:.leading,spacing:8){Text(title).font(.headline);HStack{Image(systemName:icon).foregroundStyle(.blue);TextField("0",text:$text).keyboardType(.decimalPad).font(.title2.bold());Text("ر.س").foregroundStyle(.secondary)}.padding().background(Color(.secondarySystemBackground),in:RoundedRectangle(cornerRadius:16))}}

struct TransactionsView:View{@EnvironmentObject var s:BudgetStore;@Binding var add:Bool;@State var q="";var list:[Expense]{s.cycleExpenses.sorted{$0.date>$1.date}.filter{q.isEmpty||$0.category.contains(q)||$0.note.contains(q)}};var body:some View{List{Section{Button(action: { add=true }) {Label("إضافة مصروف",systemImage:"plus.circle.fill").font(.headline)}};Section("دورة الراتب الحالية"){if list.isEmpty{ContentUnavailableView("ما عندك مصاريف",systemImage:"checkmark.circle",description:Text("سجّل أول مصروف من الزر فوق."))};ForEach(list){e in HStack{Image(systemName:icon(e.category)).foregroundStyle(.blue).frame(width:34);VStack(alignment:.leading){Text(e.category).bold();if !e.note.isEmpty{Text(e.note).font(.caption).foregroundStyle(.secondary)};Text(e.date.formatted(date:.abbreviated,time:.shortened)).font(.caption2).foregroundStyle(.tertiary)};Spacer();Text(money(e.amount)).bold()}.swipeActions{Button(role:.destructive){s.deleteExpense(e.id)}label:{Label("حذف",systemImage:"trash")}}}}}.searchable(text:$q,prompt:"ابحث").navigationTitle("المصاريف").toolbar{Button(action: { add=true }) {Image(systemName:"plus")}}};func icon(_ c:String)->String{["طعام":"fork.knife","قهوة":"cup.and.saucer.fill","وقود":"fuelpump.fill","تسوق":"bag.fill","ترفيه":"gamecontroller.fill","فواتير":"bolt.fill"][c] ?? "circle.grid.2x2.fill"}}

struct PlanView:View{@EnvironmentObject var s:BudgetStore;@State var addC=false;@State var addG=false;@State var addB=false;var body:some View{List{
 Section("ملخص"){HStack{Text("الراتب");Spacer();Text(money(s.salary)).bold()};HStack{Text("المتاح بعد الخطة");Spacer();Text(money(s.plannedAvailable)).bold().foregroundStyle(.blue)}}
 Section{ForEach(s.commitments){c in HStack{VStack(alignment:.leading){Text(c.title).bold();Text("\(c.category) • يوم \(c.dueDay)").font(.caption).foregroundStyle(.secondary)};Spacer();Text(money(c.amount))}}.onDelete{s.commitments.remove(atOffsets:$0)};Button(action: { addC=true }) {Label("إضافة التزام",systemImage:"plus")}}header:{Text("الالتزامات الشهرية")}
 Section{ForEach(s.categoryBudgets){b in VStack(alignment:.leading){HStack{Text(b.category);Spacer();Text("\(money(s.spent(in:b.category))) / \(money(b.limit))").font(.caption)};ProgressView(value:b.limit>0 ? min(1,s.spent(in:b.category)/b.limit):0)}}.onDelete{s.categoryBudgets.remove(atOffsets:$0)};Button(action: { addB=true }) {Label("حد لتصنيف",systemImage:"plus")}}header:{Text("حدود الصرف")}
 Section{ForEach(s.goals){g in VStack(alignment:.leading){HStack{Text(g.title).bold();Spacer();Text("\(money(g.current)) / \(money(g.target))").font(.caption)};ProgressView(value:g.target>0 ? min(1,g.current/g.target):0)}}.onDelete{s.goals.remove(atOffsets:$0)};Button(action: { addG=true }) {Label("هدف ادخار",systemImage:"plus")}}header:{Text("أهداف الادخار")}
 }.navigationTitle("الخطة").sheet(isPresented:$addC){AddCommitment()}.sheet(isPresented:$addG){AddGoal()}.sheet(isPresented:$addB){AddCategoryBudget()}}}

struct ReportsView:View{@EnvironmentObject var s:BudgetStore;var body:some View{ScrollView{VStack(spacing:16){VStack(alignment:.leading,spacing:10){Text("ملخص الدورة").font(.headline);HStack{SmallCard("الراتب",money(s.salary),"banknote");SmallCard("الصرف",money(s.spent),"cart");SmallCard("متوقع النهاية",money(s.projectedEnd),"flag")}}.card();VStack(alignment:.leading,spacing:12){Text("وين راحت فلوسك؟").font(.headline);if s.categoryTotals.isEmpty{Text("أضف مصاريف عشان يظهر التقرير.").foregroundStyle(.secondary).frame(maxWidth:.infinity,minHeight:120)}else{Chart(Array(s.categoryTotals.enumerated()),id:\.offset){p in SectorMark(angle:.value("المبلغ",p.element.1),innerRadius:.ratio(0.62),angularInset:2).foregroundStyle(by:.value("التصنيف",p.element.0))}.frame(height:230);ForEach(Array(s.categoryTotals.enumerated()),id:\.offset){p in HStack{Text(p.element.0);Spacer();Text(money(p.element.1)).bold();Text("\(Int(p.element.1/max(1,s.spent)*100))٪").font(.caption).foregroundStyle(.secondary)}}}}.card()}.padding()}.navigationTitle("التقارير")}}

struct AddExpense:View{@EnvironmentObject var s:BudgetStore;@Environment(\.dismiss)var dismiss;@State var amount="";@State var cat="طعام";@State var note="";@State var date=Date();var body:some View{NavigationStack{Form{Section("كم صرفت؟"){TextField("0",text:$amount).keyboardType(.decimalPad).font(.largeTitle.bold())};Section("على إيش؟"){Picker("التصنيف",selection:$cat){ForEach(cats,id:\.self){Text($0)}};TextField("ملاحظة اختيارية",text:$note);DatePicker("التاريخ",selection:$date,in:...Date())}}.navigationTitle("مصروف جديد").toolbar{ToolbarItem(placement:.cancellationAction){Button("إلغاء"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("حفظ"){if let x=Double(amount),x>0{s.expenses.append(.init(amount:x,category:cat,note:note,date:date));dismiss()}}.bold()}}}}}
struct AddCommitment:View{@EnvironmentObject var s:BudgetStore;@Environment(\.dismiss)var dismiss;@State var title="";@State var amount="";@State var cat="فواتير";@State var day=1;var body:some View{NavigationStack{Form{TextField("اسم الالتزام",text:$title);TextField("المبلغ",text:$amount).keyboardType(.decimalPad);Picker("النوع",selection:$cat){ForEach(["سكن","سيارة/تمويل","فواتير","عائلة","اشتراكات","أخرى"],id:\.self){Text($0)}};Stepper("يوم الاستحقاق: \(day)",value:$day,in:1...28)}.navigationTitle("التزام جديد").toolbar{ToolbarItem(placement:.cancellationAction){Button("إلغاء"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("حفظ"){if let x=Double(amount),x>0,!title.isEmpty{s.commitments.append(.init(title:title,amount:x,category:cat,dueDay:day));dismiss()}}}}}}}
struct AddGoal:View{@EnvironmentObject var s:BudgetStore;@Environment(\.dismiss)var dismiss;@State var title="";@State var target="";@State var current="";var body:some View{NavigationStack{Form{TextField("اسم الهدف",text:$title);TextField("المبلغ المستهدف",text:$target).keyboardType(.decimalPad);TextField("المبلغ الحالي",text:$current).keyboardType(.decimalPad)}.navigationTitle("هدف ادخار").toolbar{ToolbarItem(placement:.cancellationAction){Button("إلغاء"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("حفظ"){if let t=Double(target),t>0,!title.isEmpty{s.goals.append(.init(title:title,target:t,current:Double(current) ?? 0));dismiss()}}}}}}}
struct AddCategoryBudget:View{@EnvironmentObject var s:BudgetStore;@Environment(\.dismiss)var dismiss;@State var cat="طعام";@State var limit="";var body:some View{NavigationStack{Form{Picker("التصنيف",selection:$cat){ForEach(cats,id:\.self){Text($0)}};TextField("الحد للدورة",text:$limit).keyboardType(.decimalPad)}.navigationTitle("حد صرف").toolbar{ToolbarItem(placement:.cancellationAction){Button("إلغاء"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("حفظ"){if let x=Double(limit),x>0{s.categoryBudgets.removeAll{$0.category==cat};s.categoryBudgets.append(.init(category:cat,limit:x));dismiss()}}}}}}}
extension View{func card()->some View{padding(16).background(Color(.secondarySystemBackground),in:RoundedRectangle(cornerRadius:22,style:.continuous))}}
