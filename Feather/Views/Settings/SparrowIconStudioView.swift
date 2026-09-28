import SwiftUI
import PhotosUI
import CoreData

struct SparrowIconStudioView: View {
	@FetchRequest(entity: Imported.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]) private var apps: FetchedResults<Imported>
	@State private var selectedID: NSManagedObjectID?
	@State private var photo: PhotosPickerItem?
	@State private var imageData: Data?
	@State private var isWorking = false
	@State private var message: String?
	@State private var showFiles = false

	var body: some View {
		Form {
			Section("App") { Picker("Imported app", selection: $selectedID) { Text("Choose an app").tag(nil as NSManagedObjectID?); ForEach(apps, id: \.objectID) { Text($0.name ?? "Unknown").tag(Optional($0.objectID)) } } }
			Section("Icon Source") { PhotosPicker("Choose from Photos", selection: $photo, matching: .images); Button("Choose from Files") { showFiles = true }; if let imageData, let image = UIImage(data: imageData) { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180).clipShape(RoundedRectangle(cornerRadius: 14)) } }
			if let app = selectedApp { Section("Icon Compatibility") { Label(SparrowIconStudioService.shared.compatibility(for: app).rawValue, systemImage: SparrowIconStudioService.shared.compatibility(for: app) == .fileBased ? "checkmark.circle" : "exclamationmark.triangle").foregroundStyle(SparrowIconStudioService.shared.compatibility(for: app) == .fileBased ? .green : .orange); if SparrowIconStudioService.shared.compatibility(for: app) == .assetCatalog { Text("This app stores icons in a compiled asset catalog. Sparrow will not modify it.").font(.footnote).foregroundStyle(.secondary) } } }
			if let message { Text(message).foregroundStyle(.orange) }
			Section { Button(isWorking ? "Creating Customized Copy…" : "Create Customized Copy") { customize() }.disabled(isWorking || selectedID == nil || imageData == nil) }
		}
		.navigationTitle("Icon Studio")
		.onChange(of: photo) { item in Task { imageData = try? await item?.loadTransferable(type: Data.self) } }
		.fileImporter(isPresented: $showFiles, allowedContentTypes: [.png, .jpeg, .heic]) { result in if case .success(let url) = result { imageData = try? Data(contentsOf: url) } }
	}
	private func customize() { guard let id = selectedID, let app = apps.first(where: { $0.objectID == id }), let data = imageData else { return }; isWorking = true; SparrowIconStudioService.shared.customize(app: app, imageData: data) { result in DispatchQueue.main.async { isWorking = false; switch result { case .success(let url): FR.handlePackageFile(url) { error in message = error == nil ? "Icon Updated. Customized copy imported into Sparrow." : error!.localizedDescription }; case .failure(let error): message = error.localizedDescription } } } }
	private var selectedApp: Imported? { guard let selectedID else { return nil }; return apps.first(where: { $0.objectID == selectedID }) }
}
