//
//  APIError.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decodingFailed
    case encodingFailed
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .badStatus(let code): return "Server returned HTTP \(code)"
        case .decodingFailed: return "Could not decode response"
        case .encodingFailed: return "Could not encode request"
        case .underlying(let err): return err.localizedDescription
        }
    }
}
