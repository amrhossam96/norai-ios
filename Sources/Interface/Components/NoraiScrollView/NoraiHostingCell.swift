//
//  NoraiHostingCell.swift
//  Norai
//
//  Created by Amr on 08/07/2025.
//

import SwiftUI

class NoraiHostingCell<Content: View>: UICollectionViewCell {
    private var hostingController: UIHostingController<Content>?
    
    func host(rootView: Content) {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil

        let controller = UIHostingController(rootView: rootView)
        hostingController = controller
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
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        guard let controller = hostingController else { return .zero }
        return controller.sizeThatFits(in: targetSize)
    }
}
