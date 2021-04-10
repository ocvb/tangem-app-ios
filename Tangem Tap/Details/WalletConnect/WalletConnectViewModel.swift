//
//  WalletConnectViewModel.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 22.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class WalletConnectViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var walletConnectService: WalletConnectService!
    weak var walletConnectController: WalletConnectSessionController!
    
    @Published var error: AlertBinder?
    @Published var isConnecting: Bool = false
    @Published var isConnected: Bool = false
    @Published var code: String = ""
    
    var buttonTitle: String {
        isConnected ? "Disconnect" : "Connect"
    }
    
    var statusTitle: String {
        isConnected ? "Connected" : "Not connected"
    }
    
    private var bag = Set<AnyCancellable>()
    
    init() {}
    
    func onAppear() {
        bag = []
        
        $code
            .dropFirst()
            .sink {[unowned self] newCode in
                if self.walletConnectService.handle(url: newCode) {
                    self.isConnecting = true
                }
                else {
                    self.error = WalletConnectService.WalletConnectServiceError.failedToConnect.alertBinder
                }
            }
            .store(in: &bag)
        
        walletConnectService.connecting
            .receive(on: DispatchQueue.main)
            .sink {[unowned self] isConnecting in
                self.isConnecting = isConnecting
              //  self.isConnected = isConnected
            }
            .store(in: &bag)
        
        walletConnectService.error
            .receive(on: DispatchQueue.main)
            .sink {[unowned self]  error in
                self.isConnecting = false
                self.error = error.alertBinder
            }
            .store(in: &bag)
    }
    
    func disconnectSession(at index: Int) {
        walletConnectService.disconnectSession(at: index)
        withAnimation {
            self.objectWillChange.send()
        }
    }
    
    func openNewSession() {
        navigation.walletConnectToQR = true
    }
}
