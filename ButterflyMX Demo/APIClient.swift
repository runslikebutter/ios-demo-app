//
//  APIClient.swift
//  ButterflyMX Demo
//
//  Created by Yingtao Guo on 5/20/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation

enum Result<Success, Error: Swift.Error> {
    case success(Success)
    case failure(Error)
}

class APIClient {
    static let shared = APIClient()
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?

    //TODO: Temp implementations for more registerDevice and unRegisterDevice.
    //TODO: More implementation will be added after setting up the server in docker
    
    func registerDevice(with deviceToken: String, completion: (Result<Data, Error>) -> Void) {
        print("Register the device with deviceToken: \(deviceToken)")
        
        UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        UserDefaults.standard.synchronize()
        
        completion(.success(Data()))
    }
    
    func unRegisterDevice(completion: (Result<Data, Error>) -> Void) {
        guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") else {
            return
        }
        
        print("Unregister the device with deviceToken: \(deviceToken)")
        completion(.success(Data()))
    }
}
