import SwiftUI

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject var store: Store
    @State private var showExpense = false
    @State private var showPayment = false

    var body: some View {
        let m = store.selectedMonth
        let sum = store.summary(for: m)
        let sts = store.statements(for: m)
        ScrollView {
            VStack(spacing: 16) {
                header
                MonthHeader()
                hero(sum)
                tiles(sum, m)
                statusCard(sum)
                categoryCard(m)
                debtors(sts)
                HStack(spacing: 10) {
                    Button { showExpense = true } label: {
                        Label("هزینه جدید", systemImage: "minus.circle.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                    Button { showPayment = true } label: {
                        Label("ثبت پرداخت", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(prominent: true))
                }
                ShareLink(item: store.debtorsText(m)) {
                    Label("ارسال لیست بدهکاران", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding()
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showExpense) { ExpenseEditor(existing: nil) }
        .sheet(isPresented: $showPayment) { PaymentEditor(existing: nil, unitID: nil) }
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("مدیریت شارژ").font(.footnote).foregroundStyle(.secondary)
                Text(store.data.building.name).font(.title2.bold())
            }
            Spacer()
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [Color.amber, Color.deepOrange],
                                                startPoint: .top, endPoint: .bottom))
        }
    }

    @ViewBuilder func hero(_ s: MonthSummary) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RingProgress(progress: s.rate, lineWidth: 12)
                VStack(spacing: 0) {
                    Text(pct(s.rate)).font(.title2.bold())
                    Text("وصول").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 112, height: 112)
            VStack(alignment: .leading, spacing: 6) {
                Text("جمع شارژ \(store.selectedMonth.monthName)").font(.footnote).foregroundStyle(.secondary)
                Text(money(s.charge)).font(.title3.bold()).minimumScaleFactor(0.6).lineLimit(1)
                Divider().overlay(Color.white.opacity(0.15))
                Text("وصول‌شده: \(money(s.collected))").font(.footnote).foregroundColor(Color.okGreen)
                Text("مانده: \(money(s.remaining))").font(.footnote)
                    .foregroundColor(s.remaining > 0.5 ? Color.badRed : Color.okGreen)
            }
            Spacer(minLength: 0)
        }
        .glass(tint: Color.accentOrange)
    }

    @ViewBuilder func tiles(_ s: MonthSummary, _ m: PMonth) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(icon: "cart.fill", title: "هزینه‌های ماه", value: money(s.expenses + s.fundExpenses))
            StatTile(icon: "banknote.fill", title: "موجودی حساب ساختمان",
                     value: money(store.cashBalance(upTo: m)), tint: Color.okGreen)
            StatTile(icon: "lock.shield.fill", title: "صندوق ذخیره",
                     value: money(store.fundBalance(upTo: m)), tint: Color.amber)
            StatTile(icon: "checkmark.seal.fill", title: "واحدهای تسویه‌شده",
                     value: "\(fnum(s.paid)) از \(fnum(s.count))", tint: Color.okGreen)
        }
    }

    @ViewBuilder func statusCard(_ s: MonthSummary) -> some View {
        HStack(spacing: 8) {
            statusItem("تسویه", s.paid, Color.okGreen)
            statusItem("ناقص", s.partial, Color.amber)
            statusItem("پرداخت‌نشده", s.unpaid, Color.badRed)
        }
    }

    func statusItem(_ title: String, _ n: Int, _ c: Color) -> some View {
        VStack(spacing: 4) {
            Text(fnum(n)).font(.title2.bold()).foregroundColor(c)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glass(radius: 18, pad: 12)
    }

    @ViewBuilder func categoryCard(_ m: PMonth) -> some View {
        let totals = store.categoryTotals(m)
        let sum = totals.reduce(0.0) { $0 + $1.1 }
        if !totals.isEmpty {
            GlassSection("هزینه‌ها بر اساس دسته") {
                ForEach(totals, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(item.0.title, systemImage: item.0.icon).font(.subheadline)
                            Spacer()
                            Text(money(item.1)).font(.subheadline.bold())
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(colors: [Color.amber, Color.deepOrange],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: g.size.width * CGFloat(sum > 0 ? item.1 / sum : 0))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    @ViewBuilder func debtors(_ sts: [UnitStatement]) -> some View {
        let list = sts.filter { $0.remaining > 0.5 }.sorted { $0.remaining > $1.remaining }.prefix(5)
        if !list.isEmpty {
            GlassSection("بیشترین مانده‌ها") {
                ForEach(Array(list)) { s in
                    NavigationLink(value: s.unit.id) {
                        HStack {
                            Text("واحد \(fnum(s.unit.number))").font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.accentOrange.opacity(0.2)).clipShape(Capsule())
                            Text(s.unit.fullName).font(.subheadline)
                            Spacer()
                            Text(money(s.remaining)).font(.subheadline.bold()).foregroundColor(Color.badRed)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Units list

struct UnitRow: View {
    let s: UnitStatement
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color.amber, Color.deepOrange],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(fnum(s.unit.number)).font(.headline).foregroundColor(Color.black)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.unit.fullName).font(.subheadline.bold()).lineLimit(1)
                Text("طبقه \(fnum(s.unit.floor)) · \(fnum(Int(s.unit.area))) متر · \(fnum(s.unit.residents)) نفر")
                    .font(.caption).foregroundStyle(.secondary)
                if s.unit.isTenant { Pill(text: "مستأجر", color: Color.amber) }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                if s.remaining > 0.5 {
                    Text(money(s.remaining)).font(.subheadline.bold()).minimumScaleFactor(0.7).lineLimit(1)
                } else if s.remaining < -0.5 {
                    Text("بستانکار \(money(-s.remaining))").font(.caption.bold()).foregroundColor(Color.okGreen)
                }
                Pill(text: s.status.title, color: s.status.color)
            }
        }
        .glass(radius: 20, pad: 12)
    }
}

struct UnitsView: View {
    @EnvironmentObject var store: Store
    @State private var search = ""
    @State private var filter = 0
    @State private var showAdd = false

    var rows: [UnitStatement] {
        store.statements(for: store.selectedMonth).filter { s in
            let q = search.en
            let matchSearch = q.isEmpty || s.unit.fullName.contains(search) || String(s.unit.number) == q
            let matchFilter: Bool
            switch filter {
            case 1: matchFilter = s.remaining > 0.5
            case 2: matchFilter = s.remaining <= 0.5
            default: matchFilter = true
            }
            return matchSearch && matchFilter
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("واحدها").font(.largeTitle.bold())
                    Spacer()
                    Button { showAdd = true } label: { Image(systemName: "plus") }.buttonStyle(GlassIconStyle())
                }
                MonthHeader()
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("جستجوی نام یا شماره واحد", text: $search)
                }
                .glass(radius: 16, pad: 12)
                Picker("", selection: $filter) {
                    Text("همه").tag(0)
                    Text("بدهکار").tag(1)
                    Text("تسویه").tag(2)
                }
                .pickerStyle(.segmented)

                let list = rows
                if list.isEmpty {
                    EmptyState(icon: "building.2", text: "واحدی پیدا نشد.")
                } else {
                    ForEach(list) { s in
                        NavigationLink(value: s.unit.id) { UnitRow(s: s) }.buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAdd) {
            UnitEditor(existing: nil, nextNumber: (store.data.units.map { $0.number }.max() ?? 0) + 1)
        }
    }
}

// MARK: - Unit detail

struct UnitDetailView: View {
    let unitID: UUID
    @EnvironmentObject var store: Store
    @State private var showPay = false
    @State private var showEdit = false
    @State private var payToDelete: Payment?

    var body: some View {
        ZStack {
            AppBackground()
            if let s = store.statement(unitID: unitID, month: store.selectedMonth) {
                content(s)
            } else if let u = store.unit(unitID) {
                VStack(spacing: 14) {
                    EmptyState(icon: "pause.circle", text: "واحد \(fnum(u.number)) (\(u.fullName)) غیرفعال است و در محاسبه شارژ نمی‌آید.")
                    Button("ویرایش واحد") { showEdit = true }.buttonStyle(GlassButtonStyle(prominent: true))
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEdit) { UnitEditor(existing: store.unit(unitID)) }
        .sheet(isPresented: $showPay) { PaymentEditor(existing: nil, unitID: unitID) }
        .alert("حذف این پرداخت؟", isPresented: Binding(get: { payToDelete != nil },
                                                      set: { if !$0 { payToDelete = nil } })) {
            Button("حذف", role: .destructive) {
                if let p = payToDelete { store.delete(payment: p) }
                payToDelete = nil
            }
            Button("انصراف", role: .cancel) { payToDelete = nil }
        }
    }

    @ViewBuilder func content(_ s: UnitStatement) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard(s)
                MonthHeader()
                breakdown(s)
                paymentsCard(s)
                historyCard(s)
                HStack(spacing: 10) {
                    Button { showPay = true } label: {
                        Label("ثبت پرداخت", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(prominent: true))
                    ShareLink(item: store.receiptText(s)) {
                        Label("ارسال صورت‌حساب", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
            .padding()
        }
    }

    @ViewBuilder func headerCard(_ s: UnitStatement) -> some View {
        let u = s.unit
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color.amber, Color.deepOrange],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(fnum(u.number)).font(.title2.bold()).foregroundColor(Color.black)
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text(u.fullName).font(.title3.bold())
                    Text("طبقه \(fnum(u.floor)) · \(fnum(Int(u.area))) متر · \(fnum(u.residents)) نفر · \(fnum(u.parking)) پارکینگ")
                        .font(.caption).foregroundStyle(.secondary)
                    if u.isTenant {
                        Text("مستأجر" + (u.ownerName.isEmpty ? "" : " · مالک: \(u.ownerName)"))
                            .font(.caption).foregroundColor(Color.amber)
                    }
                }
                Spacer()
                Button { showEdit = true } label: { Image(systemName: "pencil") }.buttonStyle(GlassIconStyle())
            }
            HStack {
                Pill(text: s.status.title, color: s.status.color)
                Spacer()
                if !u.phone.isEmpty {
                    if let tel = URL(string: "tel:\(u.phone.en)") {
                        Link(destination: tel) { Image(systemName: "phone.fill") }.buttonStyle(GlassIconStyle())
                    }
                    if let sms = URL(string: "sms:\(u.phone.en)") {
                        Link(destination: sms) { Image(systemName: "message.fill") }.buttonStyle(GlassIconStyle())
                    }
                }
            }
        }
        .glass(tint: s.status.color)
    }

    @ViewBuilder func breakdown(_ s: UnitStatement) -> some View {
        GlassSection("صورت‌حساب \(s.month.title)") {
            ForEach(store.mergedLines(s), id: \.0) { item in
                HStack {
                    Text(item.0).font(.subheadline)
                    Spacer()
                    Text(money(item.1)).font(.subheadline)
                }
            }
            if s.lines.isEmpty { Text("برای این ماه هزینه‌ای ثبت نشده است.").font(.footnote).foregroundStyle(.secondary) }
            if s.fundShare > 0 { row("سهم صندوق ذخیره", s.fundShare) }
            if s.lateFee > 0 { row("جریمه تأخیر", s.lateFee, Color.badRed) }
            if abs(s.roundingAdj) >= 1 { row("گرد کردن", s.roundingAdj) }
            Divider()
            row("شارژ این ماه", s.charge, Color.white, bold: true)
            if abs(s.previousBalance) > 0.5 {
                row(s.previousBalance > 0 ? "بدهی ماه‌های قبل" : "بستانکاری قبلی", abs(s.previousBalance),
                    s.previousBalance > 0 ? Color.badRed : Color.okGreen)
            }
            row("جمع قابل پرداخت", s.due, Color.accentOrange, bold: true)
            row("پرداخت‌شده", s.paid, Color.okGreen)
            Divider()
            HStack {
                Text(s.remaining >= -0.5 ? "مانده" : "بستانکاری").font(.headline)
                Spacer()
                Text(money(abs(s.remaining))).font(.title3.bold())
                    .foregroundColor(s.remaining > 0.5 ? Color.badRed : Color.okGreen)
            }
        }
    }

    func row(_ t: String, _ v: Double, _ c: Color = Color.white, bold: Bool = false) -> some View {
        HStack {
            Text(t).font(bold ? .subheadline.bold() : .subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(money(v)).font(bold ? .subheadline.bold() : .subheadline).foregroundColor(c)
        }
    }

    @ViewBuilder func paymentsCard(_ s: UnitStatement) -> some View {
        let list = store.data.payments.filter { $0.unitID == unitID && $0.forMonth == s.month.index }
            .sorted { $0.date > $1.date }
        GlassSection("پرداخت‌های این ماه") {
            if list.isEmpty {
                Text("هنوز پرداختی ثبت نشده.").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(list) { p in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(money(p.amount)).font(.subheadline.bold())
                        Text("\(shortDate(p.date)) · \(p.method.title)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { payToDelete = p } label: { Image(systemName: "trash") }
                        .buttonStyle(GlassIconStyle())
                }
            }
        }
    }

    @ViewBuilder func historyCard(_ s: UnitStatement) -> some View {
        let start = store.data.building.startMonth
        let months = (0..<6).map { PMonth(index: s.month.index - $0) }.filter { $0.index >= start }
        if months.count > 1 {
            GlassSection("سوابق ماه‌های اخیر") {
                ForEach(months, id: \.index) { m in
                    if let x = store.statement(unitID: unitID, month: m) {
                        HStack {
                            Text(m.title).font(.subheadline)
                            Spacer()
                            Text(money(x.charge, unit: false)).font(.caption).foregroundStyle(.secondary)
                            Pill(text: x.status.title, color: x.status.color)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Unit editor

struct UnitEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let existing: BUnit?
    @State private var number: Double
    @State private var floor: Double
    @State private var first: String
    @State private var last: String
    @State private var phone: String
    @State private var area: Double
    @State private var residents: Double
    @State private var parking: Double
    @State private var isTenant: Bool
    @State private var owner: String
    @State private var active: Bool
    @State private var creditor: Bool
    @State private var opening: Double
    @State private var exemptions: Set<ExpenseCategory>
    @State private var note: String
    @State private var confirmDelete = false

    init(existing: BUnit?, nextNumber: Int = 1) {
        self.existing = existing
        let u = existing
        _number = State(initialValue: Double(u?.number ?? nextNumber))
        _floor = State(initialValue: Double(u?.floor ?? 1))
        _first = State(initialValue: u?.firstName ?? "")
        _last = State(initialValue: u?.lastName ?? "")
        _phone = State(initialValue: u?.phone ?? "")
        _area = State(initialValue: u?.area ?? 90)
        _residents = State(initialValue: Double(u?.residents ?? 3))
        _parking = State(initialValue: Double(u?.parking ?? 1))
        _isTenant = State(initialValue: u?.isTenant ?? false)
        _owner = State(initialValue: u?.ownerName ?? "")
        _active = State(initialValue: u?.active ?? true)
        _creditor = State(initialValue: (u?.openingBalance ?? 0) < 0)
        _opening = State(initialValue: abs(u?.openingBalance ?? 0))
        _exemptions = State(initialValue: Set(u?.exemptions ?? []))
        _note = State(initialValue: u?.note ?? "")
    }

    var body: some View {
        SheetScaffold(existing == nil ? "واحد جدید" : "ویرایش واحد",
                      canSave: !(first.isEmpty && last.isEmpty) || existing != nil,
                      onSave: save) {
            GlassSection("مشخصات ساکن") {
                TextRow(title: "نام", text: $first)
                Divider()
                TextRow(title: "نام خانوادگی", text: $last)
                Divider()
                TextRow(title: "تلفن همراه", text: $phone, keyboard: .phonePad)
                Divider()
                FormRow("مستأجر است") { Toggle("", isOn: $isTenant).labelsHidden() }
                if isTenant {
                    Divider()
                    TextRow(title: "نام مالک", text: $owner)
                }
            }
            GlassSection("مشخصات واحد") {
                DoubleField(title: "شماره واحد", value: $number)
                Divider()
                DoubleField(title: "طبقه", value: $floor)
                Divider()
                DoubleField(title: "متراژ", value: $area, suffix: "متر")
                Divider()
                DoubleField(title: "تعداد نفرات", value: $residents)
                Divider()
                DoubleField(title: "تعداد پارکینگ", value: $parking)
                Divider()
                FormRow("فعال (در محاسبه شارژ)") { Toggle("", isOn: $active).labelsHidden() }
            }
            GlassSection("تراز اولیه (قبل از شروع برنامه)") {
                FormRow("وضعیت") {
                    Picker("", selection: $creditor) {
                        Text("بدهکار").tag(false)
                        Text("بستانکار").tag(true)
                    }
                    .pickerStyle(.segmented).frame(maxWidth: 180)
                }
                Divider()
                DoubleField(title: "مبلغ", value: $opening, suffix: AppFormat.currency, showMoney: true)
            }
            GlassSection("معافیت از هزینه‌ها") {
                Text("اگر مجمع تصمیم گرفته واحدی (مثلاً همکف) در هزینه‌ای شریک نباشد، آن را انتخاب کنید. توجه: طبق قانون، به‌طور پیش‌فرض همه مالکان در هزینه‌های مشترک سهیم‌اند.")
                    .font(.caption).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], alignment: .leading, spacing: 6) {
                    ForEach(ExpenseCategory.allCases) { c in
                        ChipToggle(title: c.title, isOn: exemptions.contains(c)) {
                            if exemptions.contains(c) { exemptions.remove(c) } else { exemptions.insert(c) }
                        }
                    }
                }
            }
            GlassSection("یادداشت") {
                TextRow(title: "توضیحات", text: $note)
            }
            if existing != nil {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("حذف واحد", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .alert("این واحد و همه پرداخت‌هایش حذف شود؟", isPresented: $confirmDelete) {
            Button("حذف", role: .destructive) {
                if let e = existing { store.delete(unit: e) }
                dismiss()
            }
            Button("انصراف", role: .cancel) {}
        }
    }

    func save() {
        var u = existing ?? BUnit(number: Int(number), floor: Int(floor), firstName: first, lastName: last,
                                  area: area, residents: Int(residents), parking: Int(parking))
        u.number = Int(number)
        u.floor = Int(floor)
        u.firstName = first.trimmingCharacters(in: .whitespaces)
        u.lastName = last.trimmingCharacters(in: .whitespaces)
        u.phone = phone
        u.area = area
        u.residents = Int(residents)
        u.parking = Int(parking)
        u.isTenant = isTenant
        u.ownerName = owner
        u.active = active
        u.openingBalance = creditor ? -opening : opening
        u.exemptions = ExpenseCategory.allCases.filter { exemptions.contains($0) }
        u.note = note
        store.upsert(unit: u)
    }
}
