//
//  ZendeskSupportChatView.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

struct ZendeskSupportChatView: UIViewControllerRepresentable {
    let viewModel: ZendeskSupportChatViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        guard let viewController = try? viewModel.buildUI() else {
            return UINavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
        }

        viewController.navigationItem.setLeftBarButton(
            UIBarButtonItem(
                image: Assets.compass.uiImage,
                style: .plain,
                target: viewModel,
                action: #selector(ZendeskSupportChatViewModel.leftBarButtonItemDidTouch(_:))
            ),
            animated: true
        )

        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

//    func makeCoordinator() -> ZendeskSupportChatCoodinator {
//        return ZendeskSupportChatCoodinator(self, showUserActionSheet: viewModel.$showingUserActionMenu)
//    }
}
