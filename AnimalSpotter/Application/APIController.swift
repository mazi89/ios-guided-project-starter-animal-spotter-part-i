//
//  APIController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkError: Error {
    case badUrl
    case noAuth
    case badAuth
    case otherError
    case badData
    case noDecode
}

class APIController {
    
    private let baseUrl = URL(string: "https://lambdaanimalspotter.vapor.cloud/api")!
    
    var bearer: Bearer?
    // create function for sign up
    func signUp( with user: User, completion: @escaping (Error?) -> ()) {
        let signUpUrl = baseUrl.appendingPathComponent("users/signup")
        
        var request = URLRequest(url: signUpUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding user object: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError(domain: "Error this is the URL: \(request.url)", code: response.statusCode, userInfo: nil))
                return
            }
            
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    // create function for sign in
    func signIn( with user: User, completion: @escaping (Error?) -> ()) {
        let signIn = baseUrl.appendingPathComponent("users/login")
        
        var request = URLRequest(url: signIn)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding user object: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data , response, error in
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError(domain: "Error this is the URL: \(request.url)", code: response.statusCode, userInfo: nil))
                return
            }
            
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(NSError(domain: "Data not found", code: 99, userInfo: nil))
                return
            }
            
            let decoder = JSONDecoder()
            do {
                self.bearer = try decoder.decode(Bearer.self, from: data)
                completion(nil)
            } catch {
                NSLog("Error decoding bearer object: \(error)")
                completion(error)
            }
            completion(nil)
        }.resume()
    }
    // create function for fetching all animal names
    func fetchAllAnimalNames(completion: @escaping (Result<[String], NetworkError>) -> Void) {
        guard let bearer = bearer else {
            completion(.failure(.noAuth))
            return
        }
        
        let allAnimalsUrl = baseUrl.appendingPathComponent("animals/all")
        
        var request = URLRequest(url: allAnimalsUrl)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("Error receiving animal name data: \(error)")
                completion(.failure(.otherError))
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                // User is not authorized (no token or bad token)
                completion(.failure(.badAuth))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let jsonDecoder = JSONDecoder()
            do {
                let animalNames = try jsonDecoder.decode([String].self, from: data)
                completion(.success(animalNames))
            } catch {
                NSLog("Error decoding animal objects: \(error)")
                completion(.failure(.noDecode))
            }
            
        }.resume()
    }
    
    // create function for fetching animal details
    func fetchDetails(for animalName: String, completion: @escaping (Result<Animal, NetworkError>) -> Void) {
        guard let bearer = bearer else {
            completion(.failure(.noAuth))
            return
        }
        
        let animalUrl = baseUrl.appendingPathComponent("animals/\(animalName)")
        
        var request = URLRequest(url: animalUrl)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("Error receiving animal name data: \(error)")
                completion(.failure(.otherError))
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                // User is not authorized (no token or bad token)
                completion(.failure(.badAuth))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            do {
                let animal = try jsonDecoder.decode(Animal.self, from: data)
                completion(.success(animal))
            } catch {
                NSLog("Error decoding animal name: \(error)")
                completion(.failure(.noDecode))
            }
            
        }.resume()
    }
    
    // create function to fetch image
    func fetchImage(at urlString: String, completion: @escaping (Result<UIImage, NetworkError>) -> Void) {
        
        guard let imageUrl = URL(string: urlString) else {
            completion(.failure(.badUrl))
            return
        }
        
        var request = URLRequest(url: imageUrl)
        request.httpMethod = HTTPMethod.get.rawValue
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("Error receiving animal name data: \(error)")
                completion(.failure(.otherError))
            }
            
            
            guard let data = data else {
                NSLog("Github responded with no image data")
                completion(.failure(.badData))
                return
            }
            
            guard let image = UIImage(data: data) else {
                completion(.failure(.badData))
                return
            }
            
            completion(.success(image))
            
        }.resume()
    }
    
}
