//
//  MVClient.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 6/28/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import CoreData

final class MVClient: NSObject {
    
    /* Shared instance */
    static let sharedInstance = MVClient()
    
    /* Shared session */
    var session: URLSession
    
    /* Authentication state */
    var sessionID : String? = nil
    var userID : Int? = nil
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var scratchContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext()
        context.persistentStoreCoordinator =  CoreDataStackManager.sharedInstance().persistentStoreCoordinator
        return context
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK: Initializers
    
    override init() {
        session = URLSession.shared
        super.init()
    }
    
    // MARK: GET Image
    
    func taskForGETImage(_ size: String, filePath: String, completionHandler: @escaping (_ imageData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {
        
        /* 1. Set the parameters */
        // There are none...
        
        /* 2/3. Build the URL and configure the request */
        let baseURL = URL(string: MVClient.Constants.baseImageURLString)!
        let url = baseURL.appendingPathComponent(size).appendingPathComponent(filePath)
        let request = URLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? HTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            completionHandler(data, nil)
        }) 
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

    
    // MARK: GET
    func taskForGETMethod(_ method: String, parameters: [String : AnyObject], completionHandler: @escaping (Result<AnyObject, Error>) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the parameters */
        var mutableParameters = parameters
        mutableParameters[ParameterKeys.ApiKey] = Constants.ApiKey as AnyObject?
        
        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseURLSecure + method + MVClient.escapedParameters(mutableParameters)
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler(.failure(E: .network(error!.localizedDescription)))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? HTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                completionHandler(.failure(E: .parser(.BadData)))
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            MVClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }) 
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: POST
//    completionHandler: Result<AnyObject, Error> -> Void
    
    func taskForPOSTMethod(_ method: String, parameters: [String : AnyObject], jsonBody: [String:AnyObject], completionHandler: @escaping (Result<AnyObject, Error>) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the parameters */
        var mutableParameters = parameters
        mutableParameters[ParameterKeys.ApiKey] = Constants.ApiKey as AnyObject?
        
        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseURLSecure + method + MVClient.escapedParameters(mutableParameters)
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try! JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted)
        }
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(.failure(E: .network(error!.localizedDescription)))
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? HTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            MVClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }) 
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

}



// MARK: Helper Methods

extension MVClient {
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func substituteKeyInMethod(_ method: String, key: String, value: String) -> String? {
        if method.range(of: "{\(key)}") != nil {
            return method.replacingOccurrences(of: "{\(key)}", with: value)
        } else {
            return nil
        }
    }
    
    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (Result<AnyObject, Error>) -> Void) {
        
        var parsedResult: Any!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
             completionHandler(.failure(E: .parser(.BadData)))
        }
        
        completionHandler(.success(T: parsedResult as AnyObject))
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}
