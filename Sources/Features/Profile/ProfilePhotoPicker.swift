import PhotosUI
import SwiftUI

/// Native photo picker controls for the FIFA player card.
struct ProfileCardPhotoControls: View {
    let hasPhoto: Bool
    let isProcessing: Bool
    let showsFixButton: Bool
    let isPlacementLocked: Bool
    let onPhotoData: (Data) -> Void
    let onRemove: () -> Void
    let onFixPhoto: () -> Void
    let onAdjust: () -> Void
    let onAdjustDone: () -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.medium) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(
                        pickerLabel,
                        systemImage: pickerIcon
                    )
                    .font(Theme.Typography.button(size: 15))
                    .foregroundStyle(isProcessing ? Theme.Colors.textSecondary : Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.medium)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .disabled(isProcessing || showsFixButton)

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
                    .disabled(isProcessing)
                }
            }

            if showsFixButton {
                Button(action: onFixPhoto) {
                    Label("Fijar imagen", systemImage: "pin.fill")
                        .font(Theme.Typography.button(size: 16))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.medium)
                        .background(Theme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .buttonStyle(.plain)

                Text("Posiciona la foto y fíjala para recortar el fondo.")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else if isProcessing {
                HStack(spacing: Theme.Spacing.small) {
                    ProgressView()
                        .tint(Theme.Colors.accent)
                    Text("Recortando silueta…")
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.small)
            } else if hasPhoto {
                if isPlacementLocked {
                    Button(action: onAdjust) {
                        Label("Ajustar posición", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(Theme.Typography.button(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.small)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onAdjustDone) {
                        Label("Terminar ajuste", systemImage: "checkmark.circle.fill")
                            .font(Theme.Typography.button(size: 14))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.small)
                            .background(Theme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    }
                    .buttonStyle(.plain)
                }
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

    private var pickerLabel: String {
        if isProcessing { return "Recortando silueta…" }
        if showsFixButton { return "Posicionando foto…" }
        return hasPhoto ? "Cambiar foto" : "Añadir foto"
    }

    private var pickerIcon: String {
        if isProcessing { return "person.crop.rectangle" }
        if showsFixButton { return "hand.draw" }
        return "photo.on.rectangle.angled"
    }
}
