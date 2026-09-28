import SwiftUI

struct SparrowToolboxView: View {
	var body: some View {
		List {
			Section("Advanced Tools") {
				NavigationLink(destination: SparrowDashboardView()) { Label("Overview", systemImage: "rectangle.3.group") }
				NavigationLink(destination: SparrowDiagnosticsView()) { Label("Diagnostics & Activity", systemImage: "stethoscope") }
				NavigationLink(destination: SparrowSigningPresetsView()) { Label("Signing Presets", systemImage: "square.stack.3d.up") }
			}
			Section("Power Tools") {
				NavigationLink(destination: SparrowIPACompareView()) { Label("Compare IPAs", systemImage: "arrow.left.arrow.right") }
				NavigationLink(destination: SparrowVersionVaultView()) { Label("Version History", systemImage: "clock.arrow.circlepath") }
				NavigationLink(destination: SparrowStorageCleanerView()) { Label("Storage", systemImage: "internaldrive") }
				NavigationLink(destination: SparrowIconStudioView()) { Label("Change App Icon", systemImage: "photo") }
				NavigationLink(destination: SparrowSignInstallView()) { Label("Sign & Install", systemImage: "arrow.down.app") }
				NavigationLink(destination: SparrowCertificateVaultView()) { Label("Certificate Security", systemImage: "lock.shield") }
			}
		}
		.navigationTitle("Sparrow Toolbox")
	}
}
