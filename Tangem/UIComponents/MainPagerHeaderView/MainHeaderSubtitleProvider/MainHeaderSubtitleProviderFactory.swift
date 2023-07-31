//
//  MainHeaderSubtitleProviderFactory.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MainHeaderSubtitleProviderFactory {
    func provider(for userWalletModel: UserWalletModel) -> MainHeaderSubtitleProvider {
        guard userWalletModel.isMultiWallet else {
            return SingleWalletMainHeaderSubtitleProvider(userWalletModel: userWalletModel, walletModel: userWalletModel.walletModelsManager.walletModels.first)
        }

        return MultiWalletMainHeaderSubtitleProvider(
            isUserWalletLocked: userWalletModel.isUserWalletLocked,
            areWalletsImported: userWalletModel.userWallet.card.wallets.contains(where: { $0.isImported ?? false }),
            dataSource: userWalletModel
        )
    }
}
