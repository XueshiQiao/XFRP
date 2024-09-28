//
//  DockerImage.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/28/24.
//

import Foundation
import SwiftUICore
import SwiftUI

struct DockerImageSearchView: View {
    @Binding var searchText: String
    @Binding var searchResults: [DockerImage]
    var onImageSelected: (_ imageName: String) -> Void

    @State private var isLoading = false
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var selection_image_name: String?

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "cube")
                    .foregroundColor(.secondary).imageScale(.large)
                TextField("Enter Docker image name to search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        searchDockerImages()
                    }
                Button("Search Images") {
                    searchDockerImages()
                }
                .disabled(isLoading)
            }
            .padding()
            
            ZStack {
                // selection bind the id of the model coresponding to current row
                Table(searchResults, selection: $selection_image_name) {
                    TableColumn("Image Name") { image in
                        HStack {
                            Text("\(image.name)")
                            if image.isOfficial {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                        .width(ideal: 70, max: 200)
                    
                    TableColumn("Stars") { image in
                        Text("\(image.starCount)")
                    }.width(ideal: 20, max: 50)
                    
                    TableColumn("Pulls") { image in
                        Text("\(image.pullCount)")
                    }.width(ideal: 25, max: 150)
                                        
                    TableColumn("Description", value: \.description)
                        .width(ideal: 100, max: 1000)
                }
                .onChange(of: selection_image_name) { oldValue, newValue in
                    print("new value: \(String(describing: newValue))")
                    if let newImageName = newValue {
                        onImageSelected(newImageName)
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 80, height: 80)
                        .background(Color.secondary.colorInvert().opacity(0.8))
                        .cornerRadius(10)
                }
            }

        }.onAppear {
            DispatchQueue.main.async {
                self.isSearchFieldFocused = true
            }
        }
    }
    
    func searchDockerImages() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        searchResults.removeAll()
        
        let urlString = "https://registry.hub.docker.com/v2/search/repositories/?query=\(searchText)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data {
                    if let decodedResponse = try? JSONDecoder().decode(DockerImageResponse.self, from: data) {
                        searchResults = decodedResponse.results
                    }
                }
                
                if let error = error {
                    print("Fetch failed: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

}


struct DockerImage: Codable, Identifiable {
    let name: String
    let description: String
    let starCount: Int64
    let pullCount: Int64
    let isOfficial: Bool
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name = "repo_name"
        case description = "short_description"
        case starCount = "star_count"
        case pullCount = "pull_count"
        case isOfficial = "is_official"
    }
}

struct DockerImageResponse: Codable {
    let results: [DockerImage]
}

// Helper extension for ByteCountFormatter
extension ByteCountFormatter {
    static func string(fromByteCount byteCount: Int64, countStyle: ByteCountFormatter.CountStyle) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = countStyle
        return formatter.string(fromByteCount: byteCount)
    }
}
