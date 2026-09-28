//
//  ConfigurationDictAddView.swift
//  Feather
//
//  Created by samara on 20.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct ConfigurationDictAddView: View {
	@Environment(\.dismiss) var dismiss
	
	@State private var _newKey = ""
	@State private var _newValue = ""
	@State private var _showOverrideAlert = false
	@State private var _error: String?
	var editingKey: String?
	
	var saveButtonDisabled: Bool {
		_newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || _newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
	
	@Binding var dataDict: [String: String]
	
	// MARK: Body
	init(dataDict: Binding<[String: String]>, editingKey: String? = nil) {
		self._dataDict = dataDict
		self.editingKey = editingKey
		if let editingKey { self.__newKey = State(initialValue: editingKey); self.__newValue = State(initialValue: dataDict.wrappedValue[editingKey] ?? "") }
	}

	var body: some View {
		NBList(.localized(editingKey == nil ? "New" : "Edit")) {
			Section {
				TextField(.localized("Value"), text: $_newKey)
				TextField(.localized("Replacement"), text: $_newValue)
			}
			.autocapitalization(.none)
		}
		.toolbar {
			NBToolbarButton(
				.localized("Save"),
				style: .text,
				placement: .confirmationAction,
				isDisabled: saveButtonDisabled
			) {
				let key = _newKey.trimmingCharacters(in: .whitespacesAndNewlines)
				let value = _newValue.trimmingCharacters(in: .whitespacesAndNewlines)
				guard key.range(of: #"^[A-Za-z0-9]+([.-][A-Za-z0-9-]+)*$"#, options: .regularExpression) != nil else { _error = "Enter a valid bundle identifier."; return }
				if editingKey != key { dataDict.removeValue(forKey: editingKey ?? "") }
				if dataDict.keys.contains(key) && editingKey != key { _error = "That identifier already exists."; return }
				dataDict[key] = value
				OptionsManager.shared.saveOptions()
				dismiss()
			}
		}
		.alert("Identifier not saved", isPresented: Binding(get: { _error != nil }, set: { if !$0 { _error = nil } })) { Button("OK") { _error = nil } } message: { Text(_error ?? "") }
	}
}
