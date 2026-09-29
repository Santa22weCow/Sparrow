//
//  VariedTabbarView.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import SwiftUI

struct VariedTabbarView: View {
	init() {}
	
	var body: some View {
		// Keep the compact five-tab shell on every OS. The iOS 18 sidebar
		// customization view eagerly creates one navigation tree per source,
		// which can freeze or terminate the app while repositories are loading.
		TabbarView()
	}
}
