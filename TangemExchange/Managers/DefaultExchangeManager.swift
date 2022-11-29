//
//  DefaultExchangeManager.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 24.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultExchangeManager<TxBuilder: TransactionBuilder> {
    // MARK: - Dependencies

    private let exchangeProvider: ExchangeProvider
    private let transactionBuilder: TxBuilder
    private let blockchainInfoProvider: BlockchainInfoProvider
    private weak var delegate: ExchangeManagerDelegate?

    // MARK: - Internal

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var availabilityState: SwappingAvailabilityState = .idle {
        didSet { delegate?.exchangeManagerDidUpdate(availabilityState: availabilityState) }
    }
    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManagerDidUpdate(exchangeItems: exchangeItems) }
    }
    private var tokenExchangeAllowanceLimit: Decimal? {
        didSet {
            delegate?.exchangeManagerDidUpdate(
                availabilityForExchange: isAvailableForExchange(),
                limit: tokenExchangeAllowanceLimit
            )
        }
    }

    private var amount: Decimal?
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        exchangeProvider: ExchangeProvider,
        transactionBuilder: TxBuilder,
        blockchainInfoProvider: BlockchainInfoProvider,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        self.transactionBuilder = transactionBuilder
        self.blockchainInfoProvider = blockchainInfoProvider
        self.exchangeItems = exchangeItems
        self.amount = amount

        updateSourceBalances()
        updateExchangeAmountAllowance()
    }
}

// MARK: - Private

extension DefaultExchangeManager: ExchangeManager {
    func setDelegate(_ delegate: ExchangeManagerDelegate) {
        self.delegate = delegate
    }

    func getNetworksAvailableToSwap() -> [String] {
        return ["\(exchangeItems.source.blockchain.chainId)"]
    }

    func getAvailabilityState() -> SwappingAvailabilityState {
        return availabilityState
    }

    func getExchangeItems() -> ExchangeItems {
        return exchangeItems
    }

    func isAvailableForExchange() -> Bool {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request available for exchange for coin")
            return true
        }

        /// If we don't have values, `return true` for move view to default state
        guard let tokenExchangeAllowanceLimit, let amount else {
            return true
        }

        return amount <= tokenExchangeAllowanceLimit
    }

    func update(exchangeItems: ExchangeItems) {
        self.exchangeItems = exchangeItems
        exchangeItemsDidUpdate()
    }

    func update(amount: Decimal?) {
        self.amount = amount
        amountDidChange()
    }

    func approveAndSwapItems() {
        sendTransactionForSwapItems()
    }

    func swapItems() {
        sendTransactionForSwapItems()
    }
}

private extension DefaultExchangeManager {
    func exchangeItemsDidUpdate() {
        if exchangeItems.source.isToken {
            updateExchangeAmountAllowance()
        }

        restartTimer()
        updateSwappingInformation()
    }

    func updateExchangeAmountAllowance() {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request fetchExchangeAmountAllowance for coin")
            return
        }

        guard let walletAddress = blockchainInfoProvider.getWalletAddress(currency: exchangeItems.source) else {
            print("walletAddress not found")
            return
        }

        Task {
            do {
                tokenExchangeAllowanceLimit = try await exchangeProvider.fetchExchangeAmountAllowance(
                    for: exchangeItems.source,
                    walletAddress: walletAddress
                )
            } catch {
                tokenExchangeAllowanceLimit = nil
                availabilityState = .requiredRefresh(occurredError: error)
            }
        }
    }

    func updateSwappingInformation() {
        guard let amount = amount else {
            print("Amount hasn't been set")
            return
        }

        guard let walletAddress = blockchainInfoProvider.getWalletAddress(currency: exchangeItems.source) else {
            print("walletAddress not found")
            return
        }

        availabilityState = .loading

        Task {
            do {
                let swappingData = try await exchangeProvider.fetchTxDataForSwap(
                    items: exchangeItems,
                    walletAddress: walletAddress,
                    amount: amount.description,
                    slippage: 1 // Default value
                )

                availabilityState = .available(swappingData: swappingData)
            } catch {
                print("error", error)
                availabilityState = .requiredRefresh(occurredError: error)
            }
        }
    }

    func updateExchangeApprovedDataModel() {
        Task {
            do {
                let approvedData = try await exchangeProvider.approveTxData(for: exchangeItems.source)
                availabilityState = .requiredPermission(approvedData: approvedData)
            } catch {
                availabilityState = .requiredRefresh(occurredError: error)
            }
        }
    }

    func sendTransactionForSwapItems() {
        guard let amount = amount,
              case let .available(swappingData) = availabilityState,
              let gasPrice = Decimal(string: swappingData.gasPrice),
              let walletAddress = blockchainInfoProvider.getWalletAddress(currency: exchangeItems.destination)
        else {
            assertionFailure("Not enough data")
            return
        }

        let info = SwapTransactionInfo(
            currency: exchangeItems.source,
            destination: walletAddress,
            amount: amount,
            oneInchTxData: swappingData.txData
        )

        let gasValue = Decimal(swappingData.gas)

        Task {
            do {
                try await sendSwapTransaction(info, gasValue: gasValue, gasPrice: gasPrice)
            } catch {
                availabilityState = .requiredRefresh(occurredError: error)
            }
        }
    }

    func amountDidChange() {
        updateSourceBalances()

        guard let tokenExchangeAllowanceLimit else {
            return
        }

        if isAvailableForExchange() {
            updateSwappingInformation()
        } else {
            updateExchangeApprovedDataModel()
        }

        delegate?.exchangeManagerDidUpdate(
            availabilityForExchange: isAvailableForExchange(),
            limit: tokenExchangeAllowanceLimit
        )
    }

    func updateSourceBalances() {
        let source = exchangeItems.source
        let balance = blockchainInfoProvider.getBalance(currency: source)
        var fiatBalance: Decimal = 0
        if let amount {
            fiatBalance = blockchainInfoProvider.getFiatBalance(currency: source, amount: amount)
        }

        exchangeItems.sourceBalance = CurrencyBalance(balance: balance, fiatBalance: fiatBalance)
    }

    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func startTimer() {
        refreshDataTimerBag = refreshDataTimer
            .print("timer")
            .upstream
            .print("timer upstream")
            .sink { [weak self] _ in
                self?.updateSwappingInformation()
            }
    }

    func stopTimer() {
        refreshDataTimerBag?.cancel()
        refreshDataTimer
            .upstream
            .connect()
            .cancel()
    }
}

private extension DefaultExchangeManager {
    // MARK: - Sending API

    func sendSwapTransaction(_ info: SwapTransactionInfo, gasValue: Decimal, gasPrice: Decimal) async throws {
        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)

        let transaction = try transactionBuilder.buildTransaction(for: info, fee: gas)
        let signedTransaction = try await transactionBuilder.sign(transaction)

        return try await transactionBuilder.send(signedTransaction)
    }

    func submitPermissionForToken(_ info: SwapTransactionInfo, gasPrice: Decimal) async throws {
        let fees = try await blockchainInfoProvider.getFee(currency: info.currency, amount: info.amount, destination: info.destination)
        let gasValue: Decimal = fees[1]

        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)
        let transaction = try transactionBuilder.buildTransaction(for: info, fee: gas)
        let signedTransaction = try await transactionBuilder.sign(transaction)

        return try await transactionBuilder.send(signedTransaction)
    }

    func gas(from value: Decimal, price: Decimal, decimalCount: Int) -> Decimal {
        value * price / Decimal(decimalCount)
    }
}

