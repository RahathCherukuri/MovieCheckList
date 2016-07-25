//
//  MVConvenience.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 6/28/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation
import UIKit

extension MVClient {
    
    func authenticateWithViewController(hostViewController: UIViewController, completionHandler: (success: Bool, errorString: String?) -> Void) {
        self.getRequestToken() { dataResult in
            switch dataResult {
            case .Success(let requestToken):
                print("requestToken: \(requestToken)")
                self.loginWithToken(requestToken as? String, hostViewController: hostViewController) {(success, errorString) in
                    if success {
                        print("success")
                        self.getSessionID((requestToken as? String)!) { dataResult in
                            switch dataResult {
                            case .Success(let sessionID):
                                self.sessionID = sessionID as? String
                                print("sessionID: \(self.sessionID)")
                                self.getUserID(self.sessionID!) { dataResult in
                                    switch dataResult {
                                    case .Success(let id):
                                        self.userID = id as? Int
                                        print("UserID: \(self.userID)")
                                        completionHandler(success: true, errorString: nil)
                                    case .Failure(let error):
                                        completionHandler(success: false, errorString: self.getErrorString(error))
                                    }
                                }
                            case .Failure(let error):
                                completionHandler(success: false, errorString: self.getErrorString(error))
                            }
                        }
                    } else {
                        completionHandler(success: false, errorString: errorString)
                    }
                }
            case .Failure(let error):
                completionHandler(success: false, errorString: self.getErrorString(error))
            }
        }
    }
    
    // Gets the RequestToken
    func getRequestToken(completionHandler: Result<AnyObject, Error> -> Void) {
        let method = Methods.AuthenticationTokenNew
        let parameters: [String : AnyObject] = [ : ]
        
        taskForGETMethod(method, parameters: parameters) { dataResult in
            switch dataResult {
            case .Success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    requestToken = dic[MVClient.JSONResponseKeys.RequestToken] as? String
                else {
                    completionHandler(.Failure(.Parser(.BadData)))
                    return
                }
                completionHandler(.Success(requestToken))
            case .Failure:
                completionHandler(dataResult)
            }
        }
    }
    
    /* This function opens a MVAuthViewController to handle Step 2a of the auth flow */
    func loginWithToken(requestToken: String?, hostViewController: UIViewController, completionHandler: (success: Bool, errorString: String?) -> Void) {
        let authorizationURL = NSURL(string: "\(MVClient.Constants.AuthorizationURL)\(requestToken!)")
        let request = NSURLRequest(URL: authorizationURL!)
        
        let webAuthViewController = hostViewController.storyboard!.instantiateViewControllerWithIdentifier("MVAuthViewController") as! MVAuthViewController
        webAuthViewController.urlRequest = request
        webAuthViewController.requestToken = requestToken
        webAuthViewController.completionHandler = completionHandler
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)
        
        dispatch_async(dispatch_get_main_queue(), {
            hostViewController.presentViewController(webAuthNavigationController, animated: true, completion: nil)
        })
    }
    
    // Gets the sessionID
    func getSessionID(requestToken: String, completionHandler: Result<AnyObject, Error> -> Void) {
        let method: String = Methods.AuthenticationSessionNew
        let parameters: [String : AnyObject] = [ParameterKeys.RequestToken: requestToken]
        
        taskForGETMethod(method, parameters: parameters) { dataResult in
            switch dataResult {
            case .Success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    sessionID = dic[MVClient.JSONResponseKeys.SessionID] as? String
                    else {
                        completionHandler(.Failure(.Parser(.BadData)))
                        return
                }
                completionHandler(.Success(sessionID))
            case .Failure:
                completionHandler(dataResult)
            }
        }
    }
    
    //Gets the UserID
    func getUserID(session_id: String, completionHandler: Result<AnyObject, Error> -> Void) {
        let method: String = Methods.Account
        let parameters: [String: AnyObject] = [ParameterKeys.SessionID:session_id]
        
        taskForGETMethod(method, parameters: parameters) { dataResult in
            switch dataResult {
            case .Success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    userID = dic[MVClient.JSONResponseKeys.UserID] as? Int
                    else {
                        completionHandler(.Failure(.Parser(.BadData)))
                        return
                }
                completionHandler(.Success(userID))
            case .Failure:
                completionHandler(dataResult)
            }
        }
    }
    
    
    //Get the watchlist, iterate through the list and get each movie information
    func getWatchlistMovies(completionHandler: (success: Bool, errorString: String?, movies: [Movie]?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID: MVClient.sharedInstance.sessionID!]
        var mutableMethod : String = Methods.AccountIDWatchlistMovies
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!

        taskForGETMethod(mutableMethod, parameters: parameters) {dataResult in
            switch dataResult {
            case .Success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                watchMovieResults = dic[MVClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]]
                else {
                        let errorString = self.getErrorString(Error.Parser(.BadData))
                    completionHandler(success: false, errorString: errorString, movies: nil)
                        return
                }
                
                let countBeforeAppending: Int = MVClient.sharedInstance.allMovies.count
                _ = watchMovieResults.map({
                    guard let id = $0[MVClient.JSONResponseKeys.UserID] as? Int else {
                        return
                    }
                    self.getMovieInfo(id) {dataResult in
                        switch dataResult {
                        case .Success(let mov):
                            var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                            movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = false
                            let movie = Movie(dictionary: movieDictionary)
                            MVClient.sharedInstance.allMovies.append(movie)
                            let countAfterAppending = MVClient.sharedInstance.allMovies.count
                            if ((countAfterAppending - countBeforeAppending) == watchMovieResults.count) {
                                let watchListMovies:[Movie] = self.getToWatchMoviesList()
                                completionHandler(success: true, errorString: nil, movies: watchListMovies)
                            }
                        case .Failure(let error):
                            let errorString = self.getErrorString(error)
                            completionHandler(success: false, errorString: errorString, movies: nil)
                        }
                    }
                })
            case .Failure(let error):
                let errorString = self.getErrorString(error)
                completionHandler(success: false, errorString: errorString, movies: nil)
            }
        }
    }
    
    //Get the FavouriteList, iterate through the list and get each movie information
    func getFavoriteMovies(completionHandler: (success: Bool, errorString: String?, movies: [Movie]?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID: MVClient.sharedInstance.sessionID!]
        var mutableMethod : String = Methods.AccountIDFavoriteMovies
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        
        /* 2. Make the request */
        taskForGETMethod(mutableMethod, parameters: parameters) { dataresult in
            switch dataresult {
            case .Success(let result):
                guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                    watchMovieResults = dic[MVClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]]
                    else {
                        let errorString = self.getErrorString(Error.Parser(.BadData))
                        completionHandler(success: false, errorString: errorString, movies: nil)
                        return
                }
                let countBeforeAppending: Int = MVClient.sharedInstance.allMovies.count
                
                _ = watchMovieResults.map({
                    guard let id = $0[MVClient.JSONResponseKeys.UserID] as? Int else {
                        return
                    }
                    self.getMovieInfo(id) {dataResult in
                        switch dataResult {
                        case .Success(let mov):
                            var movieDictionary: [String: AnyObject] = mov as! [String : AnyObject]
                            movieDictionary[MVClient.JSONResponseKeys.MovieWatched] = true
                            let movie = Movie(dictionary: movieDictionary)
                            MVClient.sharedInstance.allMovies.append(movie)
                            let countAfterAppending = MVClient.sharedInstance.allMovies.count
                            if ((countAfterAppending - countBeforeAppending) == watchMovieResults.count) {
                                let watchedMovies:[Movie] = self.getWatchedMoviesList()
                                completionHandler(success: true, errorString: nil, movies: watchedMovies)
                            }
                        case .Failure(let error):
                            let errorString = self.getErrorString(error)
                            completionHandler(success: false, errorString: errorString, movies: nil)
                        }
                    }
                })
            case .Failure(let error):
                let errorString = self.getErrorString(error)
                completionHandler(success: false, errorString: errorString, movies: nil)
            }
        }
    }
    
    // Get movies with the search string
    func getMoviesForSearchString(searchString: String, completionHandler: (result: [Movie]?, error: String?) -> Void) -> NSURLSessionDataTask? {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.Query: searchString]
        
        /* 2. Make the request */
        let task = taskForGETMethod(Methods.SearchMovie, parameters: parameters) { dataResult in
            switch dataResult {
                case .Success(let result):
                    guard let dic: [String: AnyObject] = result as? [String: AnyObject],
                        movieResults = dic[MVClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]]
                        else {
                            let errorString = self.getErrorString(Error.Parser(.BadData))
                            completionHandler(result: nil, error: errorString)
                            return
                    }
                    var movies: [Movie] = []
                    _ = movieResults.map({
                        let movie = Movie(dictionary: $0)
                        movies.append(movie)
                    })
                    completionHandler(result: movies, error: nil)
                
                case .Failure(let error):
                    let errorString = self.getErrorString(error)
                    completionHandler(result: nil, error: errorString)
            }
        }
        return task
    }
    
    func getToWatchMoviesList()-> [Movie] {
        
        let watchListMovies = MVClient.sharedInstance.allMovies.filter({
            $0.watched! == false
        })
        return watchListMovies
    }
    
    func getWatchedMoviesList()-> [Movie] {
        let watchedMovies = MVClient.sharedInstance.allMovies.filter({
            $0.watched! == true
        })
        return watchedMovies
    }
    
//    https://api.themoviedb.org/3/movie/256924?api_key=260bdeaf6536281935bb16ea222e85ff
    func getMovieInfo(movieId: Int, completionHandler: Result<AnyObject, Error> -> Void) {
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters: [String : AnyObject] = [: ]
        var mutableMethod : String = Methods.MovieInfo
        let movieIDString: String = "\(movieId)"
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: movieIDString)!
        taskForGETMethod(mutableMethod, parameters: parameters) { dataResult in
            switch dataResult {
            case .Success(let mov):
                guard let movieDictionary: [String: AnyObject] = mov as? [String: AnyObject]
                    else {
                        completionHandler(.Failure(.Parser(.BadData)))
                        return
                }
                completionHandler(.Success(movieDictionary))
            case .Failure:
                completionHandler(dataResult)
            }
        }
    }
    
    //http://api.themoviedb.org/3/movie/256924/credits?api_key=260bdeaf6536281935bb16ea222e85ff
    func getMovieCredits() {
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters: [String : AnyObject] = [: ]
        let movieid: String = "256924"
        var mutableMethod : String = Methods.MovieCredits
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: movieid)!
        
        taskForGETMethod(mutableMethod, parameters: parameters) { dataResult in
            print(dataResult)
        }

    }
    
    func postToWatchlist(movie: Movie, watchlist: Bool, completionHandler: (result: Int?, error: String?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID : MVClient.sharedInstance.sessionID!]
        
        var mutableMethod : String = Methods.AccountIDWatchlist
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        let jsonBody : [String:AnyObject] = [
            MVClient.JSONBodyKeys.MediaType: "movie",
            MVClient.JSONBodyKeys.MediaID: movie.id as Int,
            MVClient.JSONBodyKeys.Watchlist: watchlist as Bool
        ]
        
        /* 2. Make the request */
        taskForPOSTMethod(mutableMethod, parameters: parameters, jsonBody: jsonBody) { dataResult in
            switch dataResult {
            case .Success(let res):
                guard let result = res[MVClient.JSONResponseKeys.StatusCode] as? Int
                    else {
                        let errorString = self.getErrorString(Error.Parser(.BadData))
                        completionHandler(result: nil, error: errorString)
                        return
                }
                completionHandler(result: result, error: nil)
            case .Failure:
                let errorString = self.getErrorString(Error.Parser(.BadData))
                completionHandler(result: nil, error: errorString)
            }
        }
    }
    
    
    // MARK: POST Convenience Methods
    
    func postToFavorites(movie: Movie, favorite: Bool, completionHandler: (result: Int?, error: String?) -> Void)  {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [MVClient.ParameterKeys.SessionID : MVClient.sharedInstance.sessionID!]
        
        var mutableMethod : String = Methods.AccountIDFavorite
        mutableMethod = MVClient.substituteKeyInMethod(mutableMethod, key: MVClient.URLKeys.UserID, value: String(MVClient.sharedInstance.userID!))!
        
        let jsonBody : [String:AnyObject] = [
            MVClient.JSONBodyKeys.MediaType: "movie",
            MVClient.JSONBodyKeys.MediaID: movie.id as Int,
            MVClient.JSONBodyKeys.Favorite: favorite as Bool
        ]
        
        /* 2. Make the request */
        taskForPOSTMethod(mutableMethod, parameters: parameters, jsonBody: jsonBody) { dataResult in
            switch dataResult {
            case .Success(let res):
                guard let result = res[MVClient.JSONResponseKeys.StatusCode] as? Int
                    else {
                        let errorString = self.getErrorString(Error.Parser(.BadData))
                        completionHandler(result: nil, error: errorString)
                        return
                }
                completionHandler(result: result, error: nil)
            case .Failure:
                let errorString = self.getErrorString(Error.Parser(.BadData))
                completionHandler(result: nil, error: errorString)
            }
        }
    }

    
    // MARK: Helper Functions
    
//    func convertResultObject(result: Result<AnyObject, Error>) -> (success: Bool, errorString: String) {
//        switch result {
//        case .Failure(let error):
//            switch error {
//                case .Network(let errorString):
//                    return (success: false, errorString: errorString)
//                case .Parser(let errorString):
//                    return (success: false, errorString: errorString.rawValue)
//            }
//        case .Success(<#T##T#>)
//        }
//    }
    
    func getErrorString(error: Error) -> String {
        switch error {
        case .Network(let errorString):
            return errorString
        case .Parser(let errorString):
            return errorString.rawValue
        }
    }
    
    
    
    
//    // MARK: Helper Functions
//    func getErrorSString(result: Result<AnyObject, Error>, completionHandler: (success: Bool, errorString: String?) -> Void) {
//        switch result {
//        case .Failure(let error):
//            switch error {
//                case .Network(let errorString):
//                    completionHandler(success: false, errorString: errorString)
//                case .Parser(let errorString):
//                    completionHandler(success: false, errorString: errorString.rawValue)
//            }
//        default:
//            return completionHandler(success: false, errorString: "Bad Data")
//        }
//    }

}