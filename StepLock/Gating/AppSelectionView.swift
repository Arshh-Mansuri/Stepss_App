//
//  AppSelectionView.swift
//  StepLock
//
//  Created by JJ on 5/5/2026.
//

import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @State private var shieldManager = ShieldManager.shared
    @State private var isPickerPresented = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 5) {
                Circle()
                    .fill(DS.Color.gray200)
                    .frame(width: 6, height: 6)

                Circle()
                    .fill(DS.Color.gray200)
                    .frame(width: 6, height: 6)

                RoundedRectangle(cornerRadius: 10)
                    .fill(DS.Color.purple400)
                    .frame(width: 22, height: 6)
            }
            .padding(.top, DS.Space.lg)

            VStack(spacing: DS.Space.lg) {
                Text("Pick the apps\nyou want to gate.")
                    .font(.system(size: 35, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, DS.Space.xl)

                Text("You choose. Apple shows the names.\nStepLock never sees them.")
                    .font(.system(size: 17))
                    .foregroundColor(DS.Color.gray400)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 10)

            Spacer().frame(height: 50)

            VStack(spacing: DS.Space.lg) {
                Text("APPLE SYSTEM PICKER")
                    .font(.system(size: 18, weight: .bold))
                    .kerning(1.0)
                    .foregroundColor(DS.Color.gray400)

                HStack(spacing: DS.Space.md) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(DS.Color.gray200.opacity(0.4))
                        .frame(width: 74, height: 74)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(DS.Color.purple50)
                        .frame(width: 74, height: 74)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(DS.Color.teal50)
                        .frame(width: 74, height: 74)
                }

                Text("iOS renders each app's\n real icon & name here")
                    .font(.system(size: 18))
                    .foregroundColor(DS.Color.gray400)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
            .background(DS.Color.gray50)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DS.Color.gray200, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
            .padding(.horizontal, DS.Space.edge)

            Spacer().frame(height: 30)

            Text("You can add or remove apps any time\nfrom Settings")
                .font(.system(size: 18))
                .foregroundColor(DS.Color.gray400)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, DS.Space.lg)

            Spacer()

            VStack(spacing: 12) {
                Button(action: { isPickerPresented = true }) {
                    Text("Open app picker")
                        .font(.system(size: 27, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DS.Color.purple600)
                        .foregroundColor(DS.Color.gray0)
                        .cornerRadius(16)
                }
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $shieldManager.selection)

                Button(action: {}) {
                    Text("Skip - set up later")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(DS.Color.gray400)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, DS.Space.edge)
            .padding(.bottom, DS.Space.xl)
        }
        .padding(.horizontal, 4)
        .background(DS.Color.gray0)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    AppSelectionView()
}
