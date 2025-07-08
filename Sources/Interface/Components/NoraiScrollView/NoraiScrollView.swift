//
//  NoraiScrollView.swift
//  Norai
//
//  Created by Amr on 08/07/2025.
//

import UIKit
import SwiftUI

public struct NoraiScrollView<Data: RandomAccessCollection, Content: View>: UIViewRepresentable where Data.Element: Identifiable {
    @Binding var data: Data
    let content: (Data.Element) -> Content
    
    public init(data: Binding<Data>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self._data = data
        self.content = content
    }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(250))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(250))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(NoraiHostingCell<Content>.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        // Update the coordinator with the latest content closure and data
        context.coordinator.updateData(data, content: content)
        
        // Always reload to ensure SwiftUI state changes are reflected
        // This is similar to how ForEach rebuilds when state changes
        uiView.reloadData()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(data: data, content: content)
    }
}
