//
//  TabEnum.swift
//  feather
//
//  Created by samara on 22.03.2025.
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
	case sources
	case store
	case library
	case signing
	case updates
	case settings
	case certificates
	
	var title: String {
		switch self {
		case .sources:     	return .localized("Sources")
		case .store: return "App Store"
		case .library: 		return .localized("Library")
		case .signing: 		return "Signing"
		case .updates: 		return "Updates"
		case .settings: 	return .localized("Settings")
		case .certificates:	return .localized("Certificates")
		}
	}
	
	var icon: String {
		switch self {
		case .sources: 		return "globe.desk"
		case .store: return "bag"
		case .library: 		return "square.grid.2x2"
		case .signing: 		return "signature"
		case .updates: 		return "arrow.down.circle"
		case .settings: 	return "gearshape.2"
		case .certificates: return "person.text.rectangle"
		}
	}
	
	@ViewBuilder
	static func view(for tab: TabEnum) -> some View {
		switch tab {
		case .sources: SourcesView()
		case .store: AppStoreView()
		case .library: LibraryView()
		case .signing: NBNavigationView("Signing") { SparrowSignInstallView() }
		case .updates: NBNavigationView("Updates") { SparrowUpdatesView() }
		case .settings: SettingsView()
		case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
		}
	}
	
	static var defaultTabs: [TabEnum] {
		return [.store, .sources, .settings, .library]
	}
	
	static var customizableTabs: [TabEnum] {
		return [
			.certificates
		]
	}
}
