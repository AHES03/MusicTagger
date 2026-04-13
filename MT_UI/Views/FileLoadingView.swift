//
//  FileLoadingView.swift
//  MusicTagger
//
//  Created by Hadi El-Seyed on 13/04/2026.
//

import SwiftUI

struct FileLoadingView: View {
    var body: some View {
        ZStack {
            Color(white: 0.05)
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Getting things ready...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 20)
        }
    }
}

#Preview {
    FileLoadingView()
}
