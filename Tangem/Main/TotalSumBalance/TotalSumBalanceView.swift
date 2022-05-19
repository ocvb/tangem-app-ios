//
//  TotalSumBalanceView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 11.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct TotalSumBalanceView: View {
    @ObservedObject var viewModel: TotalSumBalanceViewModel
    
    var tapOnCurrencySymbol: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("main_page_balance".localized.uppercased())
                    .lineLimit(1)
                    .font(Font.system(size: 14, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)
                    .padding(.leading, 16)
                    .padding(.top, 20)
                
                Spacer()
                
                Button {
                    tapOnCurrencySymbol()
                } label: {
                    HStack(spacing: 0) {
                        Text(viewModel.currencyType)
                            .lineLimit(1)
                            .font(Font.system(size: 16, weight: .medium))
                            .foregroundColor(Color.tangemGrayDark)
                            .padding(.trailing, 6)
                        Image("tangemArrowDown")
                            .foregroundColor(Color.tangemTextGray)
                            .padding(.trailing, 20)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 22)
            }
            .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isLoading {
                    ActivityIndicatorView(isAnimating: true, style: .medium, color: .gray)
                        .padding(.leading, 16)
                        .frame(height: 33)
                } else {
                    Text(viewModel.totalFiatValueString)
                        .lineLimit(1)
                        .font(Font.system(size: 28, weight: .semibold))
                        .foregroundColor(Color.tangemGrayDark6)
                        .padding(.leading, 16)
                        .frame(height: 33)
                }
                
                if viewModel.isFailed {
                    Text(viewModel.isFailed ? "main_processing_full_amount".localized : "")
                        .foregroundColor(Color.tangemWarning)
                        .font(.system(size: 13, weight: .regular))
                        .padding(.top, 2)
                        .padding(.leading, 16)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .onDisappear {
            viewModel.disableLoading()
        }
    }
}
