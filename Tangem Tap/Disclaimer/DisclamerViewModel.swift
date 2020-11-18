//
//  DisclamerViewModel.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 03.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DisclaimerViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var userPrefsService: UserPrefsService!
    
    @Published var state: State = .accept
	
	private var cardViewModel: CardViewModel?
    
    private var bag = Set<AnyCancellable>()
    
	init(cardViewModel: CardViewModel?) {
		self.cardViewModel = cardViewModel
	}
	
    func accept() {
        userPrefsService.isTermsOfServiceAccepted = true
		if (cardViewModel?.isTwinCard ?? false), !userPrefsService.isTwinCardOnboardingWasDisplayed {
			navigation.openTwinCardOnboarding = true
		} else {
			navigation.openMainFromDisclaimer = true
		}
    }
}

extension DisclaimerViewModel {
    enum State {
        case accept
        case read
    }
}
