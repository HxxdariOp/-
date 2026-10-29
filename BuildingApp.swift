import SwiftUI

@main
struct BuildingChargeApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "fa_IR"))
                .tint(Color.accentOrange)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    var body: some View {
        if store.data.building.setupDone {
            tabs
        } else {
            SetupView()
        }
    }

    func screen<V: View>(_ v: V) -> some View {
        NavigationStack {
            v.navigationDestination(for: UUID.self) { UnitDetailView(unitID: $0) }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    var tabs: some View {
        TabView(selection: $tab) {
            screen(DashboardView())
                .tabItem { Label("خانه", systemImage: "house.fill") }.tag(0)
            screen(UnitsView())
                .tabItem { Label("واحدها", systemImage: "building.2.fill") }.tag(1)
            screen(ExpensesView())
                .tabItem { Label("هزینه‌ها", systemImage: "creditcard.fill") }.tag(2)
            screen(PaymentsView())
                .tabItem { Label("پرداخت‌ها", systemImage: "banknote.fill") }.tag(3)
            screen(MoreView())
                .tabItem { Label("بیشتر", systemImage: "ellipsis.circle.fill") }.tag(4)
        }
    }
}

// MARK: - Setup wizard

struct SetupView: View {
    @EnvironmentObject var store: Store
    @State private var name = ""
    @State private var count: Double = 25
    @State private var perFloor: Double = 5
    @State private var area: Double = 90
    @State private var residents: Double = 3
    @State private var manager = ""
    @State private var card = ""
    @State private var cardOwner = ""

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Image(systemName: "building.2.crop.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(LinearGradient(colors: [Color.amber, Color.deepOrange],
                                                            startPoint: .top, endPoint: .bottom))
                        Text("شارژ ساختمان").font(.largeTitle.bold())
                        Text("حساب‌وکتاب ماهانه ساختمان، ساده و دقیق")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 30)

                    GlassSection("اطلاعات ساختمان") {
                        TextRow(title: "نام ساختمان", text: $name, placeholder: "مثلاً مجتمع گلستان")
                        Divider()
                        DoubleField(title: "تعداد واحدها", value: $count)
                        Divider()
                        DoubleField(title: "واحد در هر طبقه", value: $perFloor)
                        Divider()
                        DoubleField(title: "متراژ پیش‌فرض", value: $area, suffix: "متر")
                        Divider()
                        DoubleField(title: "نفرات پیش‌فرض هر واحد", value: $residents)
                    }

                    GlassSection("مدیر و اطلاعات پرداخت (اختیاری)") {
                        TextRow(title: "نام مدیر", text: $manager)
                        Divider()
                        TextRow(title: "شماره کارت", text: $card, placeholder: "۶۰۳۷-…", keyboard: .numbersAndPunctuation)
                        Divider()
                        TextRow(title: "به نام", text: $cardOwner)
                    }

                    Button {
                        store.setupBuilding(name: name, count: Int(count), perFloor: Int(perFloor),
                                            area: area, residents: Int(residents),
                                            manager: manager, card: card, cardOwner: cardOwner)
                    } label: {
                        Text("ساخت ساختمان").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(prominent: true))

                    Button {
                        store.loadDemo()
                    } label: {
                        Label("مشاهده با داده نمونه (۲۵ واحد)", systemImage: "sparkles").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())

                    Text("نام و مشخصات هر واحد را بعداً در تب «واحدها» وارد می‌کنید.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
}
