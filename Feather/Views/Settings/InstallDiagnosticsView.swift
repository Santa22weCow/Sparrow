import SwiftUI

struct InstallDiagnosticsView: View {
	@AppStorage("Feather.serverMethod") private var serverMethod = 0
	@AppStorage("Feather.manifestServiceURL") private var manifestServiceURL = ""
	@AppStorage("Feather.builtInSigningCertificateStatus") private var certificateStatus = "No bundled signing certificate was found."

	var body: some View {
		Form {
			Section("Installation") {
				LabeledContent("Server mode", value: serverMethod == 0 ? "Fully Local" : "Semi Local")
				LabeledContent("Local delivery", value: "127.0.0.1 (loopback)")
				if serverMethod == 1 { LabeledContent("Manifest service", value: manifestServiceURL.isEmpty ? "Not configured" : manifestServiceURL) }
			}
			Section("Signing") { LabeledContent("Built-in certificate", value: certificateStatus) }
			Section("What to check after a failure") {
				Text("Open the device console and search for Install server, health check, manifest provider, or iOS refused. Sparrow reports listener, TLS, provider, and timeout failures there and in the install alert.")
					.font(.footnote).foregroundStyle(.secondary)
			}
		}
		.navigationTitle("Install Diagnostics")
	}
}
