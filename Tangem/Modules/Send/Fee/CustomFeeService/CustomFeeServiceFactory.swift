//
//  CustomFeeServiceFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CustomFeeServiceFactory {
    let input: CustomFeeServiceInput
    let output: CustomFeeServiceOutput
    let walletModel: WalletModel

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        walletModel: WalletModel,
    ) {
        self.input = input
        self.output = output
        self.walletModel = walletModel
    }

    func makeService() -> CustomFeeService? {
        if let bitcoinTransactionFeeCalculator = walletModel.bitcoinTransactionFeeCalculator {
            return CustomBitcoinFeeService(
                input: input,
                output: output,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )
        } else if walletModel.blockchainNetwork.blockchain.isEvm {
            return CustomEvmFeeService(
                input: input,
                output: output,
                blockchain: walletModel.blockchainNetwork.blockchain,
                feeTokenItem: walletModel.feeTokenItem
            )
        } else {
            return nil
        }
    }
}
