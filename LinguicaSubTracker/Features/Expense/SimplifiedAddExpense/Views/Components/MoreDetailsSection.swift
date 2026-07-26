import SwiftUI

/// Dates, billing cadence and free-form notes — everything that has a sane
/// default and can be skipped on a fast entry.
struct MoreDetailsSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date?
    @Binding var billingCycle: BillingCycle
    @Binding var notes: String

    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 0) {
            FormRow(
                label: "Start Date",
                icon: "calendar",
                iconColor: tint,
                labelColor: tint
            ) {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .typography(.bodyMedium)
                    .tint(tint)
            }

            Divider()

            FormRow(
                label: "End Date",
                icon: "calendar.badge.minus",
                iconColor: tint,
                labelColor: tint
            ) {
                if let end = endDate {
                    HStack(spacing: 8) {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { end },
                                set: { endDate = $0 }
                            ),
                            in: startDate...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .typography(.bodyMedium)
                        .tint(tint)

                        Button {
                            endDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button("Set End Date") {
                        endDate = Calendar.current.date(
                            byAdding: .month,
                            value: 1,
                            to: startDate
                        ) ?? startDate
                    }
                    .typography(.bodyMedium)
                    .foregroundStyle(tint)
                }
            }

            Divider()

            FormRow(
                label: "Payment Schedule",
                icon: "repeat",
                iconColor: tint,
                labelColor: tint
            ) {
                AppPicker(
                    title: "",
                    selection: $billingCycle,
                    options: BillingCycle.allCases.map {
                        (value: $0, label: $0.displayName)
                    },
                    tint: tint
                )
                .fixedSize(horizontal: true, vertical: false)
            }
            .lineLimit(1)

            Divider().padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .iconStyle(size: 16, weight: .medium, color: tint)
                        .frame(width: 20)
                    Text("Notes")
                        .typography(.bodyLarge)
                        .foregroundStyle(tint)
                }

                TextEditor(text: $notes)
                    .frame(height: 100)
                    .scrollContentBackground(.hidden)
                    .typography(.bodyMedium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    @Previewable @State var start = Date()
    @Previewable @State var end: Date? = nil
    @Previewable @State var cycle: BillingCycle = .monthly
    @Previewable @State var notes = ""

    ZStack {
        LinearGradient(colors: [.green, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        ScrollView {
            LabeledSection("More details", titleColor: .white.opacity(0.85)) {
                MoreDetailsSection(
                    startDate: $start,
                    endDate: $end,
                    billingCycle: $cycle,
                    notes: $notes,
                    tint: .white
                )
            }
            .padding()
        }
    }
}
