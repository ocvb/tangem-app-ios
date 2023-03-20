//
//  ExchangeWalletDataProvider.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 09.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

class ExchangeWalletDataProvider {
    private let wallet: Wallet
    private let ethereumGasLoader: EthereumGasLoader
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let currencyMapper: CurrencyMapping

    private var balances: [Amount.AmountType: Decimal] = [:]
    private var walletAddress: String { wallet.address }

    init(
        wallet: Wallet,
        ethereumGasLoader: EthereumGasLoader,
        ethereumNetworkProvider: EthereumNetworkProvider,
        currencyMapper: CurrencyMapping
    ) {
        self.wallet = wallet
        self.ethereumGasLoader = ethereumGasLoader
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.currencyMapper = currencyMapper

        balances = wallet.amounts.reduce(into: [:]) {
            $0[$1.key] = $1.value.value.rounded(scale: $1.value.decimals, roundingMode: .down)
        }
    }
}

// MARK: - WalletDataProvider

extension ExchangeWalletDataProvider: WalletDataProvider {
    func getWalletAddress(currency: Currency) -> String? {
        guard wallet.blockchain.networkId == currency.blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return nil
        }

        return walletAddress
    }

    func getGasModel(
        sourceAddress: String,
        destinationAddress: String,
        data: Data,
        blockchain: ExchangeBlockchain,
        value: Decimal
    ) async throws -> EthereumGasDataModel {
        async let price = ethereumGasLoader.getGasPrice().async()
        async let limit = ethereumGasLoader.getGasLimit(
            to: destinationAddress,
            from: sourceAddress,
            value: createAmount(from: blockchain, amount: value).encodedForSend,
            data: "0x\(data.hexString)"
        ).async()

        // We are increasing the gas limit by 25% to be more confident that the transaction will be provider

        return try await EthereumGasDataModel(
            blockchain: blockchain,
            gasPrice: Int(price),
            gasLimit: Int(limit * 125 / 100)
        )
    }

    func getBalance(for currency: Currency) async throws -> Decimal {
        let amountType: Amount.AmountType

        switch currency.currencyType {
        case .token:
            guard let token = currencyMapper.mapToToken(currency: currency) else {
                assertionFailure("Currency isn't a token")
                return 0
            }

            amountType = Amount.AmountType.token(value: token)
        case .coin:
            amountType = Amount.AmountType.coin
        }

        if let balance = balances[amountType] {
            return balance
        }

        var balance = try await getBalanceFromNetwork(amountType: amountType)
        balance.round(scale: currency.decimalCount, roundingMode: .down)

        balances[amountType] = balance

        return balance
    }

    func getBalance(for blockchain: ExchangeBlockchain) async throws -> Decimal {
        guard wallet.blockchain.networkId == blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return 0
        }

        if let balance = balances[.coin] {
            return balance
        }

        let balance = try await getBalanceFromNetwork(amountType: .coin)
        balances[.coin] = balance
        return balance
    }
}

// MARK: - Private

private extension ExchangeWalletDataProvider {
    func createAmount(from currency: Currency, amount: Decimal) -> Amount {
        if let token = currencyMapper.mapToToken(currency: currency) {
            return Amount(with: token, value: amount)
        }

        return Amount(
            type: .coin,
            currencySymbol: currency.symbol,
            value: amount,
            decimals: currency.decimalCount
        )
    }

    func createAmount(from blockchain: ExchangeBlockchain, amount: Decimal) -> Amount {
        Amount(
            type: .coin,
            currencySymbol: blockchain.symbol,
            value: amount,
            decimals: blockchain.decimalCount
        )
    }

    func getBalanceFromNetwork(amountType: Amount.AmountType) async throws -> Decimal {
        switch amountType {
        case .coin:
            let balance = try await ethereumNetworkProvider.getBalance(walletAddress).async()
            balances[amountType] = balance
            return balance

        case .token(let token):
            let loadedBalances = try await ethereumNetworkProvider.getTokensBalance(
                walletAddress, tokens: [token]
            ).async()

            if let balance = loadedBalances[token] {
                balances[amountType] = balance
                return balance
            }

        case .reserve:
            throw CommonError.notImplemented
        @unknown default:
            throw CommonError.notImplemented
        }
        
        AppLog.shared.debug("WalletModel haven't balance for amountType \(amountType)")
        return 0
    }
}
