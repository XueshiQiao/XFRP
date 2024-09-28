//
//  DockerImage.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/28/24.
//

import Foundation
import SwiftUICore
import SwiftUI

struct DockerImageView: View {
    
    @State private var tagSearchText = ""
    @State private var imageSearchText = ""
    @State private var tagSearchResults: [ImageTag] = []
    @State private var imageSearchResults: [DockerImage] = []

    @State private var imageNameForSearching: String = ""

    
    var body: some View {
        HStack {
            DockerImageSearchView(searchText: $imageSearchText, searchResults: $imageSearchResults, onImageSelected: searchTagWithImage)
            DockerImageTagSearchView(searchText: $tagSearchText, searchResults: $tagSearchResults, imageNameForSearching: $imageNameForSearching)
        }.navigationTitle(L10n.MainView.dockerImage.capitalized)

    }
    
    func searchTagWithImage(_ imageName: String) {
        imageNameForSearching = imageName
    }
}
