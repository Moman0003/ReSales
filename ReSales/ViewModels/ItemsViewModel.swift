//
//  ItemsViewModel.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation
import Combine

@MainActor
final class ItemsViewModel: ObservableObject {

    @Published private(set) var items: [SalesItem] = []
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private let repo: ItemRepository

    init(repo: ItemRepository) {
        self.repo = repo
    }

    func createItem(
        description: String,
        price: Int,
        sellerEmail: String,
        sellerPhone: String,
        pictureUrl: String? = nil
    ) async {
        errorMessage = nil

        do {
            let created = try await repo.createItem(
                description: description,
                price: price,
                sellerEmail: sellerEmail,
                sellerPhone: sellerPhone,
                pictureUrl: pictureUrl
            )

            // Ligesom Android: vis den nye annonce med det samme
            items.insert(created, at: 0)

            // Hvis backend ikke returnerer det nye item ordentligt, brug i stedet:
            // await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await repo.getAllItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(id: Int) async {
        do {
            try await repo.deleteItem(id: id)
            items.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    
    
}
