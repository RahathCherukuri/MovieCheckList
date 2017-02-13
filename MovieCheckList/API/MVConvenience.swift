//
//  MVConvenience.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 6/28/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension MVClient {
    
    func authenticateWithViewController(_ hostViewController: UIViewController, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        self.getRequestToken() { dataResult in
            switch dataResult {
            case .success(let requestToken):
                print("requestToken: \(requestToken)")
                self.loginWithToken(requestToken as? String, hostViewController: hostViewController) {(success, errorString) in
                    if success {
                        print("success")
                        self.getSessionID((requestToken as? String)!) { dataResult in
                            switch dataResult {
                            case .success(let sessionID):
                                self.sessionID = sessionID as? String
                                Foundation.UserDefaults.standard.setValue(self.sessionID, forKey: MVClient.UserDefaults.SessionID)
                                print("sessionID: \(self.sessionID)")
                                self.getUserID(self.sessionID!) { dataResult in
                                    switch dataResult {
                                    case .success(let id):
                                        self.userID = id as? Int
                                        Foundation.UserDefaults.standard.set(self.userID!, forKey: MVClient.UserDefaults.UserID)
                                        print("UserID: \(self.userID)")
                                        completionHandler(true, nil)
                                    case .failure(let error):
                                        completionHandler(false, self.getErrorString(error))
                                    }
                                }
                            case .failure(let error):
                                completionHandler(false, self.getErrorString(error))
                            }
                        }
                    } else {
                        completionHandler(false, errorString)
                    }
                }
            case .failure(let error):
                completionHandler(false, self.getErrorString(error))
            }
        }
    }
    
    // Gets the RequestToken
    func getRequestToken(_ completionHandler: @escaping (Result<AnyObject, Error>) -> Void) {
        let method = Methods.AuthenticationTokenNew
        let parameters: [String : AnyObject] = [ : ]
        
        _ = taskForGETMethod(method, parameters: parameters) { dataResult in
            switch dataResult {
            case .success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    let requestToken = dic[MVClient.JSONResponseKeys.RequestToken] as? String
                else {
                    completionHandler(.failure(E: .parser(.BadData)))
                    return
                }
                completionHandler(.success(T: requestToken as AnyObject))
            case .failure:
                completionHandler(dataResult)
            }
        }
    }
    
    /* This function opens a MVAuthViewController to handle Step 2a of the auth flow */
    func loginWithToken(_ requestToken: String?, hostViewController: UIViewController, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        let authorizationURL = URL(string: "\(MVClient.Constants.AuthorizationURL)\(requestToken!)")
        let request = URLRequest(url: authorizationURL!)
        
        let webAuthViewController = hostViewController.storyboard!.instantiateViewController(withIdentifier: "MVAuthViewController") as! MVAuthViewController
        webAuthViewController.urlRequest = request
        webAuthViewController.requestToken = requestToken
        webAuthViewController.completionHandler = completionHandler
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)
        
        DispatchQueue.main.async(execute: {
            hostViewController.present(webAuthNavigationController, animated: true, completion: nil)
        })
    }
    
    // Gets the sessionID
    func getSessionID(_ requestToken: String, completionHandler: @escaping (Result<AnyObject, Error>) -> Void) {
        let method: String = Methods.AuthenticationSessionNew
        let parameters: [String : AnyObject] = [ParameterKeys.RequestToken: requestToken as AnyObject]
        
        _ = taskForGETMethod(method, parameters: parameters) { dataResult in
            switch dataResult {
            case .success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    let sessionID = dic[MVClient.JSONResponseKeys.SessionID] as? String
                    else {
                        completionHandler(.failure(E: .parser(.BadData)))
                        return
                }
                completionHandler(.success(T: sessionID as AnyObject))
            case .failure:
                completionHandler(dataResult)
            }
        }
    }
    
    //Gets the UserID
    func getUserID(_ session_id: String, completionHandler: @escaping (Result<AnyObject, Error>) -> Void) {
        let method: String = Methods.Account
        let parameters: [String: AnyObject] = [ParameterKeys.SessionID:session_id as AnyObject]
        
        _ = taskForGETMethod(method, parameters: parameters) { dataResult in
            switch dataResult {
            case .success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    let userID = dic[MVClient.JSONResponseKeys.UserID] as? Int
                    else {
                        completionHandler(.failure(E: .parser(.BadData)))
                        return
                }
                completionHandler(.success(T: userID as AnyObject))
            case .failure:
                completionHandler(dataResult)
            }
        }
    }
    
    //Get the watchlist, iterate through the list and get each movie information
    func getWatchlistMovies(_ completionHandler: @escaping (_ success: Bool, _ errorString: String?, _ movies: [Movie]?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID: MVClient.sharedInstance.sessionID!]
        var mutableMethod : String = Methods.AccountIDWatchlistMovies
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        
        _ = taskForGETMethod(mutableMethod, parameters: parameters as [String : AnyObject]) {dataResult in
            switch dataResult {
            case .success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    let watchMovieResults = dic[MVClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]]
                    else {
                        let errorString = self.getErrorString(AppError.parser(.BadData))
                        completionHandler(false, errorString, nil)
                        return
                }
                
                let myGroup = DispatchGroup()
                _ = watchMovieResults.map({
                    guard let id = $0[MVClient.JSONResponseKeys.UserID] as? Int else {
                        return
                    }
                    myGroup.enter()
                    self.getMovieInfo(id) {dataResult in
                        switch dataResult {
                        case .success(let mov):
                            var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                            movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = false as AnyObject?
                            _ = Movie(dictionary: movieDictionary, context: MVClient.sharedInstance.sharedContext)
                            myGroup.leave()
                        case .failure(let error):
                            let errorString = self.getErrorString(error)
                            completionHandler(false, errorString, nil)
                        }
                    }
                })
                myGroup.notify(queue: DispatchQueue.main, execute: {
                    MVClient.sharedInstance.saveContext()
                    let toWatchMovies = self.fetchMovies(false)
                    completionHandler(true, nil, toWatchMovies)
                })
            case .failure(let error):
                let errorString = self.getErrorString(error)
                completionHandler(false, errorString, nil)
            }
        }
    }

    
    //Get the FavouriteList, iterate through the list and get each movie information
    func getFavoriteMovies(_ completionHandler: @escaping (_ success: Bool, _ errorString: String?, _ movies: [Movie]?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID: MVClient.sharedInstance.sessionID!]
        var mutableMethod : String = Methods.AccountIDFavoriteMovies
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        
        /* 2. Make the request */
        _ = taskForGETMethod(mutableMethod, parameters: parameters as [String : AnyObject]) { dataresult in
            switch dataresult {
            case .success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    let watchMovieResults = dic[MVClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]]
                    else {
                        let errorString = self.getErrorString(AppError.parser(.BadData))
                        completionHandler(false, errorString, nil)
                        return
                }
                let myGroup = DispatchGroup()
                _ = watchMovieResults.map({
                    guard let id = $0[MVClient.JSONResponseKeys.UserID] as? Int else {
                        return
                    }
                    myGroup.enter()

                    self.getMovieInfo(id) {dataResult in
                        switch dataResult {
                        case .success(let mov):
                            var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                            movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = true as AnyObject?
                            _ = Movie(dictionary: movieDictionary, context: MVClient.sharedInstance.sharedContext)
                            myGroup.leave()
                        case .failure(let error):
                            let errorString = self.getErrorString(error)
                            completionHandler(false, errorString, nil)
                        }
                    }
                })
                myGroup.notify(queue: DispatchQueue.main, execute: {
                    MVClient.sharedInstance.saveContext()
                    let watchListMovies = self.fetchMovies(true)
                    completionHandler(true, nil, watchListMovies)
                })
            case .failure(let error):
                let errorString = self.getErrorString(error)
                completionHandler(false, errorString, nil)
            }
        }
    }
    
    // Get movies with the search string
    func getMoviesForSearchString(_ searchString: String, completionHandler: @escaping (_ result: [Movie]?, _ error: String?) -> Void) -> URLSessionDataTask? {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.Query: searchString]
        
        /* 2. Make the request */
        let task = taskForGETMethod(Methods.SearchMovie, parameters: parameters as [String : AnyObject]) { dataResult in
            switch dataResult {
                case .success(let result):
                    guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                        let movieResults = dic[MVClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]]
                        else {
                            let errorString = self.getErrorString(AppError.parser(.BadData))
                            completionHandler(nil, errorString)
                            return
                    }
                    var movies: [Movie] = []
                    _ = movieResults.map({
                        let movie = Movie(dictionary: $0, context: MVClient.sharedInstance.scratchContext)
                        movies.append(movie)
                    })
                    completionHandler(movies, nil)
                
                case .failure(let error):
                    let errorString = self.getErrorString(error)
                    completionHandler(nil, errorString)
            }
        }
        return task
    }
    
    func fetchMovies(_ watched: Bool) -> [Movie] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Movie")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "watched == %@", watched as CVarArg);
        
        // Execute the Fetch Request
        do {
            return try sharedContext.fetch(fetchRequest) as! [Movie]
        } catch _ {
            return [Movie]()
        }
    }

    
    func getMovieInfo(_ movieId: Int, completionHandler: @escaping (Result<AnyObject, Error>) -> Void) {
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters: [String : AnyObject] = [: ]
        var mutableMethod : String = Methods.MovieInfo
        let movieIDString: String = "\(movieId)"
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: movieIDString)!
        _ = taskForGETMethod(mutableMethod, parameters: parameters) { dataResult in
            switch dataResult {
            case .success(let mov):
                guard let movieDictionary: [String: AnyObject] = mov as? [String: AnyObject]
                    else {
                        completionHandler(.failure(E: .parser(.BadData)))
                        return
                }
                completionHandler(.success(T: movieDictionary as AnyObject))
            case .failure:
                completionHandler(dataResult)
            }
        }
    }
    
    func postToWatchlist(_ movie: Movie, watchlist: Bool, completionHandler: @escaping (_ result: Int?, _ error: String?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID : MVClient.sharedInstance.sessionID!]
        
        var mutableMethod : String = Methods.AccountIDWatchlist
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        let jsonBody : [String:AnyObject] = [
            MVClient.JSONBodyKeys.MediaType: "movie" as AnyObject,
            MVClient.JSONBodyKeys.MediaID: movie.id as NSNumber,
            MVClient.JSONBodyKeys.Watchlist: watchlist as Bool as AnyObject
        ]
        
        /* 2. Make the request */
        _ = taskForPOSTMethod(mutableMethod, parameters: parameters as [String : AnyObject], jsonBody: jsonBody) { dataResult in
            switch dataResult {
            case .success(let res):
                guard let result = res[MVClient.JSONResponseKeys.StatusCode] as? Int
                    else {
                        let errorString = self.getErrorString(AppError.parser(.BadData))
                        completionHandler(nil, errorString)
                        return
                }
                completionHandler(result, nil)
            case .failure(let error):
                let errorString = self.getErrorString(error)
                completionHandler(nil, errorString)
            }
        }
    }
    
    
    // MARK: POST Convenience Methods
    
    func postToFavorites(_ movie: Movie, favorite: Bool, completionHandler: @escaping (_ result: Int?, _ error: String?) -> Void)  {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID : MVClient.sharedInstance.sessionID!]
        
        var mutableMethod : String = Methods.AccountIDFavorite
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        
        let jsonBody : [String:AnyObject] = [
            MVClient.JSONBodyKeys.MediaType: "movie" as AnyObject,
            MVClient.JSONBodyKeys.MediaID: movie.id as NSNumber,
            MVClient.JSONBodyKeys.Favorite: favorite as Bool as AnyObject
        ]
        
        /* 2. Make the request */
        _ = taskForPOSTMethod(mutableMethod, parameters: parameters as [String : AnyObject], jsonBody: jsonBody) { dataResult in
            switch dataResult {
            case .success(let res):
                guard let result = res[MVClient.JSONResponseKeys.StatusCode] as? Int
                    else {
                        let errorString = self.getErrorString(AppError.parser(.BadData))
                        completionHandler(nil, errorString)
                        return
                }
                completionHandler(result, nil)
            case .failure(let error):
                let errorString = self.getErrorString(error)
                completionHandler(nil, errorString)
            }
        }
    }
    
    func getErrorString(_ error: AppError) -> String {
        switch error {
        case .network(let errorString):
            return errorString
        case .parser(let errorString):
            return errorString.rawValue
        }
    }
}
