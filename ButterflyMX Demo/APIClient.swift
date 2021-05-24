//
//  APIClient.swift
//  ButterflyMX Demo
//
//  Created by Yingtao Guo on 5/20/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation

enum APIError: Error {
    case unableToCreateRequest(message: String)
    case runtime(error: Error)
}

class APIClient {
    static let shared = APIClient()
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?

    //TODO: Temp implementations for more registerDevice and unRegisterDevice.
    //TODO: More implementation will be added after setting up the server in docker
    
    func registerDevice(with deviceToken: String, completion: @escaping (Result<Data, APIError>) -> Void) {
        guard deviceToken.count > 0 else {
            completion(.failure(.unableToCreateRequest(message: "invalid device token.")))
            return
        }
        
        print("Register the device with deviceToken: \(deviceToken)")        
        UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        UserDefaults.standard.synchronize()
        
        completion(.success(Data()))
    }
    
    func unRegisterDevice(completion: @escaping (Result<Data, APIError>) -> Void) {
        guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") else {
            completion(.failure(.unableToCreateRequest(message: "invalid device token.")))
            return
        }
        
        print("Unregister the device with deviceToken: \(deviceToken)")
        completion(.success(Data()))
    }
}
