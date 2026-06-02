import SwiftUI

/// Date of birth picker (day / month / year wheels). Persists `birth_year` on the server.
struct ProfileBirthDatePicker: View {
    @Binding var date: Date?

    @State private var showSheet = false
    @State private var day = 15
    @State private var month = 6
    @State private var year = 1999

    private let calendar = Calendar.current

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((ProfileBirthDate.minYear...current).reversed())
    }

    private var monthSymbols: [String] {
        calendar.monthSymbols
    }

    private var daysInSelectedMonth: Int {
        var components = DateComponents(year: year, month: month)
        guard let start = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: start)
        else { return 31 }
        return range.count
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.medium) {
            Image(systemName: "calendar")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text("Date of birth")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Button {
                    loadFromBinding()
                    showSheet = true
                } label: {
                    HStack {
                        Text(displayText)
                            .font(Theme.Typography.body(size: 17))
                            .foregroundStyle(
                                date == nil ? Theme.Colors.textSecondary : Theme.Colors.textPrimary
                            )
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.bottom, 10)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Theme.Colors.textSecondary.opacity(0.25))
                            .frame(height: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showSheet) {
            pickerSheet
        }
        .onChange(of: month) { _, _ in clampDay() }
        .onChange(of: year) { _, _ in clampDay() }
    }

    private var displayText: String {
        guard let date else { return "Select day, month and year" }
        return ProfileBirthDate.displayString(for: date)
    }

    private var pickerSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        wheelColumn(title: "Day") {
                            Picker("Day", selection: $day) {
                                ForEach(1...daysInSelectedMonth, id: \.self) { value in
                                    Text("\(value)")
                                        .tag(value)
                                }
                            }
                        }

                        wheelColumn(title: "Month") {
                            Picker("Month", selection: $month) {
                                ForEach(1...12, id: \.self) { value in
                                    Text(monthSymbols[value - 1])
                                        .tag(value)
                                }
                            }
                        }

                        wheelColumn(title: "Year") {
                            Picker("Year", selection: $year) {
                                ForEach(yearRange, id: \.self) { value in
                                    Text(verbatim: "\(value)")
                                        .tag(value)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.top, Theme.Spacing.small)

                    Text("Used for heart-rate zones and match rating")
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.top, Theme.Spacing.medium)
                }
            }
            .navigationTitle("Date of birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        date = nil
                        showSheet = false
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        date = ProfileBirthDate.date(day: day, month: month, year: year)
                        showSheet = false
                    }
                    .font(Theme.Typography.button(size: 16))
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private func wheelColumn<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.8)
            content()
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
        }
    }

    private func loadFromBinding() {
        if let date {
            day = calendar.component(.day, from: date)
            month = calendar.component(.month, from: date)
            year = calendar.component(.year, from: date)
        } else {
            let fallback = ProfileBirthDate.defaultDate
            day = calendar.component(.day, from: fallback)
            month = calendar.component(.month, from: fallback)
            year = calendar.component(.year, from: fallback)
        }
        clampDay()
    }

    private func clampDay() {
        if day > daysInSelectedMonth {
            day = daysInSelectedMonth
        }
    }
}

enum ProfileBirthDate {
    static let minYear = 1900

    /// Mid-year default when only birth year exists on the profile.
    static var defaultDate: Date {
        date(day: 15, month: 6, year: 1999) ?? Date()
    }

    static func date(day: Int, month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        guard let value = Calendar.current.date(from: components) else { return nil }
        return value <= Date() ? value : nil
    }

    static func date(fromBirthYear birthYear: Int) -> Date {
        date(day: 15, month: 6, year: birthYear) ?? defaultDate
    }

    static func birthYear(from date: Date?) -> Int? {
        guard let date else { return nil }
        return Calendar.current.component(.year, from: date)
    }

    static func displayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
