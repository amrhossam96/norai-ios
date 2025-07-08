//
//  NoraiHostingCell.swift
//  Norai
//
//  Created by Amr on 08/07/2025.
//

import SwiftUI

class NoraiHostingCell<Content: View>: UICollectionViewCell {
    private var hostingController: UIHostingController<Content>?
    private var currentContentID: AnyHashable?
    
    func host(rootView: Content, itemID: AnyHashable? = nil) {
        // If we have the same item ID and an existing controller, try to update instead of recreate
        if let existingController = hostingController,
           let itemID = itemID,
           currentContentID == itemID {
            // Update the existing hosting controller's root view
            existingController.rootView = rootView
            existingController.view.setNeedsLayout()
            return
        }
        
        // Remove existing controller if any
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        
        // Create new controller
        let controller = UIHostingController(rootView: rootView)
        hostingController = controller
        currentContentID = itemID
        
        controller.view.backgroundColor = .clear
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(controller.view)

        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Don't remove the hosting controller here as we want to reuse it when possible
        currentContentID = nil
    }
    
    func cleanupHostingController() {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
        currentContentID = nil
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        guard let controller = hostingController else { return .zero }
        return controller.sizeThatFits(in: targetSize)
    }
}
