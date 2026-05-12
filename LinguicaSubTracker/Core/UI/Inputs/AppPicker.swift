import SwiftUI

struct AppPicker<V: Hashable, S: PickerStyle>: View {
    let title: String
    @Binding var selection: V
    let options: [(value: V, label: String)]
    var pickerStyle: S
    var tint: Color = .primary

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.value) { option in
                Text(option.label).tag(option.value)
            }
        }
        .pickerStyle(pickerStyle)
        .typography(.bodyMedium)
        .tint(tint)
    }
}

extension AppPicker where S == MenuPickerStyle {
    init(
        title: String,
        selection: Binding<V>,
        options: [(value: V, label: String)],
        tint: Color = .secondary
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.pickerStyle = .menu
        self.tint = tint
    }
}

#Preview("AppPicker — menu (default)") {
    @Previewable @State var schedule: String = "Monthly"

    let options = [
        (value: "Monthly", label: "Monthly"),
        (value: "Yearly", label: "Yearly"),
    ]

    VStack {
        AppPicker(title: "Schedule", selection: $schedule, options: options)
    }
    .padding()
    .background(.black)
}

#Preview("AppPicker — segmented") {
    @Previewable @State var schedule: String = "Monthly"

    let options = [
        (value: "Monthly", label: "Monthly"),
        (value: "Yearly", label: "Yearly"),
    ]

    VStack {
        AppPicker(
            title: "Schedule",
            selection: $schedule,
            options: options,
            pickerStyle: .segmented
        )
    }
    .padding()
    .background(.black)
}
