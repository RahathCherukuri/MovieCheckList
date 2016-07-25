//
//  MVAuthViewController.swift
//  MovieCheckList
//
//  Created by Rahath cherukuri on 7/9/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class MVAuthViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var webView: UIWebView!
    
    var urlRequest: NSURLRequest? = nil
    var requestToken: String? = nil
    var completionHandler : ((success: Bool, errorString: String?) -> Void)? = nil
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        self.navigationItem.title = "TheMovieDB Auth"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(MVAuthViewController.cancelAuth))
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if urlRequest != nil {
            self.webView.loadRequest(urlRequest!)
        }
    }
    
    // MARK: Cancel Auth Flow
    
    func cancelAuth() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - TMDBAuthViewController: UIWebViewDelegate

extension MVAuthViewController: UIWebViewDelegate {
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("webView URL: ", webView.request?.URL?.absoluteString)
        if ( webView.request!.URL!.absoluteString == "\(MVClient.Constants.AuthorizationURL)\(requestToken!)/allow") {
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.completionHandler!(success: true, errorString: nil)
            })
        }
    }
    
}
