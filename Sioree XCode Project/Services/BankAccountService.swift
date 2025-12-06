//
//  BankAccountService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import Combine

struct BankAccount: Identifiable, Codable {
    let id: String
    let bankName: String
    let accountType: String // "checking" or "savings"
    let last4: String
    let isVerified: Bool
    let createdAt: Date
}

struct BankAccountResponse: Codable {
    let accounts: [BankAccount]
    let linkToken: String?
}

class BankAccountService: ObservableObject {
    static let shared = BankAccountService()
    private let networkService = NetworkService()
    
    // MARK: - Get Link Token (Plaid)
    func getLinkToken() -> AnyPublisher<String, Error> {
        // Call backend to get Plaid Link token
        struct LinkTokenResponse: Codable {
            let linkToken: String
        }
        
        return networkService.request("/api/bank/link-token", method: "POST")
            .map { (response: LinkTokenResponse) in response.linkToken }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Exchange Public Token (Plaid)
    func exchangePublicToken(_ publicToken: String) -> AnyPublisher<BankAccount, Error> {
        let body: [String: Any] = ["public_token": publicToken]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }
        
        // Call backend to exchange Plaid public token for access token
        return networkService.request("/api/bank/exchange-token", method: "POST", body: jsonData)
    }
    
    // MARK: - Get Connected Accounts
    func getConnectedAccounts() -> AnyPublisher<[BankAccount], Error> {
        struct AccountsResponse: Codable {
            let accounts: [BankAccount]
        }
        
        return networkService.request("/api/bank/accounts", method: "GET")
            .map { (response: AccountsResponse) in response.accounts }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Remove Account
    func removeAccount(_ accountId: String) -> AnyPublisher<Bool, Error> {
        struct DeleteResponse: Codable {
            let success: Bool
        }
        
        return networkService.request("/api/bank/accounts/\(accountId)", method: "DELETE")
            .map { (response: DeleteResponse) in response.success }
            .eraseToAnyPublisher()
    }
}

