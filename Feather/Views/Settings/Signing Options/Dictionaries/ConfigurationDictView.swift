//
//  SigningOptionsDictView.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct ConfigurationDictView: View {
	@State private var _isAddingPresenting = false
	@State private var _editingKey: String?
	@AppStorage("Sparrow.identifierRulesEnabled") private var _enabledData = Data()
	private var enabled: [String: Bool] { (try? JSONDecoder().decode([String: Bool].self, from: _enabledData)) ?? [:] }
	private func setEnabled(_ key: String, _ value: Bool) { var copy = enabled; copy[key] = value; _enabledData = (try? JSONEncoder().encode(copy)) ?? Data() }
	
	var title: String
	@Binding var dataDict: [String: String]
	
	// MARK: Body
	var body: some View {
		NBList(title, type: .list) {
			ForEach(dataDict.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
					Section {
						Toggle(isOn: Binding(get: { enabled[key] ?? true }, set: { setEnabled(key, $0) })) { Text("\(key) → \(value)") }
						.swipeActions(edge: .trailing) {
						_actions(key: key)
					}
				}
			}
		}
		.toolbar {
			NBToolbarButton(
				systemImage: "plus",
				style: .icon,
				placement: .topBarTrailing
			) {
				_isAddingPresenting = true
			}
		}
		.navigationDestination(isPresented: $_isAddingPresenting) {
			ConfigurationDictAddView(dataDict: $dataDict, editingKey: _editingKey)
		}
	}
}

// MARK: - Extension: View
extension ConfigurationDictView {
	@ViewBuilder
	private func _actions(key: String) -> some View {
		Button {
			_editingKey = key
			_isAddingPresenting = true
		} label: { Label(.localized("Edit"), systemImage: "pencil") }
		Button(role: .destructive) {
			dataDict.removeValue(forKey: key)
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
}
