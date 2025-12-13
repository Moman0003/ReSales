//
//  ItemRepository.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation

final class ItemRepository {
    private let api: ItemAPI

    init(api: ItemAPI = ItemAPI()) {
        self.api = api
    }

    func getAllItems() async throws -> [SalesItem] {
        try await api.getAll()
    }

    func createItem(
        description: String,
        price: Int,
        sellerEmail: String,
        sellerPhone: String,
        pictureUrl: String? = nil
    ) async throws -> SalesItem {

        let item = SalesItem(
            id: 0,
            description: description,
            price: price,
            sellerEmail: sellerEmail,
            sellerPhone: sellerPhone,
            time: Int64(Date().timeIntervalSince1970),
            pictureUrl: pictureUrl
        )

        return try await api.create(item)
    }

    func deleteItem(id: Int) async throws {
        try await api.delete(id: id)
    }
}
