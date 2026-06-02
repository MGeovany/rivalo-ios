import PhotosUI
import SwiftUI

/// Native photo picker controls for the FIFA player card.
struct ProfileCardPhotoControls: View {
    let hasPhoto: Bool
    let onPhotoData: (Data) -> Void
    let onRemove: () -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(
                    hasPhoto ? "Change photo" : "Add photo",
                    systemImage: "photo.on.rectangle.angled"
                )
                .font(Theme.Typography.button(size: 15))
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.medium)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }

            if hasPhoto {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.negative)
                        .frame(width: 48, height: 48)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { onPhotoData(data) }
                }
                await MainActor.run { pickerItem = nil }
            }
        }
    }
}
