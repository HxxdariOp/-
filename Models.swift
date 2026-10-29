import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Jalali month

struct PMonth: Hashable, Comparable {
    let index: Int
    init(index: Int) { self.index = index }
    init(year: Int, month: Int) { index = year * 12 + month - 1 }

    var year: Int { index / 12 }
    var month: Int { index % 12 + 1 }
    var prev: PMonth { PMonth(index: index - 1) }
    var next: PMonth { PMonth(index: index + 1) }

    static func < (a: PMonth, b: PMonth) -> Bool { a.index < b.index }

    static let names = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
                        "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]
    var monthName: String { PMonth.names[month - 1] }
    var title: String { "\(monthName) \(String(year).fa)" }

    static var current: PMonth { of(Date()) }

    static func of(_ d: Date) -> PMonth {
        var cal = Calendar(identifier: .persian)
        cal.timeZone = TimeZone(identifier: "Asia/Tehran") ?? .current
        let c = cal.dateComponents([.year, .month], from: d)
        return PMonth(year: c.year ?? 1405, month: c.month ?? 1)
    }
}

// MARK: - Enums

enum SplitMethod: String, Codable, CaseIterable, Identifiable {
    case equal, area, residents, mixed, parking
    var id: String { rawValue }
    var title: String {
        switch self {
        case .equal: return "مساوی بین واحدها"
        case .area: return "بر اساس متراژ"
        case .residents: return "بر اساس تعداد نفرات"
        case .mixed: return "ترکیبی (متراژ + نفرات)"
        case .parking: return "بر اساس تعداد پارکینگ"
        }
    }
    var short: String {
        switch self {
        case .equal: return "مساوی"
        case .area: return "متراژ"
        case .residents: return "نفرات"
        case .mixed: return "ترکیبی"
        case .parking: return "پارکینگ"
        }
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case water, electricity, gas, elevator, cleaning, security, repair, garden
    case internet, insurance, facilities, management, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .water: return "آب مشترک"
        case .electricity: return "برق مشترک"
        case .gas: return "گاز مشترک"
        case .elevator: return "آسانسور"
        case .cleaning: return "نظافت"
        case .security: return "نگهبان / سرایدار"
        case .repair: return "تعمیرات"
        case .garden: return "فضای سبز"
        case .internet: return "اینترنت و دوربین"
        case .insurance: return "بیمه و عوارض"
        case .facilities: return "تأسیسات و موتورخانه"
        case .management: return "حق‌الزحمه مدیر"
        case .other: return "سایر"
        }
    }
    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .electricity: return "bolt.fill"
        case .gas: return "flame.fill"
        case .elevator: return "arrow.up.and.down"
        case .cleaning: return "sparkles"
        case .security: return "shield.lefthalf.filled"
        case .repair: return "wrench.and.screwdriver.fill"
        case .garden: return "leaf.fill"
        case .internet: return "wifi"
        case .insurance: return "doc.text.fill"
        case .facilities: return "gearshape.2.fill"
        case .management: return "person.fill.checkmark"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum PayMethod: String, Codable, CaseIterable, Identifiable {
    case card, cash, transfer, pos, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .card: return "کارت‌به‌کارت"
        case .cash: return "نقدی"
        case .transfer: return "حواله / پایا"
        case .pos: return "درگاه / پوز"
        case .other: return "سایر"
        }
    }
}

enum PayStatus {
    case paid, partial, unpaid
    var title: String {
        switch self {
        case .paid: return "تسویه"
        case .partial: return "ناقص"
        case .unpaid: return "پرداخت‌نشده"
        }
    }
    var color: Color {
        switch self {
        case .paid: return Color.okGreen
        case .partial: return Color.amber
        case .unpaid: return Color.badRed
        }
    }
}

// MARK: - Data models

struct BUnit: Identifiable, Codable, Hashable {
    var id = UUID()
    var number: Int
    var floor: Int
    var firstName: String
    var lastName: String
    var phone: String = ""
    var area: Double
    var residents: Int
    var parking: Int
    var isTenant: Bool = false
    var ownerName: String = ""
    var active: Bool = true
    var openingBalance: Double = 0      // مثبت = بدهی ، منفی = بستانکاری
    var exemptions: [ExpenseCategory] = []
    var note: String = ""

    var fullName: String {
        let n = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "بدون نام" : n
    }
}

struct Expense: Identifiable, Codable, Hashable {
    var id = UUID()
    var monthIndex: Int
    var title: String
    var category: ExpenseCategory
    var amount: Double
    var date: Date
    var method: SplitMethod
    var paidFromFund: Bool = false
    var note: String = ""
}

struct RecurringTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var category: ExpenseCategory
    var amount: Double
    var method: SplitMethod
    var active: Bool = true
}

struct Payment: Identifiable, Codable, Hashable {
    var id = UUID()
    var unitID: UUID
    var forMonth: Int
    var amount: Double
    var date: Date
    var method: PayMethod
    var refNo: String = ""
    var note: String = ""
}

struct Building: Codable {
    var name = "ساختمان من"
    var address = ""
    var managerName = ""
    var managerPhone = ""
    var cardNumber = ""
    var cardOwner = ""
    var sheba = ""
    var startMonth: Int = PMonth.current.index
    var defaultMethod: SplitMethod = .mixed
    var mixAreaWeight: Double = 0.5
    var fundPercent: Double = 5
    var roundTo: Double = 1000
    var lateFeePercent: Double = 0
    var dueDay: Int = 5
    var currency = "تومان"
    var openingCash: Double = 0
    var fundOpening: Double = 0
    var setupDone = false
}

struct AppData: Codable {
    var building: Building
    var units: [BUnit]
    var expenses: [Expense]
    var templates: [RecurringTemplate]
    var payments: [Payment]

    static func empty() -> AppData {
        AppData(building: Building(), units: [], expenses: [], templates: [], payments: [])
    }
}

// MARK: - Calculation results

struct ChargeLine: Identifiable {
    let id = UUID()
    let title: String
    let category: ExpenseCategory?
    let amount: Double
}

struct UnitStatement: Identifiable {
    var id: UUID { unit.id }
    let unit: BUnit
    let month: PMonth
    let previousBalance: Double
    let lines: [ChargeLine]
    let fundShare: Double
    let lateFee: Double
    let roundingAdj: Double
    let charge: Double
    let paid: Double
    let status: PayStatus
    var due: Double { previousBalance + charge }
    var remaining: Double { due - paid }
}

struct MonthShares {
    var lines: [UUID: [ChargeLine]] = [:]
    var fund: [UUID: Double] = [:]
    var totalExpenses = 0.0
    var totalFund = 0.0
}

struct MonthSummary {
    var expenses = 0.0
    var fundExpenses = 0.0
    var charge = 0.0
    var dueTotal = 0.0
    var collected = 0.0
    var remaining = 0.0
    var paid = 0
    var partial = 0
    var unpaid = 0
    var count = 0
    var rate = 1.0
}

// MARK: - Export helpers

struct BackupFile: Transferable {
    let filename: String
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { f in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(f.filename)
            try f.data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

struct CSVFile: Transferable {
    let filename: String
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { f in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(f.filename)
            try f.data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

// MARK: - Store

@MainActor
final class Store: ObservableObject {
    @Published var data: AppData {
        didSet { didChange() }
    }
    @Published var selectedMonth: PMonth = PMonth.current
    private var cache: [Int: [UnitStatement]] = [:]

    static let fileURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("building_data.json")
    }()

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init() {
        if let d = try? Data(contentsOf: Store.fileURL),
           let a = try? Store.decoder.decode(AppData.self, from: d) {
            data = a
        } else {
            data = AppData.empty()
        }
        AppFormat.currency = data.building.currency
    }

    private func didChange() {
        cache.removeAll()
        AppFormat.currency = data.building.currency
        if let d = try? Store.encoder.encode(data) {
            try? d.write(to: Store.fileURL, options: .atomic)
        }
    }

    // MARK: Queries

    var activeUnits: [BUnit] {
        data.units.filter { $0.active }.sorted { $0.number < $1.number }
    }

    func unit(_ id: UUID) -> BUnit? { data.units.first { $0.id == id } }

    func expenses(in m: PMonth) -> [Expense] {
        data.expenses.filter { $0.monthIndex == m.index }.sorted { $0.date > $1.date }
    }

    func payments(in m: PMonth) -> [Payment] {
        data.payments.filter { $0.forMonth == m.index }.sorted { $0.date > $1.date }
    }

    func categoryTotals(_ m: PMonth) -> [(ExpenseCategory, Double)] {
        var d: [ExpenseCategory: Double] = [:]
        for e in expenses(in: m) { d[e.category, default: 0] += e.amount }
        return d.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    // MARK: Allocation

    func weights(method: SplitMethod, category: ExpenseCategory?, units: [BUnit]) -> [UUID: Double] {
        var pool = units
        if let category {
            let el = units.filter { !$0.exemptions.contains(category) }
            if !el.isEmpty { pool = el }
        }
        let base = pool
        guard !base.isEmpty else { return [:] }
        let n = Double(base.count)

        func share(_ key: (BUnit) -> Double) -> [UUID: Double] {
            let total = base.reduce(0.0) { $0 + key($1) }
            var out: [UUID: Double] = [:]
            for u in base { out[u.id] = total <= 0 ? 1 / n : key(u) / total }
            return out
        }

        switch method {
        case .equal: return share { _ in 1 }
        case .area: return share { $0.area }
        case .residents: return share { Double($0.residents) }
        case .parking: return share { Double($0.parking) }
        case .mixed:
            let a = share { $0.area }
            let r = share { Double($0.residents) }
            let w = data.building.mixAreaWeight
            var out: [UUID: Double] = [:]
            for u in base { out[u.id] = w * (a[u.id] ?? 0) + (1 - w) * (r[u.id] ?? 0) }
            return out
        }
    }

    func monthShares(_ idx: Int, units: [BUnit]) -> MonthShares {
        var res = MonthShares()
        let exps = data.expenses.filter { $0.monthIndex == idx && !$0.paidFromFund }
        for e in exps {
            res.totalExpenses += e.amount
            let w = weights(method: e.method, category: e.category, units: units)
            for (id, f) in w {
                res.lines[id, default: []].append(ChargeLine(title: e.title, category: e.category, amount: e.amount * f))
            }
        }
        let pct = data.building.fundPercent
        if pct > 0 && res.totalExpenses > 0 {
            res.totalFund = res.totalExpenses * pct / 100
            let w = weights(method: data.building.defaultMethod, category: nil, units: units)
            for (id, f) in w { res.fund[id] = res.totalFund * f }
        }
        return res
    }

    static func status(due: Double, paid: Double) -> PayStatus {
        if due - paid <= 0.5 { return .paid }
        if paid > 0 { return .partial }
        return .unpaid
    }

    func statements(for month: PMonth) -> [UnitStatement] {
        if let c = cache[month.index] { return c }
        let b = data.building
        let units = activeUnits
        let startIdx = min(b.startMonth, month.index)
        var running: [UUID: Double] = [:]
        for u in units { running[u.id] = u.openingBalance }
        var out: [UnitStatement] = []
        var idx = startIdx
        while idx <= month.index {
            let shares = monthShares(idx, units: units)
            out.removeAll()
            for u in units {
                let prev = running[u.id] ?? 0
                let lines = shares.lines[u.id] ?? []
                let fund = shares.fund[u.id] ?? 0
                var late = 0.0
                if b.lateFeePercent > 0 && prev > 0 && idx > startIdx {
                    late = (prev * b.lateFeePercent / 100).rounded()
                }
                let raw = lines.reduce(0.0) { $0 + $1.amount } + fund + late
                var charge = raw
                if b.roundTo > 1 { charge = (raw / b.roundTo).rounded() * b.roundTo }
                let paid = data.payments
                    .filter { $0.unitID == u.id && $0.forMonth == idx }
                    .reduce(0.0) { $0 + $1.amount }
                let due = prev + charge
                running[u.id] = due - paid
                out.append(UnitStatement(unit: u, month: PMonth(index: idx), previousBalance: prev,
                                         lines: lines, fundShare: fund, lateFee: late,
                                         roundingAdj: charge - raw, charge: charge, paid: paid,
                                         status: Store.status(due: due, paid: paid)))
            }
            idx += 1
        }
        cache[month.index] = out
        return out
    }

    func statement(unitID: UUID, month: PMonth) -> UnitStatement? {
        statements(for: month).first { $0.unit.id == unitID }
    }

    func summary(for m: PMonth) -> MonthSummary {
        let st = statements(for: m)
        var s = MonthSummary()
        s.count = st.count
        for x in st {
            s.charge += x.charge
            s.dueTotal += max(x.due, 0)
            s.collected += x.paid
            s.remaining += max(x.remaining, 0)
            switch x.status {
            case .paid: s.paid += 1
            case .partial: s.partial += 1
            case .unpaid: s.unpaid += 1
            }
        }
        for e in data.expenses where e.monthIndex == m.index {
            if e.paidFromFund { s.fundExpenses += e.amount } else { s.expenses += e.amount }
        }
        s.rate = s.dueTotal > 0 ? min(1, s.collected / s.dueTotal) : 1
        return s
    }

    func cashBalance(upTo m: PMonth) -> Double {
        let income = data.payments.filter { $0.forMonth <= m.index }.reduce(0.0) { $0 + $1.amount }
        let spent = data.expenses.filter { $0.monthIndex <= m.index }.reduce(0.0) { $0 + $1.amount }
        return data.building.openingCash + income - spent
    }

    func fundBalance(upTo m: PMonth) -> Double {
        var f = data.building.fundOpening
        let units = activeUnits
        var idx = data.building.startMonth
        while idx <= m.index {
            f += monthShares(idx, units: units).totalFund
            idx += 1
        }
        f -= data.expenses.filter { $0.paidFromFund && $0.monthIndex <= m.index }.reduce(0.0) { $0 + $1.amount }
        return f
    }

    // MARK: CRUD

    func upsert(unit u: BUnit) {
        if let i = data.units.firstIndex(where: { $0.id == u.id }) { data.units[i] = u } else { data.units.append(u) }
    }

    func delete(unit u: BUnit) {
        data.payments.removeAll { $0.unitID == u.id }
        data.units.removeAll { $0.id == u.id }
    }

    func upsert(expense e: Expense) {
        if let i = data.expenses.firstIndex(where: { $0.id == e.id }) { data.expenses[i] = e } else { data.expenses.append(e) }
    }

    func delete(expense e: Expense) { data.expenses.removeAll { $0.id == e.id } }

    func upsert(payment p: Payment) {
        if let i = data.payments.firstIndex(where: { $0.id == p.id }) { data.payments[i] = p } else { data.payments.append(p) }
    }

    func delete(payment p: Payment) { data.payments.removeAll { $0.id == p.id } }

    func upsert(template t: RecurringTemplate) {
        if let i = data.templates.firstIndex(where: { $0.id == t.id }) { data.templates[i] = t } else { data.templates.append(t) }
    }

    func delete(template t: RecurringTemplate) { data.templates.removeAll { $0.id == t.id } }

    func copyExpenses(from src: PMonth, to dst: PMonth) -> Int {
        let existing = expenses(in: dst)
        var n = 0
        for e in expenses(in: src) {
            if existing.contains(where: { $0.title == e.title && $0.category == e.category }) { continue }
            var c = e
            c.id = UUID()
            c.monthIndex = dst.index
            c.date = Date()
            data.expenses.append(c)
            n += 1
        }
        return n
    }

    func applyTemplates(to m: PMonth) -> Int {
        let existing = expenses(in: m)
        var n = 0
        for t in data.templates where t.active && t.amount > 0 {
            if existing.contains(where: { $0.title == t.title && $0.category == t.category }) { continue }
            data.expenses.append(Expense(monthIndex: m.index, title: t.title, category: t.category,
                                         amount: t.amount, date: Date(), method: t.method))
            n += 1
        }
        return n
    }

    // MARK: Text reports

    func mergedLines(_ s: UnitStatement) -> [(String, Double)] {
        var order: [String] = []
        var sums: [String: Double] = [:]
        for l in s.lines {
            if sums[l.title] == nil { order.append(l.title) }
            sums[l.title, default: 0] += l.amount
        }
        return order.map { ($0, sums[$0] ?? 0) }
    }

    func receiptText(_ s: UnitStatement) -> String {
        let b = data.building
        var t = "🏢 \(b.name)\n"
        t += "صورت‌حساب شارژ \(s.month.title)\n"
        t += "واحد \(fnum(s.unit.number)) | \(s.unit.fullName)\n"
        t += "━━━━━━━━━━\n"
        for (title, amt) in mergedLines(s) { t += "• \(title): \(money(amt))\n" }
        if s.fundShare > 0 { t += "• سهم صندوق ذخیره: \(money(s.fundShare))\n" }
        if s.lateFee > 0 { t += "• جریمه تأخیر: \(money(s.lateFee))\n" }
        if abs(s.roundingAdj) >= 1 { t += "• گرد کردن: \(money(s.roundingAdj))\n" }
        t += "━━━━━━━━━━\n"
        t += "شارژ این ماه: \(money(s.charge))\n"
        if s.previousBalance > 0.5 { t += "بدهی ماه‌های قبل: \(money(s.previousBalance))\n" }
        if s.previousBalance < -0.5 { t += "بستانکاری قبلی: \(money(-s.previousBalance))\n" }
        t += "جمع قابل پرداخت: \(money(s.due))\n"
        if s.paid > 0 { t += "پرداخت‌شده: \(money(s.paid))\n" }
        if s.remaining > 0.5 {
            t += "💳 مانده قابل پرداخت: \(money(s.remaining))\n"
            if !b.cardNumber.isEmpty { t += "شماره کارت: \(b.cardNumber)\n" }
            if !b.cardOwner.isEmpty { t += "به نام: \(b.cardOwner)\n" }
            if !b.sheba.isEmpty { t += "شبا: \(b.sheba)\n" }
            if b.dueDay > 0 { t += "مهلت پرداخت: \(fnum(b.dueDay)) \(s.month.monthName)\n" }
        } else {
            t += "✅ تسویه‌شده\n"
        }
        if !b.managerName.isEmpty { t += "— مدیر ساختمان: \(b.managerName)" }
        return t
    }

    func debtorsText(_ m: PMonth) -> String {
        let list = statements(for: m).filter { $0.remaining > 0.5 }.sorted { $0.remaining > $1.remaining }
        var t = "📋 لیست بدهکاران \(data.building.name) – \(m.title)\n━━━━━━━━━━\n"
        if list.isEmpty { return t + "همه واحدها تسویه هستند ✅" }
        for s in list { t += "واحد \(fnum(s.unit.number)) – \(s.unit.fullName): \(money(s.remaining))\n" }
        t += "━━━━━━━━━━\nجمع: \(money(list.reduce(0.0) { $0 + $1.remaining }))"
        return t
    }

    func payableListText(_ m: PMonth) -> String {
        let b = data.building
        var t = "🏢 \(b.name)\nمبلغ واریزی شارژ \(m.title)\n━━━━━━━━━━\n"
        for s in statements(for: m) {
            let line = s.remaining > 0.5 ? money(s.remaining) : "✅ تسویه"
            t += "واحد \(fnum(s.unit.number)) – \(s.unit.fullName): \(line)\n"
        }
        if !b.cardNumber.isEmpty {
            t += "━━━━━━━━━━\nشماره کارت: \(b.cardNumber)"
            if !b.cardOwner.isEmpty { t += "\nبه نام: \(b.cardOwner)" }
        }
        return t
    }

    func csvFile(_ m: PMonth) -> CSVFile {
        var rows = ["واحد,نام,متراژ,نفرات,مانده قبل,شارژ ماه,جمع قابل پرداخت,پرداختی,مانده,وضعیت"]
        for s in statements(for: m) {
            let cols: [String] = [
                String(s.unit.number), "\"\(s.unit.fullName)\"", String(Int(s.unit.area)), String(s.unit.residents),
                String(Int(s.previousBalance.rounded())), String(Int(s.charge.rounded())),
                String(Int(s.due.rounded())), String(Int(s.paid.rounded())),
                String(Int(s.remaining.rounded())), s.status.title
            ]
            rows.append(cols.joined(separator: ","))
        }
        let text = "\u{FEFF}" + rows.joined(separator: "\n")
        return CSVFile(filename: "charge-\(m.year)-\(m.month).csv", data: Data(text.utf8))
    }

    // MARK: Backup / reset / setup

    func backupFile() -> BackupFile {
        let d = (try? Store.encoder.encode(data)) ?? Data()
        return BackupFile(filename: "building-backup.json", data: d)
    }

    func restore(from url: URL) throws {
        let d = try Data(contentsOf: url)
        data = try Store.decoder.decode(AppData.self, from: d)
    }

    func resetAll() {
        data = AppData.empty()
        selectedMonth = PMonth.current
    }

    func defaultTemplates() -> [RecurringTemplate] {
        [
            RecurringTemplate(title: "آب مشترک", category: .water, amount: 0, method: .residents),
            RecurringTemplate(title: "برق مشترک", category: .electricity, amount: 0, method: .equal),
            RecurringTemplate(title: "آسانسور", category: .elevator, amount: 0, method: .equal),
            RecurringTemplate(title: "نظافت", category: .cleaning, amount: 0, method: .equal),
            RecurringTemplate(title: "نگهبان / سرایدار", category: .security, amount: 0, method: .equal),
            RecurringTemplate(title: "تأسیسات و موتورخانه", category: .facilities, amount: 0, method: .area)
        ]
    }

    func setupBuilding(name: String, count: Int, perFloor: Int, area: Double, residents: Int,
                       manager: String, card: String, cardOwner: String) {
        var b = Building()
        b.name = name.isEmpty ? "ساختمان من" : name
        b.managerName = manager
        b.cardNumber = card
        b.cardOwner = cardOwner
        b.startMonth = PMonth.current.index
        b.setupDone = true
        var units: [BUnit] = []
        let per = max(perFloor, 1)
        for i in 1...max(count, 1) {
            units.append(BUnit(number: i, floor: (i - 1) / per + 1, firstName: "ساکن",
                               lastName: "واحد \(fnum(i))", area: area, residents: residents, parking: 1))
        }
        data = AppData(building: b, units: units, expenses: [], templates: defaultTemplates(), payments: [])
        selectedMonth = PMonth.current
    }

    func loadDemo() {
        let cur = PMonth.current
        var b = Building()
        b.name = "مجتمع مسکونی نمونه"
        b.managerName = "آقای احمدی"
        b.managerPhone = "09120000000"
        b.cardNumber = "6037-9911-2233-4455"
        b.cardOwner = "احمدی (مدیر ساختمان)"
        b.startMonth = cur.index - 1
        b.setupDone = true
        b.defaultMethod = .mixed
        b.fundPercent = 5
        b.roundTo = 1000

        let firsts = ["علی", "محمد", "رضا", "حسین", "مهدی", "سعید", "امیر", "حمید", "مریم", "زهرا",
                      "فاطمه", "سارا", "نرگس", "مینا", "لیلا", "احمد", "کاظم", "بهرام", "نادر", "کامران",
                      "شیرین", "پریسا", "جواد", "داریوش", "هدی"]
        let lasts = ["رضایی", "احمدی", "کریمی", "محمدی", "حسینی", "موسوی", "جعفری", "صادقی", "قاسمی", "نظری",
                     "یوسفی", "فرهادی", "اکبری", "رحیمی", "مرادی", "عباسی", "بهرامی", "تقوی", "صفایی", "کاظمی",
                     "غفاری", "نوری", "شریفی", "ملکی", "طاهری"]
        let areas: [Double] = [78, 82, 95, 110, 78, 90, 102, 120]
        let res = [2, 3, 4, 1, 5, 3, 2, 4]
        var units: [BUnit] = []
        for i in 0..<25 {
            var u = BUnit(number: i + 1, floor: i / 5 + 1, firstName: firsts[i], lastName: lasts[i],
                          area: areas[i % areas.count], residents: res[i % res.count], parking: i % 6 == 0 ? 0 : 1)
            u.phone = "0912\(String(1000000 + i * 7311).suffix(7))"
            if i % 7 == 3 { u.isTenant = true; u.ownerName = "مالک واحد \(fnum(i + 1))" }
            if i == 0 { u.exemptions = [] }
            units.append(u)
        }

        func exp(_ m: PMonth, _ t: String, _ c: ExpenseCategory, _ a: Double, _ me: SplitMethod) -> Expense {
            Expense(monthIndex: m.index, title: t, category: c, amount: a, date: Date(), method: me)
        }
        var exps: [Expense] = []
        for m in [cur.prev, cur] {
            exps.append(exp(m, "آب مشترک", .water, 2_400_000, .residents))
            exps.append(exp(m, "برق مشترک", .electricity, 3_100_000, .equal))
            exps.append(exp(m, "آسانسور", .elevator, 4_500_000, .equal))
            exps.append(exp(m, "نظافت", .cleaning, 6_000_000, .equal))
            exps.append(exp(m, "نگهبان / سرایدار", .security, 12_000_000, .equal))
            exps.append(exp(m, "تأسیسات و موتورخانه", .facilities, 1_800_000, .area))
        }
        exps.append(exp(cur, "تعمیر پمپ آب", .repair, 3_500_000, .mixed))

        data = AppData(building: b, units: units, expenses: exps, templates: defaultTemplates(), payments: [])
        selectedMonth = cur

        // پرداخت‌های نمونه برای ماه قبل
        var pays: [Payment] = []
        for (i, s) in statements(for: cur.prev).enumerated() {
            if i % 9 == 4 { continue }
            let amount = i % 9 == 7 ? (s.due / 2 / 1000).rounded() * 1000 : s.due
            pays.append(Payment(unitID: s.unit.id, forMonth: cur.prev.index, amount: amount,
                                date: Date().addingTimeInterval(-86400 * 20), method: .card))
        }
        data.payments = pays
        // چند پرداخت برای ماه جاری
        var pays2: [Payment] = data.payments
        for (i, s) in statements(for: cur).enumerated() where i % 3 == 0 && s.remaining > 0 {
            pays2.append(Payment(unitID: s.unit.id, forMonth: cur.index, amount: s.remaining,
                                 date: Date().addingTimeInterval(-86400 * 2), method: i % 2 == 0 ? .card : .cash))
        }
        data.payments = pays2
    }
}
