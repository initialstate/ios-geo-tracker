//
//  InitialStateApi.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/22/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import Foundation
import Alamofire

class ISApi {
    var CoreBase = "https://dev-api.initialstate.com/api/v2"
    var Corev1Base = "https://dev-api.initialstate.com/api/v1"
    var env:Env = Env.Dev
    
    enum Env {
        case Dev
        case Prod
    }
    
    init(env: Env = Env.Dev) {
        self.env = env
        switch env{
        case Env.Prod:
            self.CoreBase = "https://api.initialstate.com/api/v2"
            self.Corev1Base = "https://api.initialstate.com/api/v1"
            break
        case Env.Dev:
            self.CoreBase = "https://dev-api.initialstate.com/api/v2"
            self.Corev1Base = "https://dev-api.initialstate.com/api/v1"
            break
        }
    }
    
    class AuthenticationInfo {
        var accessToken = ""
        var accessKeyId = ""
        var apiKey = ""
        var accessKey = ""
        var userName = ""
        
        var tempAccessToken = ""
        var tempTokenPostUrl = ""
        var tempApiKey = ""
        
        func setAuth(at: String, akid: String, apik: String, un: String) {
            self.accessToken = at
            self.accessKeyId = akid
            self.apiKey = apik
            self.userName = un
        }
        func setAccessKey(ak: String) {
            self.accessKey = ak
        }
        func setTempAuth(apik: String, tat: String, url: String) {
            self.tempAccessToken = tat
            self.tempTokenPostUrl = url
            self.tempApiKey = apik
        }
    }
    
    class BucketInfo {
        var bucketKey = ""
        var bucketName = ""
    }
    
    var authenticationInfo = AuthenticationInfo()
    var bucketInfo = BucketInfo()
    
    func setAuthenticationInfo(akid: String, at: String, apik: String, un: String) {
        self.authenticationInfo.setAuth(at, akid: akid, apik: apik, un: un)
    }
    
    func setAccessKey(ak: String) {
        self.authenticationInfo.setAccessKey(ak)
    }
    
    func setBucketInfo(bn: String, bk: String) {
        self.bucketInfo.bucketKey = bk
        self.bucketInfo.bucketName = bn
    }
    
    func resetAuth() {
        self.authenticationInfo = AuthenticationInfo()
    }
    
    func resetAccessKeys() {
        self.authenticationInfo.setAccessKey("")
    }
    
    func testAuth(callback: (success: Bool) -> Void) {
        let url = "\(Corev1Base)/user_tokens"
        
        Alamofire.request(.GET, url, encoding: .JSON)
            .validate()
            .responseJSON { response in
                print("Called Url: \(response.request)")
                
                switch response.result{
                case .Success:
                    callback(success: true)
                case .Failure(_):
                    callback(success: false)
                }
        }
    }
    
    func auth(email: String, pass: String, tfa: String = "", callback: (tfaRequired: Bool, success: Bool) -> Void) {
        
        let request: [String: AnyObject] = [
            "email": email,
            "password": pass,
            "twoFactorToken": tfa
        ]
        
        let url = "\(Corev1Base)/user_tokens"
        
        Alamofire.request(.POST, url, parameters: request, encoding: .JSON)
            .responseJSON { response in
                print("Called Url: \(response.request)")
                print("request: \(request)")
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    if (response.response?.statusCode >= 200 && response.response?.statusCode < 300) {
                        let authResp = (JSON as! NSDictionary)
                        let user = (authResp["user"] as! NSDictionary)
                        
                        let uid = (user["id"] as! String)
                        let at = (authResp["accessToken"] as! String)
                        let apik = (authResp["apiKey"] as! String)
                        let username = (user["email"] as! String)
                        
                        self.authenticationInfo.setAuth(at, akid: uid, apik: apik, un: username)
                        callback(tfaRequired: false, success: true)
                    } else if (response.response?.statusCode == 401){
                        if (response.response?.allHeaderFields["X-IS-OTP"] != nil) {
                            print("2fa required")
                            
                            let authResp = (JSON as! NSDictionary)
                            let apik = (authResp["apiKey"] as! String)
                            let tempTat = (authResp["tempAccessToken"] as! String)
                            let tokenPostUrl = (authResp["tokenPostUrl"] as! String)
                            self.authenticationInfo = AuthenticationInfo()
                            self.authenticationInfo.setTempAuth(apik, tat: tempTat, url: tokenPostUrl)
                            
                            callback(tfaRequired: true, success: false)
                        } else {
                            NSLog("Error")
                            callback(tfaRequired: false, success: false)
                        }
                    }
                } else {
                    callback(tfaRequired: false, success: false)
                }
                
        }
    }
    
    func continueAuth(token: String, callback: (success: Bool) -> Void) {
        
        let url = self.authenticationInfo.tempTokenPostUrl
        
        let request: [String: AnyObject] = [
            "twoFactorToken": token,
            "tempAccessToken": self.authenticationInfo.tempAccessToken,
            "rememberMe": true
        ]
        
        Alamofire.request(.POST, url, parameters: request, encoding: .JSON)
            .responseJSON { response in
                print("Called Url: \(response.request)")
                print("request: \(request)")
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    if (response.response?.statusCode >= 200 && response.response?.statusCode < 300) {
                        let authResp = (JSON as! NSDictionary)
                        let user = (authResp["user"] as! NSDictionary)
                        
                        let uid = (user["id"] as! String)
                        let at = (authResp["accessToken"] as! String)
                        let apik = (authResp["apiKey"] as! String)
                        let username = (user["email"] as! String)
                        
                        self.authenticationInfo.setAuth(at, akid: uid, apik: apik, un: username)
                        callback(success: true)
                    } else {
                        NSLog("Error")
                        callback(success: false)
                    }
                } else {
                    callback(success: false)
                }
        }
    }
    
    func getAccessKey(callback: (success: Bool) -> Void) {
        
        let url = "\(Corev1Base)/me/access_keys?createIfEmpty=true"
        let headers = [
            "X-IS-AT": authenticationInfo.accessToken,
            "X-IS-ApiKey": authenticationInfo.apiKey,
            "X-IS-AKID": authenticationInfo.accessKeyId
        ]
        
        NSLog("\(headers)")
        
        Alamofire.request(.GET, url, headers: headers, encoding: .JSON)
            .responseJSON { response in
                if (response.response == nil) {
                    callback(success: false)
                    return
                }
                if (response.response?.statusCode >= 200 && response.response?.statusCode < 300) {
                    if let JSON = response.result.value {
                        
                        let response = (JSON as! [NSDictionary])
                        let accessKey = response[0]
                        self.authenticationInfo.setAccessKey(accessKey["key"] as! String)
                        print(accessKey)
                        
                        callback(success: true)
                    } else {
                        callback(success: false)
                    }
                } else {
                    callback(success: false)
                }
        }
    }
}