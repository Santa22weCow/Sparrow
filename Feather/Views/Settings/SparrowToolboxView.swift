import SwiftUI

struct SparrowToolboxView: View {
	var body: some View {
		List {
			Section("Sparrow Toolbox") {
				NavigationLink(destination: SparrowDashboardView()) { Label("Dashboard", systemImage: "rectangle.3.group") }
				NavigationLink(destination: SparrowDiagnosticsView()) { Label("Diagnostics & Activity", systemImage: "stethoscope") }
				NavigationLink(destination: SparrowSigningPresetsView()) { Label("Signing Presets", systemImage: "square.stack.3d.up") }
			}
			Section("Power Tools") {
				NavigationLink(destination: SparrowIPACompareView()) { Label("Compare IPAs", systemImage: "arrow.left.arrow.right") }
				NavigationLink(destination: SparrowVersionVaultView()) { Label("Version Vault", systemImage: "clock.arrow.circlepath") }
				Text("Icon Studio, Sparrow Drop, and Storage Cleaner will appear here as each tool receives its safe file-processing implementation.").foregroundStyle(.secondary)
			}
		}
		.navigationTitle("Sparrow Toolbox")
	}
}
