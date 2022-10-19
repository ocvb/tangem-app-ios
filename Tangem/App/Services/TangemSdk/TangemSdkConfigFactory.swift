//
//  TangemSdkConfigFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TangemSdkConfigFactory {
    @Injected(\.loggerProvider) var loggerProvider: LoggerProviding

    func makeDefaultConfig() -> Config {
        var config = Config()
        config.filter.allowedCardTypes = [.release, .sdk]
        config.logConfig = Log.Config.custom(logLevel: Log.Level.allCases,
                                             loggers: [loggerProvider.logger, ConsoleLogger()])
        config.filter.batchIdFilter = .deny(["0027", // todo: tangem tags
                                             "0030",
                                             "0031",
                                             "0035"])

        config.filter.issuerFilter = .deny(["TTM BANK"])
        config.allowUntrustedCards = true
        config.biometricsLocalizedReason = "biometry_touch_id_reason".localized
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        #warning("TODO TODO TODO TODO TODO")
        config.attestationMode = .offline

        return config
    }
}
