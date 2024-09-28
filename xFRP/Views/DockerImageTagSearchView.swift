//
//  DockerImage.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/28/24.
//

import Foundation
import SwiftUICore
import SwiftUI

struct DockerImageTagSearchView: View {
    @Binding var searchText: String
    @Binding var searchResults: [ImageTag]
    @Binding var imageNameForSearching: String
    @State private var isLoading = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack {
            HStack {
                TextField("Enter Docker image name, then press 'Enter'", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        searchDockerImage()
                    }
                Button("Search") {
                    searchDockerImage()
                }
            }
            .padding()
            
            ZStack {
                Table(searchResults) {
                    TableColumn("Name", value: \.name)
                        .width(ideal: 200)
                    TableColumn("Last Updated", value: \.formattedLastUpdated)
                        .width(ideal: 150)
                    TableColumn("Size", value: \.formattedFullSize)
                        .width(ideal: 100)
                }
                .tableStyle(.bordered)
                .alternatingRowBackgrounds()
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .padding(.top, 10)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.secondary.colorInvert().opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }

        }.onAppear {
            DispatchQueue.main.async {
                self.isSearchFieldFocused = true
            }
            if !self.imageNameForSearching.isEmpty {
                self.searchText = self.imageNameForSearching
                searchDockerImage()
            }
        }
    }
    
    func searchDockerImage() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        searchResults.removeAll()
        
        let pageSize = 50
        let urlString: String
        if containsSlash(searchText) {  // like 'ubuntu'
            urlString = "https://registry.hub.docker.com/v2/repositories/\(searchText)/tags?page_size=\(pageSize)"
        } else {  // like 'ubuntu/nginx'
            urlString = "https://registry.hub.docker.com/v2/repositories/library/\(searchText)/tags?page_size=\(pageSize)"
        }

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data {
                    if let decodedResponse = try? JSONDecoder().decode(DockerResponse.self, from: data) {
                        searchResults = decodedResponse.results
                    }
                }
                
                if let error = error {
                    print("Fetch failed: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func containsSlash(_ repoName: String) -> Bool {
        return repoName.contains("/")
    }

}


struct ImageTag: Codable, Identifiable {
    let name: String
    let lastUpdated: String
    let fullSize: Int64
    
    var id: String { name }
    
    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
        if let date = formatter.date(from: lastUpdated) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
        return lastUpdated // Return original string if parsing fails
    }
    
    var formattedFullSize: String {
        ByteCountFormatter.string(fromByteCount: fullSize, countStyle: .file)
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case lastUpdated = "last_updated"
        case fullSize = "full_size"
    }
}

struct DockerResponse: Codable {
    let results: [ImageTag]
}

// Helper extension for ByteCountFormatter
//extension ByteCountFormatter {
//    static func string(fromByteCount byteCount: Int64, countStyle: ByteCountFormatter.CountStyle) -> String {
//        let formatter = ByteCountFormatter()
//        formatter.allowedUnits = [.useAll]
//        formatter.countStyle = countStyle
//        return formatter.string(fromByteCount: byteCount)
//    }
//}
