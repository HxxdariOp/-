import SwiftUI
import UniformTypeIdentifiers

// MARK: - Expenses

struct ExpenseRow: View {
    let e: Expense
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: e.category.icon)
                .font(.title3)
                .foregroundColor(Color.accentOrange)
                .frame(width: 42, height: 42)
                .background(Color.accentOrange.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(e.title).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 6) {
                    Text(e.category.title).font(.caption).foregroundStyle(.secondary)
                    Pill(text: e.method.short, color: Color.amber)
                    if e.paidFromFund { Pill(text: "از صندوق", color: Color.okGreen) }
                }
            }
            Spacer(minLength: 4)
            Text(money(e.amount)).font(.subheadline.bold()).minimumScaleFactor(0.7).lineLimit(1)
        }
        .glass(radius: 20, pad: 12)
    }
}

struct ExpensesView: View {
    @EnvironmentObject var store: Store
    @State private var editing: Expense?
    @State private var showNew = false
    @State private var showTemplates = false
    @State private var message: String?

    var body: some View {
        let m = store.selectedMonth
        let list = store.expenses(in: m)
        let total = list.reduce(0.0) { $0 + $1.amount }
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("هزینه‌ها").font(.largeTitle.bold())
                    Spacer()
                    Button { showNew = true } label: { Image(systemName: "plus") }.buttonStyle(GlassIconStyle())
                }
                MonthHeader()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("جمع هزینه‌های \(m.monthName)").font(.footnote).foregroundStyle(.secondary)
                        Text(money(total)).font(.title3.bold())
                    }
                    Spacer()
                    Text("\(fnum(list.count)) مورد").font(.caption).foregroundStyle(.secondary)
                }
                .glass(tint: Color.accentOrange)
                HStack(spacing: 10) {
                    Button { showTemplates = true } label: {
                        Label("قالب‌های ماهانه", systemImage: "repeat").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                    Button {
                        let n = store.copyExpenses(from: m.prev, to: m)
                        message = n > 0 ? "\(fnum(n)) هزینه از ماه قبل کپی شد." : "هزینه جدیدی برای کپی وجود نداشت."
                    } label: {
                        Label("کپی از ماه قبل", systemImage: "doc.on.doc").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                if list.isEmpty {
                    EmptyState(icon: "tray", text: "برای این ماه هزینه‌ای ثبت نشده.\nاز دکمه + یا قالب‌های ماهانه استفاده کنید.")
                } else {
                    ForEach(list) { e in
                        Button { editing = e } label: { ExpenseRow(e: e) }.buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNew) { ExpenseEditor(existing: nil) }
        .sheet(item: $editing) { ExpenseEditor(existing: $0) }
        .sheet(isPresented: $showTemplates) { TemplatesSheet() }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("باشه", role: .cancel) {}
        }
    }
}

struct ExpenseEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let existing: Expense?
    @State private var title: String
    @State private var category: ExpenseCategory
    @State private var amount: Double
    @State private var date: Date
    @State private var method: SplitMethod
    @State private var fromFund: Bool
    @State private var note: String
    @State private var monthIndex: Int
    @State private var saveTemplate = false
    @State private var confirmDelete = false

    init(existing: Expense?) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _category = State(initialValue: existing?.category ?? .other)
        _amount = State(initialValue: existing?.amount ?? 0)
        _date = State(initialValue: existing?.date ?? Date())
        _method = State(initialValue: existing?.method ?? .equal)
        _fromFund = State(initialValue: existing?.paidFromFund ?? false)
        _note = State(initialValue: existing?.note ?? "")
        _monthIndex = State(initialValue: existing?.monthIndex ?? PMonth.current.index)
    }

    var body: some View {
        SheetScaffold(existing == nil ? "هزینه جدید" : "ویرایش هزینه",
                      canSave: amount > 0 && !title.isEmpty, onSave: save) {
            GlassSection("مشخصات") {
                TextRow(title: "عنوان", text: $title, placeholder: "مثلاً قبض برق")
                Divider()
                FormRow("دسته") {
                    Picker("", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.menu)
                }
                Divider()
                DoubleField(title: "مبلغ", value: $amount, suffix: AppFormat.currency, showMoney: true)
                Divider()
                FormRow("تاریخ") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.calendar, Calendar(identifier: .persian))
                        .environment(\.locale, Locale(identifier: "fa_IR"))
                }
                Divider()
                FormRow("بابت ماه") { MonthStepper(index: $monthIndex) }
            }
            GlassSection("نحوه تقسیم بین واحدها") {
                FormRow("روش") {
                    Picker("", selection: $method) {
                        ForEach(SplitMethod.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.menu)
                }
                if amount > 0 && !fromFund {
                    Text("میانگین سهم هر واحد: \(money(amount / Double(max(store.activeUnits.count, 1))))")
                        .font(.caption).foregroundColor(Color.accentOrange)
                }
                Divider()
                FormRow("پرداخت از صندوق ذخیره") { Toggle("", isOn: $fromFund).labelsHidden() }
                Text("اگر فعال باشد، این هزینه به ساکنان تقسیم نمی‌شود و از موجودی صندوق کم می‌شود.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            GlassSection("توضیحات") {
                TextRow(title: "یادداشت", text: $note)
                if existing == nil {
                    Divider()
                    FormRow("ذخیره به‌عنوان قالب ماهانه") { Toggle("", isOn: $saveTemplate).labelsHidden() }
                }
            }
            if existing != nil {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("حذف هزینه", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .onAppear {
            if existing == nil {
                monthIndex = store.selectedMonth.index
                method = store.data.building.defaultMethod
            }
        }
        .alert("این هزینه حذف شود؟", isPresented: $confirmDelete) {
            Button("حذف", role: .destructive) {
                if let e = existing { store.delete(expense: e) }
                dismiss()
            }
            Button("انصراف", role: .cancel) {}
        }
    }

    func save() {
        var e = existing ?? Expense(monthIndex: monthIndex, title: title, category: category,
                                    amount: amount, date: date, method: method)
        e.monthIndex = monthIndex
        e.title = title
        e.category = category
        e.amount = amount
        e.date = date
        e.method = method
        e.paidFromFund = fromFund
        e.note = note
        store.upsert(expense: e)
        if saveTemplate && existing == nil {
            store.upsert(template: RecurringTemplate(title: title, category: category, amount: amount, method: method))
        }
    }
}

struct TemplatesSheet: View {
    @EnvironmentObject var store: Store
    @State private var editing: RecurringTemplate?
    @State private var showNew = false
    @State private var message: String?

    var body: some View {
        SheetScaffold("قالب‌های ماهانه", saveTitle: "تمام", onSave: {}) {
            Text("هزینه‌های ثابت هر ماه (مثل نظافت و نگهبان) را یک بار تعریف کنید و با یک لمس به ماه انتخاب‌شده اضافه کنید. قالب‌های با مبلغ صفر اضافه نمی‌شوند.")
                .font(.caption).foregroundStyle(.secondary)
            if store.data.templates.isEmpty {
                EmptyState(icon: "repeat", text: "قالبی تعریف نشده است.")
            }
            ForEach(store.data.templates) { t in
                Button { editing = t } label: {
                    HStack(spacing: 12) {
                        Image(systemName: t.category.icon).foregroundColor(Color.accentOrange).frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.title).font(.subheadline.bold())
                            Text(t.method.short).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(t.amount > 0 ? money(t.amount) : "مبلغ؟").font(.subheadline)
                            .foregroundColor(t.amount > 0 ? Color.white : Color.badRed)
                        if !t.active { Pill(text: "غیرفعال", color: Color.gray) }
                    }
                    .glass(radius: 18, pad: 12)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                Button { showNew = true } label: {
                    Label("قالب جدید", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                Button {
                    let n = store.applyTemplates(to: store.selectedMonth)
                    message = n > 0 ? "\(fnum(n)) هزینه به \(store.selectedMonth.title) اضافه شد."
                                    : "موردی برای افزودن نبود (قبلاً اضافه شده یا مبلغ صفر است)."
                } label: {
                    Label("افزودن به این ماه", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(prominent: true))
            }
            if let message {
                Text(message).font(.footnote).foregroundColor(Color.okGreen)
            }
        }
        .sheet(isPresented: $showNew) { TemplateEditor(existing: nil) }
        .sheet(item: $editing) { TemplateEditor(existing: $0) }
    }
}

struct TemplateEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let existing: RecurringTemplate?
    @State private var title: String
    @State private var category: ExpenseCategory
    @State private var amount: Double
    @State private var method: SplitMethod
    @State private var active: Bool

    init(existing: RecurringTemplate?) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _category = State(initialValue: existing?.category ?? .other)
        _amount = State(initialValue: existing?.amount ?? 0)
        _method = State(initialValue: existing?.method ?? .equal)
        _active = State(initialValue: existing?.active ?? true)
    }

    var body: some View {
        SheetScaffold(existing == nil ? "قالب جدید" : "ویرایش قالب", canSave: !title.isEmpty, onSave: save) {
            GlassSection {
                TextRow(title: "عنوان", text: $title)
                Divider()
                FormRow("دسته") {
                    Picker("", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.menu)
                }
                Divider()
                DoubleField(title: "مبلغ ماهانه", value: $amount, suffix: AppFormat.currency, showMoney: true)
                Divider()
                FormRow("روش تقسیم") {
                    Picker("", selection: $method) {
                        ForEach(SplitMethod.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.menu)
                }
                Divider()
                FormRow("فعال") { Toggle("", isOn: $active).labelsHidden() }
            }
            if existing != nil {
                Button(role: .destructive) {
                    if let e = existing { store.delete(template: e) }
                    dismiss()
                } label: {
                    Label("حذف قالب", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }

    func save() {
        var t = existing ?? RecurringTemplate(title: title, category: category, amount: amount, method: method)
        t.title = title
        t.category = category
        t.amount = amount
        t.method = method
        t.active = active
        store.upsert(template: t)
    }
}

// MARK: - Payments

struct PaymentsView: View {
    @EnvironmentObject var store: Store
    @State private var showNew = false
    @State private var editing: Payment?

    var body: some View {
        let m = store.selectedMonth
        let list = store.payments(in: m)
        let total = list.reduce(0.0) { $0 + $1.amount }
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("پرداخت‌ها").font(.largeTitle.bold())
                    Spacer()
                    Button { showNew = true } label: { Image(systemName: "plus") }.buttonStyle(GlassIconStyle())
                }
                MonthHeader()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("وصولی بابت \(m.monthName)").font(.footnote).foregroundStyle(.secondary)
                        Text(money(total)).font(.title3.bold()).foregroundColor(Color.okGreen)
                    }
                    Spacer()
                    Text("\(fnum(list.count)) پرداخت").font(.caption).foregroundStyle(.secondary)
                }
                .glass(tint: Color.okGreen)
                if list.isEmpty {
                    EmptyState(icon: "banknote", text: "برای این ماه پرداختی ثبت نشده.")
                } else {
                    ForEach(list) { p in
                        Button { editing = p } label: { paymentRow(p) }.buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNew) { PaymentEditor(existing: nil, unitID: nil) }
        .sheet(item: $editing) { PaymentEditor(existing: $0, unitID: nil) }
    }

    func paymentRow(_ p: Payment) -> some View {
        let u = store.unit(p.unitID)
        return HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill").font(.title2).foregroundColor(Color.okGreen)
            VStack(alignment: .leading, spacing: 3) {
                Text("واحد \(fnum(u?.number ?? 0)) · \(u?.fullName ?? "حذف‌شده")").font(.subheadline.bold()).lineLimit(1)
                Text("\(shortDate(p.date)) · \(p.method.title)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text(money(p.amount)).font(.subheadline.bold()).minimumScaleFactor(0.7).lineLimit(1)
        }
        .glass(radius: 20, pad: 12)
    }
}

struct PaymentEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let existing: Payment?
    @State private var unitID: UUID?
    @State private var forMonth: Int
    @State private var amount: Double
    @State private var date: Date
    @State private var method: PayMethod
    @State private var ref: String
    @State private var note: String
    @State private var confirmDelete = false

    init(existing: Payment?, unitID: UUID?) {
        self.existing = existing
        _unitID = State(initialValue: existing?.unitID ?? unitID)
        _forMonth = State(initialValue: existing?.forMonth ?? PMonth.current.index)
        _amount = State(initialValue: existing?.amount ?? 0)
        _date = State(initialValue: existing?.date ?? Date())
        _method = State(initialValue: existing?.method ?? .card)
        _ref = State(initialValue: existing?.refNo ?? "")
        _note = State(initialValue: existing?.note ?? "")
    }

    var remaining: Double? {
        guard let id = unitID, let s = store.statement(unitID: id, month: PMonth(index: forMonth)) else { return nil }
        return s.remaining
    }

    var body: some View {
        SheetScaffold(existing == nil ? "ثبت پرداخت" : "ویرایش پرداخت",
                      canSave: amount > 0 && unitID != nil, onSave: save) {
            GlassSection("پرداخت‌کننده") {
                FormRow("واحد") {
                    Picker("", selection: $unitID) {
                        Text("انتخاب کنید").tag(UUID?.none)
                        ForEach(store.activeUnits) { u in
                            Text("واحد \(fnum(u.number)) – \(u.fullName)").tag(UUID?.some(u.id))
                        }
                    }
                    .labelsHidden().pickerStyle(.menu)
                }
                Divider()
                FormRow("بابت ماه") { MonthStepper(index: $forMonth) }
                if let r = remaining {
                    Divider()
                    HStack {
                        Text(r > 0.5 ? "مانده این ماه: \(money(r))" : "این ماه تسویه است")
                            .font(.caption).foregroundColor(r > 0.5 ? Color.badRed : Color.okGreen)
                        Spacer()
                        if r > 0.5 {
                            Button("پر کردن با مانده") { amount = r.rounded() }
                                .font(.caption.bold()).foregroundColor(Color.accentOrange)
                        }
                    }
                }
            }
            GlassSection("جزئیات پرداخت") {
                DoubleField(title: "مبلغ", value: $amount, suffix: AppFormat.currency, showMoney: true)
                Divider()
                FormRow("تاریخ") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.calendar, Calendar(identifier: .persian))
                        .environment(\.locale, Locale(identifier: "fa_IR"))
                }
                Divider()
                FormRow("روش پرداخت") {
                    Picker("", selection: $method) {
                        ForEach(PayMethod.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.menu)
                }
                Divider()
                TextRow(title: "شماره پیگیری", text: $ref, keyboard: .numbersAndPunctuation)
                Divider()
                TextRow(title: "توضیحات", text: $note)
            }
            if existing != nil {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("حذف پرداخت", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .onAppear {
            if existing == nil {
                forMonth = store.selectedMonth.index
                if unitID == nil { unitID = store.activeUnits.first?.id }
                if let r = remaining, r > 0.5, amount == 0 { amount = r.rounded() }
            }
        }
        .alert("این پرداخت حذف شود؟", isPresented: $confirmDelete) {
            Button("حذف", role: .destructive) {
                if let e = existing { store.delete(payment: e) }
                dismiss()
            }
            Button("انصراف", role: .cancel) {}
        }
    }

    func save() {
        guard let uid = unitID else { return }
        var p = existing ?? Payment(unitID: uid, forMonth: forMonth, amount: amount, date: date, method: method)
        p.unitID = uid
        p.forMonth = forMonth
        p.amount = amount
        p.date = date
        p.method = method
        p.refNo = ref
        p.note = note
        store.upsert(payment: p)
    }
}

// MARK: - More

struct MoreLink<Dest: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let dest: Dest
    var body: some View {
        NavigationLink {
            dest
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).foregroundColor(Color.accentOrange).frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold())
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.forward").font(.caption).foregroundStyle(.secondary)
            }
            .glass(radius: 20, pad: 14)
        }
        .buttonStyle(.plain)
    }
}

struct MoreView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("بیشتر").font(.largeTitle.bold())
                    Spacer()
                }
                MoreLink(icon: "doc.text.magnifyingglass", title: "گزارش‌ها",
                         subtitle: "مبلغ واریزی هر واحد، بدهکاران، خروجی اکسل",
                         dest: ReportsView())
                MoreLink(icon: "lock.shield.fill", title: "صندوق و تراز مالی",
                         subtitle: "موجودی حساب، ذخیره صندوق، روند ماهانه",
                         dest: FundView())
                MoreLink(icon: "gearshape.fill", title: "تنظیمات",
                         subtitle: "اطلاعات ساختمان، روش محاسبه، پشتیبان‌گیری",
                         dest: SettingsView())
                MoreLink(icon: "questionmark.circle.fill", title: "راهنما",
                         subtitle: "روش‌های تقسیم شارژ و نکات قانونی",
                         dest: HelpView())
            }
            .padding()
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Reports

struct ReportsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let m = store.selectedMonth
        let sts = store.statements(for: m)
        ScrollView {
            VStack(spacing: 14) {
                MonthHeader()
                HStack(spacing: 10) {
                    ShareLink(item: store.payableListText(m)) {
                        Label("ارسال فهرست واریزی", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(prominent: true))
                    ShareLink(item: store.csvFile(m), preview: SharePreview("خروجی اکسل \(m.title)")) {
                        Label("خروجی CSV", systemImage: "tablecells").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                GlassSection("مبلغ واریزی هر واحد در \(m.monthName)") {
                    ForEach(sts) { s in
                        HStack {
                            Text(fnum(s.unit.number))
                                .font(.caption.bold())
                                .frame(width: 28, height: 28)
                                .background(Color.accentOrange.opacity(0.2))
                                .clipShape(Circle())
                            Text(s.unit.fullName).font(.subheadline).lineLimit(1)
                            Spacer()
                            if s.remaining > 0.5 {
                                Text(money(s.remaining)).font(.subheadline.bold())
                            } else {
                                Pill(text: "تسویه", color: Color.okGreen)
                            }
                        }
                    }
                    Divider()
                    HStack {
                        Text("جمع مانده").font(.subheadline.bold())
                        Spacer()
                        Text(money(sts.reduce(0.0) { $0 + max($1.remaining, 0) })).font(.subheadline.bold())
                            .foregroundColor(Color.accentOrange)
                    }
                }
                let totals = store.categoryTotals(m)
                if !totals.isEmpty {
                    GlassSection("هزینه‌ها بر اساس دسته") {
                        ForEach(totals, id: \.0) { item in
                            HStack {
                                Label(item.0.title, systemImage: item.0.icon).font(.subheadline)
                                Spacer()
                                Text(money(item.1)).font(.subheadline)
                            }
                        }
                    }
                }
                ShareLink(item: store.debtorsText(m)) {
                    Label("ارسال لیست بدهکاران", systemImage: "exclamationmark.bubble").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("گزارش‌ها")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Fund

struct FundView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let m = store.selectedMonth
        let months = (0..<12).map { PMonth(index: m.index - $0) }.filter { $0.index >= store.data.building.startMonth }
        ScrollView {
            VStack(spacing: 14) {
                MonthHeader()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(icon: "banknote.fill", title: "موجودی حساب ساختمان",
                             value: money(store.cashBalance(upTo: m)), tint: Color.okGreen)
                    StatTile(icon: "lock.shield.fill", title: "صندوق ذخیره (تعهدی)",
                             value: money(store.fundBalance(upTo: m)), tint: Color.amber)
                }
                Text("موجودی حساب = موجودی اولیه + کل پرداخت‌های دریافتی − کل هزینه‌ها. صندوق ذخیره بر اساس سهم صندوقِ محاسبه‌شده در شارژها حساب می‌شود و پرداخت‌نشدن شارژ را لحاظ نمی‌کند.")
                    .font(.caption).foregroundStyle(.secondary)
                GlassSection("روند ماه‌های اخیر") {
                    HStack {
                        Text("ماه").frame(maxWidth: .infinity, alignment: .leading)
                        Text("هزینه").frame(maxWidth: .infinity)
                        Text("وصولی").frame(maxWidth: .infinity)
                        Text("مانده").frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(months, id: \.index) { x in
                        let s = store.summary(for: x)
                        HStack {
                            Text(x.monthName).frame(maxWidth: .infinity, alignment: .leading)
                            Text(compact(s.expenses + s.fundExpenses)).frame(maxWidth: .infinity)
                            Text(compact(s.collected)).foregroundColor(Color.okGreen).frame(maxWidth: .infinity)
                            Text(compact(s.remaining)).foregroundColor(s.remaining > 0.5 ? Color.badRed : Color.okGreen)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(.caption)
                    }
                    if months.isEmpty {
                        Text("هنوز داده‌ای ثبت نشده.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("صندوق و تراز")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    func compact(_ v: Double) -> String {
        if abs(v) >= 1_000_000 { return String(format: "%.1f", v / 1_000_000).fa + " م" }
        if abs(v) >= 1000 { return fnum(Int((v / 1000).rounded())) + " هزار" }
        return fnum(Int(v.rounded()))
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var showImport = false
    @State private var showReset = false
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassSection("اطلاعات ساختمان") {
                    TextRow(title: "نام ساختمان", text: $store.data.building.name)
                    Divider()
                    TextRow(title: "آدرس", text: $store.data.building.address)
                    Divider()
                    TextRow(title: "نام مدیر", text: $store.data.building.managerName)
                    Divider()
                    TextRow(title: "تلفن مدیر", text: $store.data.building.managerPhone, keyboard: .phonePad)
                }
                GlassSection("اطلاعات پرداخت (در صورت‌حساب‌ها درج می‌شود)") {
                    TextRow(title: "شماره کارت", text: $store.data.building.cardNumber, keyboard: .numbersAndPunctuation)
                    Divider()
                    TextRow(title: "به نام", text: $store.data.building.cardOwner)
                    Divider()
                    TextRow(title: "شماره شبا", text: $store.data.building.sheba, keyboard: .numbersAndPunctuation)
                }
                GlassSection("روش محاسبه شارژ") {
                    FormRow("روش پیش‌فرض") {
                        Picker("", selection: $store.data.building.defaultMethod) {
                            ForEach(SplitMethod.allCases) { Text($0.title).tag($0) }
                        }
                        .labelsHidden().pickerStyle(.menu)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("سهم متراژ در روش ترکیبی: \(pct(store.data.building.mixAreaWeight)) (نفرات: \(pct(1 - store.data.building.mixAreaWeight)))")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Slider(value: $store.data.building.mixAreaWeight, in: 0...1, step: 0.05)
                    }
                    Divider()
                    FormRow("سهم صندوق ذخیره") {
                        Stepper("\(fnum(Int(store.data.building.fundPercent)))٪ از هزینه‌ها",
                                value: $store.data.building.fundPercent, in: 0...50, step: 1)
                    }
                    Divider()
                    FormRow("گرد کردن شارژ هر واحد") {
                        Picker("", selection: $store.data.building.roundTo) {
                            Text("بدون گرد کردن").tag(1.0)
                            Text("۱۰۰").tag(100.0)
                            Text("۱٬۰۰۰").tag(1000.0)
                            Text("۱۰٬۰۰۰").tag(10000.0)
                        }
                        .labelsHidden().pickerStyle(.menu)
                    }
                    Divider()
                    FormRow("جریمه تأخیر ماهانه") {
                        Stepper("\(String(store.data.building.lateFeePercent).fa)٪ از بدهی",
                                value: $store.data.building.lateFeePercent, in: 0...10, step: 0.5)
                    }
                    Divider()
                    FormRow("مهلت پرداخت (روز ماه)") {
                        Stepper(fnum(store.data.building.dueDay), value: $store.data.building.dueDay, in: 1...30)
                    }
                    Divider()
                    FormRow("واحد پول") {
                        Picker("", selection: $store.data.building.currency) {
                            Text("تومان").tag("تومان")
                            Text("ریال").tag("ریال")
                        }
                        .labelsHidden().pickerStyle(.segmented).frame(maxWidth: 140)
                    }
                }
                GlassSection("شروع حساب‌وکتاب") {
                    FormRow("ماه شروع") { MonthStepper(index: $store.data.building.startMonth) }
                    Divider()
                    DoubleField(title: "موجودی اولیه حساب", value: $store.data.building.openingCash,
                                suffix: AppFormat.currency, showMoney: true)
                    Divider()
                    DoubleField(title: "موجودی اولیه صندوق", value: $store.data.building.fundOpening,
                                suffix: AppFormat.currency, showMoney: true)
                }
                GlassSection("داده‌ها") {
                    ShareLink(item: store.backupFile(), preview: SharePreview("پشتیبان شارژ ساختمان")) {
                        Label("گرفتن نسخه پشتیبان", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(prominent: true))
                    Button { showImport = true } label: {
                        Label("بازیابی از نسخه پشتیبان", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                    Button { store.loadDemo(); message = "داده نمونه بارگذاری شد." } label: {
                        Label("بارگذاری داده نمونه", systemImage: "sparkles").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                    Button(role: .destructive) { showReset = true } label: {
                        Label("پاک کردن همه اطلاعات", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                    Text("اطلاعات فقط روی همین گوشی ذخیره می‌شود؛ پیشنهاد می‌شود هر ماه یک نسخه پشتیبان بگیرید.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("تنظیمات")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fileImporter(isPresented: $showImport, allowedContentTypes: [UTType.json]) { result in
            if case .success(let url) = result {
                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }
                do {
                    try store.restore(from: url)
                    message = "اطلاعات با موفقیت بازیابی شد."
                } catch {
                    message = "فایل پشتیبان معتبر نیست."
                }
            }
        }
        .alert("همه اطلاعات پاک شود؟ این کار قابل بازگشت نیست.", isPresented: $showReset) {
            Button("پاک کردن", role: .destructive) { store.resetAll() }
            Button("انصراف", role: .cancel) {}
        }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("باشه", role: .cancel) {}
        }
    }
}

// MARK: - Help

struct HelpView: View {
    func block(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.bold()).foregroundColor(Color.accentOrange)
            Text(text).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(radius: 20)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                block("روش‌های تقسیم شارژ",
                      "مساوی: کل هزینه بین واحدها برابر تقسیم می‌شود؛ مناسب ساختمان‌هایی با واحدهای هم‌اندازه.\nمتراژ: سهم هر واحد متناسب با زیربنای آن است.\nنفرات: متناسب با تعداد ساکنان؛ مناسب هزینه‌هایی مثل آب.\nترکیبی: ترکیب وزنی متراژ و نفرات (وزن را در تنظیمات تعیین کنید).\nپارکینگ: متناسب با تعداد پارکینگ؛ مناسب هزینه‌های مربوط به پارکینگ.")
                block("نکات قانونی",
                      "طبق قانون تملک آپارتمان‌ها، پرداخت هزینه‌های مشترک برای همه مالکان الزامی است، حتی اگر از قسمت‌های مشترک استفاده نکنند. طبق تبصره ۲ ماده ۴، اگر مالکانِ دارای اکثریت زیربنا موافق باشند و نرخ در مجمع عمومی تصویب شود، هزینه‌ها بر اساس زیربنای اختصاصی هر واحد محاسبه می‌شود. روش و نرخ نهایی را مجمع عمومی ساختمان تعیین می‌کند؛ این برنامه مشاوره حقوقی نیست.")
                block("گردش کار پیشنهادی ماهانه",
                      "۱) هزینه‌های ثابت را از «قالب‌های ماهانه» اضافه کنید.\n۲) قبض‌ها و هزینه‌های متغیر را ثبت کنید.\n۳) در تب «واحدها» مبلغ هر نفر را ببینید و از «گزارش‌ها» فهرست واریزی را برای گروه ساختمان بفرستید.\n۴) با هر واریزی، پرداخت را ثبت کنید.\n۵) آخر ماه لیست بدهکاران را ارسال و نسخه پشتیبان را ذخیره کنید.")
                block("تراز و جریمه تأخیر",
                      "مانده هر ماه به ماه بعد منتقل می‌شود. اگر جریمه تأخیر را در تنظیمات فعال کنید، هر ماه درصدی از بدهی ماه قبل به شارژ اضافه می‌شود. پرداخت اضافه، به‌صورت بستانکاری به ماه بعد می‌رود.")
                block("معافیت واحدها",
                      "در ویرایش هر واحد می‌توانید آن را از یک دسته هزینه (مثلاً آسانسور برای همکف) معاف کنید؛ فقط در صورتی که مجمع عمومی چنین تصمیمی گرفته باشد.")
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("راهنما")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
