
//
//  CARD.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public protocol TlvMapable {
    init?(from tlv: [Tlv])
}

@available(iOS 13.0, *)
public protocol CommandSerializer {
    associatedtype CommandResponse: TlvMapable
    
    func serialize(with environment: CardEnvironment) -> CommandApdu
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) -> CommandResponse?
}

@available(iOS 13.0, *)
public extension CommandSerializer {
    func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) -> CommandResponse? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let commandResponse = CommandResponse(from: tlv) else {
                return nil
        }
        
        return commandResponse
    }
}
