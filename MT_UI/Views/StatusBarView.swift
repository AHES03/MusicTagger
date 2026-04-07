import SwiftUI

struct StatusBarView: View {
    let itemSelected: Bool
    @Binding var files: [MusicFile]
    let selectedFile: MusicFile?
    var body: some View {
        HStack(spacing: 6) {
            Text(itemSelected ? "1 selected" : "\(files.count) items") // TODO: AHE-86 — update once multi-select is supported
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            Text("\(files.count) loaded")
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 6) {
                Text(selectedFile?.format ?? "—") // TODO: populate once backend returns format field
                Divider().frame(height: 12)
                Text(selectedFile?.sampleRate.map { "\($0 / 1000).\(($0 % 1000) / 100) kHz" } ?? "—") // TODO: populate once backend returns sample_rate field
                Divider().frame(height: 12)
                Text(selectedFile?.bitDepth.map { "\($0)-bit" } ?? "—") // TODO: populate once backend returns bit_depth field
            }
            .foregroundColor(.secondary)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(.bar)
        .overlay(Divider(), alignment: .top)
    }
}
