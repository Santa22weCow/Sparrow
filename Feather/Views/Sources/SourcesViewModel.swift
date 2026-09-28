//
//  SourcesViewModel.swift
//  Feather
//
//  Created by samara on 30.04.2025.
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Class
@MainActor
final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	@Published var isFinished = true
	@Published var sources: [AltSource: ASRepository] = [:]
	
	func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
		guard isFinished else { return }
		
		// check if sources to be fetched are the same as before, if yes, return
		// also skip check if refresh is true
		if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
		
		// isfinished is used to prevent multiple fetches at the same time
		isFinished = false
		defer { isFinished = true }
		
		let sourcesArray = Array(sources)
		// Show the last successful catalog immediately; fresh network data replaces
		// it as each repository returns.
		await MainActor.run {
			for source in sourcesArray {
				if let url = source.sourceURL, let cached = RepositoryCache.repository(for: url) {
					self.sources[source] = cached
				}
			}
		}
		
		for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourcesArray[startIndex..<endIndex]
			
			let batchResults = await withTaskGroup(of: (AltSource, ASRepository?).self, returning: [AltSource: ASRepository].self) { group in
				for source in batch {
					group.addTask {
						guard let url = source.sourceURL else {
							return (source, nil)
						}
						
						do {
							let (data, response) = try await URLSession.shared.data(from: url)
							guard (response as? HTTPURLResponse)?.statusCode == 200 else { return (source, nil) }
							let repo = try JSONDecoder().decode(ASRepository.self, from: data)
							RepositoryCache.save(data, for: url)
							return (source, repo)
						} catch { return (source, nil) }
					}
				}
				
				var results = [AltSource: ASRepository]()
				for await (source, repo) in group {
					if let repo {
						results[source] = repo
					}
				}
				return results
			}
			
			await MainActor.run {
				for (source, repo) in batchResults {
					self.sources[source] = repo
				}
			}
		}
	}
}
