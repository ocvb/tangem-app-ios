//
//  WalletSelectorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletSelectorView: View {
    @ObservedObject var viewModel: WalletSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandler()
                .padding(.bottom, 15)

            Text(Localization.manageTokensWalletSelectorTitle)
                .style(Fonts.Bold.headline, color: Colors.Text.primary1)
                .padding(.bottom, 25)

            VStack {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    WalletSelectorCellView(viewModel: itemViewModel)
                }
            }
            .background(Colors.Background.action)
            .padding(16)
        }
        .background(Colors.Background.secondary)
    }
}

struct WalletSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        WalletSelectorView(viewModel: WalletSelectorViewModel(userWallets: FakeUserWalletModel.allFakeWalletModels.map { $0.userWallet }, currentUserWalletId: FakeUserWalletModel.allFakeWalletModels.first?.userWallet.userWalletId ?? Data()))
    }
}
