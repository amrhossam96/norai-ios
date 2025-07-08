//
//  NoraiScrollView+Coordinator.swift
//  Norai
//
//  Created by Amr on 08/07/2025.
//

import SwiftUI

public extension NoraiScrollView {
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        
        private var data: Data
        private let content: (Data.Element) -> Content
        var visibleIndexPaths: Set<IndexPath> = []
        
        init(data: Data, content: @escaping (Data.Element) -> Content) {
            self.data = data
            self.content = content
        }
        
        func updateData(_ newData: Data) {
            self.data = newData
        }
        
        public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            data.count
        }
        
        public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? NoraiHostingCell<Content> else {
                return UICollectionViewCell()
            }

            guard indexPath.item < data.count else {
                return cell
            }
            
            let item = data[data.index(data.startIndex, offsetBy: indexPath.item)]
            cell.host(rootView: content(item))
            return cell
        }
        
        private func checkVisibilityManually(in collectionView: UICollectionView) {
            scrollViewDidScroll(collectionView)
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let collectionView = scrollView as? UICollectionView else { return }
            let currentlyVisible = collectionView.indexPathsForVisibleItems
            
            for indexPath in currentlyVisible {
                guard let cellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else { continue }
                let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
                let intersection = visibleRect.intersection(cellFrame)
                let totalArea = cellFrame.width * cellFrame.height
                let visibleArea = intersection.width * intersection.height
                let visibleRatio = visibleArea / totalArea
                
                if visibleRatio >= 0.5 {
                    if !visibleIndexPaths.contains(indexPath) {
                        visibleIndexPaths.insert(indexPath)
                        // TODO: Trigger cell is visible
                        print("✅ Cell at \(indexPath) is visible (tracking started)")
                    }
                } else {
                    if visibleIndexPaths.contains(indexPath) {
                        visibleIndexPaths.remove(indexPath)
                        // TODO: Trigger cell is invisible
                        print("⛔️ Cell at \(indexPath) is no longer visible (tracking stopped)")
                    }
                }
            }
            
            let stillVisible = Set(currentlyVisible)
            let nowInvisible = visibleIndexPaths.subtracting(stillVisible)
            for indexPath in nowInvisible {
                visibleIndexPaths.remove(indexPath)
                // TODO: Trigger cell is invisible
                print("⛔️ Cell at \(indexPath) completely disappeared (tracking stopped)")
            }
        }
    }
}
