//
//  CardManagerDelegate.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol CardManagerDelegate: class {
    func showSecurityDelay(remainingSeconds: Int)
    func requestPin(completion: @escaping () -> CompletionResult<String>)
}

final class DefaultCardManagerDelegate: CardManagerDelegate {
    private let reader: NFCReaderText
    
    init(reader: NFCReaderText) {
        self.reader = reader
    }
    
    func showSecurityDelay(remainingSeconds: Int) {
        reader.alertMessage = "\(remainingSeconds)"
    }
    
    func requestPin(completion: @escaping () -> CompletionResult<String>) {
    }
}
