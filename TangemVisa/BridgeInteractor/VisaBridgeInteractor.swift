//
//  VisaBridgeInteractor.swift
//  TangemVisa
//
//  Created by Andrew Son on 15/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoSwift
import BlockchainSdk

public protocol VisaBridgeInteractor {
    var accountAddress: String { get }
    func loadBalances() async throws -> VisaBalances
    func loadLimits() async throws -> VisaLimits
}

struct DefaultBridgeInteractor {
    private let logger: InternalLogger

    private let smartContractInteractor: EVMSmartContractInteractor
    private let paymentAccount: String
    private let decimalCount: Int

    init(smartContractInteractor: EVMSmartContractInteractor, paymentAccount: String, logger: InternalLogger) {
        self.smartContractInteractor = smartContractInteractor
        self.paymentAccount = paymentAccount
        decimalCount = VisaUtilities().visaBlockchain.decimalCount
        self.logger = logger
    }
}

extension DefaultBridgeInteractor: VisaBridgeInteractor {
    var accountAddress: String { paymentAccount }

    func loadBalances() async throws -> VisaBalances {
        logger.debug(topic: .bridgeInteractor, "Attempting to load all balances for: \(accountAddress)")
        let loadedBalances: VisaBalances
        do {
            async let totalBalance = try await smartContractInteractor.ethCall(
                request: VisaSmartContractRequest(
                    contractAddress: VisaUtilities().visaToken.contractAddress,
                    method: GetTotalBalanceMethod(paymentAccountAddress: paymentAccount)
                )
            ).async()

            async let verifiedBalance = try await smartContractInteractor.ethCall(request: amountRequest(for: .verifiedBalance)).async()
            async let availableAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .availableForPayment)).async()
            async let blockedAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .blocked)).async()
            async let debtAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .debt)).async()
            async let pendingRefundAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .pendingRefund)).async()

            loadedBalances = try await VisaBalances(
                totalBalance: convertToDecimal(totalBalance),
                verifiedBalance: convertToDecimal(verifiedBalance),
                available: convertToDecimal(availableAmount),
                blocked: convertToDecimal(blockedAmount),
                debt: convertToDecimal(debtAmount),
                pendingRefund: convertToDecimal(pendingRefundAmount)
            )

            logger.debug(topic: .bridgeInteractor, "All balances sucessfully loaded: \(loadedBalances)")
            return loadedBalances
        } catch {
            logger.debug(topic: .bridgeInteractor, "Failed to load balances for \(accountAddress).\n\nReason: \(error)")
            throw error
        }
    }

    func loadLimits() async throws -> VisaLimits {
        logger.debug(topic: .bridgeInteractor, "Attempting to load limits for:")
        do {
            let limitsResponse = try await smartContractInteractor.ethCall(request: amountRequest(for: .limits)).async()
            logger.debug(topic: .bridgeInteractor, "Received limits response for \(accountAddress).\n\nResponse: \(limitsResponse)\n\nAttempting to parse...")
            let parser = LimitsResponseParser()
            let limits = try parser.parseResponse(limitsResponse)
            logger.debug(topic: .bridgeInteractor, "Limits sucessfully loaded: \(limits)")
            return limits
        } catch {
            logger.debug(topic: .bridgeInteractor, "Failed to load balances for: \(accountAddress).\n\nReason: \(error)")
            throw error
        }
    }
}

private extension DefaultBridgeInteractor {
    func amountRequest(for amountType: GetAmountMethod.AmountType) -> VisaSmartContractRequest {
        let method = GetAmountMethod(amountType: amountType)
        return VisaSmartContractRequest(contractAddress: paymentAccount, method: method)
    }

    func convertToDecimal(_ value: String) -> Decimal? {
        let decimal = EthereumUtils.parseEthereumDecimal(value, decimalsCount: decimalCount)
        logger.debug(topic: .bridgeInteractor, "Reponse \(value) converted into \(String(describing: decimal))")
        return decimal
    }
}
