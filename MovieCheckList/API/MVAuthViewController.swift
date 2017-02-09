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
    
    var urlRequest: URLRequest? = nil
    var requestToken: String? = nil
    var completionHandler : ((_ success: Bool, _ errorString: String?) -> Void)? = nil
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        navigationItem.title = "TheMovieDB Auth"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(MVAuthViewController.cancelAuth))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if urlRequest != nil {
            self.webView.loadRequest(urlRequest!)
        }
    }
    
    // MARK: Cancel Auth Flow
    
    func cancelAuth() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TMDBAuthViewController: UIWebViewDelegate

extension MVAuthViewController: UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("webView URL: ", webView.request?.url?.absoluteString)
        if ( webView.request!.url!.absoluteString == "\(MVClient.Constants.AuthorizationURL)\(requestToken!)/allow") {
            self.dismiss(animated: true, completion: { () -> Void in
                self.completionHandler!(true, nil)
            })
        }
    }
    
}
