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
    
    @State private var copiedTag: String?
    @State private var showingToast = false
    @State private var toastMessage = ""

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Image(systemName: "tag.circle")
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
                    Table(searchResults, selection: $copiedTag) {
                        TableColumn("Tag", value: \.name)
                            .width(ideal: 200)
                        TableColumn("Last Updated", value: \.formattedLastUpdated)
                            .width(ideal: 150)
                        TableColumn("Size", value: \.formattedFullSize)
                            .width(ideal: 100)
                    }
                    .tableStyle(.bordered)
                    .alternatingRowBackgrounds()
                    .onChange(of: self.copiedTag, { oldValue, newValue in
                        if let tag = newValue {
                            copyToClipboard(imageName: searchText, tag: tag)
                        }
                    })
                    
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
            }
            ToastView(message: toastMessage, isShowing: $showingToast)
        }.onAppear {
            DispatchQueue.main.async {
                self.isSearchFieldFocused = true
            }
        }.onChange(of: self.imageNameForSearching) { oldValue, newValue in
            if !newValue.isEmpty {
                self.searchText = newValue
                searchDockerImage()
            }
        }
    }
    
    func copyToClipboard(imageName: String, tag: String) {
        let fullImageName = "\(imageName):\(tag)"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullImageName, forType: .string)
        
        toastMessage = "Copied \(fullImageName) to clipboard"
        showingToast = true
        
        // Reset the selection
        DispatchQueue.main.async {
            self.copiedTag = nil
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


struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isShowing)
        .padding(.bottom)
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
