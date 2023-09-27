//
//  Separator.swift
//  Tangem
//
//  Created by Andrew Son on 16/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct Separator: View {
    @Environment(\.displayScale) private var displayScale

    enum Height {
        case exact(Double)
        case minimal
    }

    private let height: Height
    private let padding: Double
    private let color: Color

    private var heightValue: Double {
        switch height {
        case .exact(let value):
            return value
        case .minimal:
            return 1.0 / displayScale
        }
    }

    var body: some View {
        color
            .frame(height: heightValue)
            .padding(.vertical, padding)
    }

    init(height: Height = .exact(1), padding: Double = 4, color: Color = Color.tangemGrayLight5) {
        self.height = height
        self.padding = padding
        self.color = color
    }
}
