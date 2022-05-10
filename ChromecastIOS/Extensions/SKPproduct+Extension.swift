//
//  SKPproduct+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import Foundation
import StoreKit

extension SKProduct {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    var isFree: Bool {
        price == 0.00
    }

    var localizedPrice: String? {
        guard !isFree else {
            return nil
        }
        
        let formatter = SKProduct.formatter
        formatter.locale = priceLocale

        return formatter.string(from: price)
    }

}

extension String {
    var swapPriceAndCurrency: String {
        let array = components(separatedBy: .whitespaces)
        return array.count == 2 ? "\(array[1])\(array[0])" : self.trimmingCharacters(in: .whitespaces)
    }
}
