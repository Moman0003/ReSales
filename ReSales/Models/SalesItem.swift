//
//  SalesItem.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation

struct SalesItem: Identifiable, Codable {
    var id: Int
    var description: String
    var price: Int
    var sellerEmail: String
    var sellerPhone: String
    var time: Int64
    var pictureUrl: String?
}
