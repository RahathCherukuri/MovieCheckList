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
    
    // MARK: Helper Functions
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