//
//  CustomButtons.swift
//  MusicTagger
//
//  Created by Hadi El-Seyed on 07/04/2026.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .fontWeight(.medium)
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(white: 0.2))
            .foregroundColor(.primary)
            .fontWeight(.medium)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
