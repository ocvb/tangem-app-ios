//
//  PushTxCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 16.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class PushTxCoordinator: CoordinatorObject {
    //MARK: - View models
    @Published private(set) var pushTxViewModel: PushTxViewModel!
    @Published var mailViewModel: MailViewModel? = nil
    
    var dismissAction: () -> Void = {}
    
    func start(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) {
        pushTxViewModel = PushTxViewModel(transaction: tx,
                                          blockchainNetwork: blockchainNetwork,
                                          cardViewModel: card,
                                          coordinator: self)
    }
}


extension PushTxCoordinator: PushTxRoutable {
    func openMail(with dataCollector: EmailDataCollector) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: .tangem, emailType: .failedToPushTx)
    }
}
