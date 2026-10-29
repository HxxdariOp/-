import SwiftUI

// MARK: - Colors

extension Color {
    static let accentOrange = Color(red: 1.0, green: 0.56, blue: 0.10)
    static let deepOrange = Color(red: 0.96, green: 0.36, blue: 0.02)
    static let amber = Color(red: 1.0, green: 0.76, blue: 0.25)
    static let inkBlack = Color(red: 0.035, green: 0.035, blue: 0.045)
    static let okGreen = Color(red: 0.32, green: 0.86, blue: 0.52)
    static let badRed = Color(red: 1.0, green: 0.34, blue: 0.32)
}

// MARK: - Formatting

enum AppFormat {
    static var currency = "تومان"
}

extension String {
    /// English digits -> Persian digits
    var fa: String {
        let m: [Character: Character] = ["0": "۰", "1": "۱", "2": "۲", "3": "۳", "4": "۴",
                                          "5": "۵", "6": "۶", "7": "۷", "8": "۸", "9": "۹"]
        return String(self.map { m[$0] ?? $0 })
    }

    /// Persian / Arabic digits -> English digits
    var en: String {
        let m: [Character: Character] = ["۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
                                          "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9",
                                          "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
                                          "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"]
        return String(self.map { m[$0] ?? $0 })
    }
}

func parseNum(_ s: String) -> Double {
    var e = s.en
    for ch in [",", "٬", "،", " "] { e = e.replacingOccurrences(of: ch, with: "") }
    e = e.replacingOccurrences(of: "٫", with: ".")
    return Double(e) ?? 0
}

func groupInt(_ n: Int) -> String {
    let neg = n < 0
    let s = String(abs(n))
    var out = ""
    for (i, ch) in s.reversed().enumerated() {
        if i > 0 && i % 3 == 0 { out.append("٬") }
        out.append(ch)
    }
    let r = String(out.reversed()).fa
    return neg ? "\u{202A}-\(r)\u{202C}" : r
}

func money(_ v: Double, unit: Bool = true) -> String {
    guard v.isFinite else { return "—" }
    let s = groupInt(Int(v.rounded()))
    return unit ? "\(s) \(AppFormat.currency)" : s
}

func fnum(_ v: Int) -> String { String(v).fa }

func pct(_ v: Double) -> String {
    guard v.isFinite else { return "—" }
    return "\(String(Int((v * 100).rounded())).fa)٪"
}

func shortDate(_ d: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .persian)
    f.locale = Locale(identifier: "fa_IR")
    f.timeZone = TimeZone(identifier: "Asia/Tehran")
    f.dateFormat = "d MMMM yyyy"
    return f.string(from: d)
}

// MARK: - Background & glass

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color.inkBlack
            Circle().fill(Color.deepOrange.opacity(0.55)).frame(width: 360, height: 360)
                .blur(radius: 90).offset(x: 140, y: -300)
            Circle().fill(Color.accentOrange.opacity(0.35)).frame(width: 300, height: 300)
                .blur(radius: 90).offset(x: -150, y: 260)
            Circle().fill(Color.amber.opacity(0.16)).frame(width: 240, height: 240)
                .blur(radius: 80).offset(x: 130, y: 90)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard: ViewModifier {
    var radius: CGFloat
    var tint: Color?
    var pad: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(pad)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.ultraThinMaterial)
                    if let tint {
                        RoundedRectangle(cornerRadius: radius, style: .continuous).fill(tint.opacity(0.14))
                    }
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.02)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.05), Color.accentOrange.opacity(0.28)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func glass(radius: CGFloat = 22, tint: Color? = nil, pad: CGFloat = 16) -> some View {
        modifier(GlassCard(radius: radius, tint: tint, pad: pad))
    }
}

struct GlassButtonStyle: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundColor(prominent ? Color.black : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                if prominent {
                    Capsule().fill(LinearGradient(colors: [Color.amber, Color.accentOrange, Color.deepOrange],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 1))
            .shadow(color: prominent ? Color.accentOrange.opacity(0.35) : Color.clear, radius: 10, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct GlassIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundColor(Color.accentOrange)
            .frame(width: 38, height: 38)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
    }
}

// MARK: - Small components

struct Pill: View {
    let text: String
    var color: Color = Color.accentOrange
    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .clipShape(Capsule())
    }
}

struct RingProgress: View {
    let progress: Double
    var lineWidth: CGFloat = 12
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(AngularGradient(colors: [Color.amber, Color.accentOrange, Color.deepOrange, Color.amber], center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = Color.accentOrange
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(tint)
            Text(value).font(.headline).minimumScaleFactor(0.6).lineLimit(1)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(radius: 20)
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote.bold())
            .foregroundColor(Color.accentOrange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
    }
}

struct ChipToggle: View {
    let title: String
    let isOn: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isOn ? Color.black : Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isOn ? Color.accentOrange : Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Form components

struct GlassSection<Content: View>: View {
    let title: String?
    let content: Content
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title { SectionTitle(text: title) }
            VStack(alignment: .leading, spacing: 8) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(radius: 20)
        }
    }
}

struct FormRow<Content: View>: View {
    let title: String
    let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            content.multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

struct DoubleField: View {
    let title: String
    @Binding var value: Double
    var suffix: String? = nil
    var showMoney = false
    @State private var text = ""
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            FormRow(title) {
                HStack(spacing: 4) {
                    TextField("۰", text: $text)
                        .keyboardType(.numbersAndPunctuation)
                        .frame(maxWidth: 170)
                    if let suffix { Text(suffix).font(.caption).foregroundStyle(.secondary) }
                }
            }
            if showMoney && value != 0 {
                Text(money(value)).font(.caption2).foregroundColor(Color.accentOrange)
            }
        }
        .onAppear {
            if !loaded {
                text = value == 0 ? "" : (value.rounded() == value ? String(Int(value)) : String(value))
                loaded = true
            }
        }
        .onChange(of: text) { newValue in
            value = parseNum(newValue)
        }
    }
}

struct TextRow: View {
    let title: String
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default
    var body: some View {
        FormRow(title) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .frame(maxWidth: 200)
        }
    }
}

struct SheetScaffold<Content: View>: View {
    let title: String
    let saveTitle: String
    let canSave: Bool
    let onSave: () -> Void
    let content: Content
    @Environment(\.dismiss) private var dismiss

    init(_ title: String, saveTitle: String = "ذخیره", canSave: Bool = true,
         onSave: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.saveTitle = saveTitle
        self.canSave = canSave
        self.onSave = onSave
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                HStack {
                    Button("انصراف") { dismiss() }.buttonStyle(GlassButtonStyle())
                    Spacer()
                    Text(title).font(.headline)
                    Spacer()
                    Button(saveTitle) { onSave(); dismiss() }
                        .buttonStyle(GlassButtonStyle(prominent: true))
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                }
                .padding()
                ScrollView {
                    VStack(spacing: 16) { content }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MonthStepper: View {
    @Binding var index: Int
    var body: some View {
        HStack(spacing: 10) {
            Button { index -= 1 } label: { Image(systemName: "chevron.backward") }.buttonStyle(GlassIconStyle())
            Text(PMonth(index: index).title).font(.subheadline.bold()).frame(minWidth: 110)
            Button { index += 1 } label: { Image(systemName: "chevron.forward") }.buttonStyle(GlassIconStyle())
        }
    }
}

struct MonthHeader: View {
    @EnvironmentObject var store: Store
    var body: some View {
        HStack {
            Button { store.selectedMonth = store.selectedMonth.prev } label: { Image(systemName: "chevron.backward") }
                .buttonStyle(GlassIconStyle())
            Spacer()
            VStack(spacing: 4) {
                Text(store.selectedMonth.title).font(.headline)
                if store.selectedMonth == PMonth.current {
                    Pill(text: "ماه جاری")
                } else {
                    Button("بازگشت به ماه جاری") { store.selectedMonth = PMonth.current }
                        .font(.caption2.bold())
                        .foregroundColor(Color.accentOrange)
                }
            }
            Spacer()
            Button { store.selectedMonth = store.selectedMonth.next } label: { Image(systemName: "chevron.forward") }
                .buttonStyle(GlassIconStyle())
        }
        .glass(radius: 20, pad: 10)
    }
}

struct EmptyState: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(Color.accentOrange.opacity(0.8))
            Text(text).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .glass()
    }
}
