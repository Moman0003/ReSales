//
//  ItemAPI.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation

final class ItemAPI {
    private let baseURL: String
    private let itemsPath: String
    private let session: URLSession

    init(
        baseURL: String = "https://anbo-salesitems.azurewebsites.net/api",
        itemsPath: String = "/SalesItems",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.itemsPath = itemsPath
        self.session = session
    }

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        return url
    }

    func getAll() async throws -> [SalesItem] {
        let url = try makeURL(itemsPath)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }

            do {
                return try JSONDecoder().decode([SalesItem].self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        } catch {
            throw APIError.underlying(error)
        }
    }

    func create(_ item: SalesItem) async throws -> SalesItem {
        let url = try makeURL(itemsPath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(item)
        } catch {
            throw APIError.encodingFailed
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }

            do {
                return try JSONDecoder().decode(SalesItem.self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        } catch {
            throw APIError.underlying(error)
        }
    }

    func delete(id: Int) async throws {
        let url = try makeURL(itemsPath + "/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        } catch {
            throw APIError.underlying(error)
        }
    }
}
