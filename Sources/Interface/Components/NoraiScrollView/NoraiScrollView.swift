//
//  NoraiScrollView.swift
//  Norai
//
//  Created by Amr on 08/07/2025.
//

import UIKit
import SwiftUI

struct NoraiScrollView<Data: RandomAccessCollection, Content: View>: UIViewRepresentable where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    
    func makeUIView(context: Context) -> UICollectionView {
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
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.data = data
        uiView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(data: data, content: content)
    }
}
