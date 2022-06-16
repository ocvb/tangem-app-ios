//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingCoordinator: ObservableObject, Identifiable {    
    //MARK: - View models
    @Published var singleCardViewModel: SingleCardOnboardingViewModel? = nil
    @Published var twinsViewModel: TwinsOnboardingViewModel? = nil
    @Published var walletViewModel: WalletOnboardingViewModel? = nil
    @Published var buyCryptoModel: WebViewContainerViewModel? = nil
    @Published var accessCodeModel: OnboardingAccessCodeViewModel? = nil
    
    //For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}
    
    func start(with input: OnboardingInput) {
        switch input.steps {
        case .singleWallet:
            singleCardViewModel = SingleCardOnboardingViewModel(input: input, coordinator: self)
        case .twins:
            twinsViewModel = TwinsOnboardingViewModel(input: input, coordinator: self)
        case .wallet:
            let model = WalletOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            walletViewModel = model
        }
    }
}

extension OnboardingCoordinator: OnboardingTopupViewModelRoutable {
    func openCryptoShop(at url: URL, closeUrl: String, action: @escaping () -> Void) {
        buyCryptoModel = .init(url: url,
                               title: "wallet_button_topup".localized,
                               addLoadingIndicator: true,
                               withCloseButton: true, urlActions: [closeUrl : {[weak self] _ in
            DispatchQueue.main.async {
                action()
                self?.buyCryptoModel = nil
            }
        }])
    }
}

extension OnboardingCoordinator: WalletOnboardingViewRoutable {
    func openAccessCodeView(callback: @escaping (String) -> Void) {
        accessCodeModel = .init(successHandler: {[weak self] code in
            self?.accessCodeModel = nil
            callback(code)
        })
    }
}
