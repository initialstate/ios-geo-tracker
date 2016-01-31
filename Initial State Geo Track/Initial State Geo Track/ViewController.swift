//
//  ViewController.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/22/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var onePasswordButton: UIButton!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //self.onePasswordButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())
        
        emailAddress.keyboardType = UIKeyboardType.EmailAddress
        
        if let accessKeyId = NSUserDefaults.standardUserDefaults().objectForKey("accessKeyId") as? NSString {
            if let accessToken = NSUserDefaults.standardUserDefaults().objectForKey("accessToken") as? NSString {
                if let apiKey = NSUserDefaults.standardUserDefaults().objectForKey("apiKey") as? NSString {
                    if let username = NSUserDefaults.standardUserDefaults().objectForKey("username") as? NSString {
                        self.appDelegate.apiController.setAuthenticationInfo(accessKeyId as String, at: accessToken as String, apik: apiKey as String, un: username as String)
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBAction func clearEmail(sender: AnyObject) {
        emailAddress.text = "";
    }
    @IBAction func clearPassword(sender: AnyObject) {
        password.text = "";
        password.secureTextEntry = true
    }
    
    
    @IBAction func findLoginFrom1Password(sender: AnyObject) {
        OnePasswordExtension.sharedExtension().findLoginForURLString("https://dev.initialstate.com", forViewController: self, sender: sender, completion: {
            (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
                    print("Error invoking 1Password App Extension: \(error)")
                }
                return
            }
            
            self.emailAddress.text = loginDictionary?[AppExtensionUsernameKey] as? String
            self.password.secureTextEntry = true
            self.password.text = loginDictionary?[AppExtensionPasswordKey] as? String
            
            self.loginAction(sender)
        })
    }
    
    @IBAction func loginAction(sender: AnyObject) {
        self.appDelegate.apiController.auth(emailAddress.text!, pass: password.text!) { (tfaRequired: Bool, success: Bool) -> Void in
            
            if (!success) {
                if (tfaRequired) {
                    let alertController = UIAlertController(title: "Initial State", message: "Initial State Multi Factor Token", preferredStyle: .Alert)
                    
                    let loginAction = UIAlertAction(title: "Continue", style: .Default) { (_) in
                        let twoFactorToken = alertController.textFields![0] as UITextField
                        
                        self.appDelegate.apiController.continueAuth(twoFactorToken.text!, callback: {
                            (success) -> Void in
                            if (success) {
                                self.successfulAuth()
                            } else {
                                self.clearEmail(sender)
                                self.clearPassword(sender)
                            }
                        })
                    }
                    
                    alertController.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                        textField.placeholder = "<2fa token>"
                        textField.keyboardType = UIKeyboardType.NumberPad
                    })
                    
                    alertController.addAction(loginAction)
                    
                    self.presentViewController(alertController, animated: true, completion: { () -> Void in
                        print("displayed")
                    })
                } else {
                    print("finished")
                }
            } else {
                self.successfulAuth()
            }
        }
    }
    
    func successfulAuth(){
        print("successful auth")
        
        NSUserDefaults.standardUserDefaults().setObject(self.appDelegate.apiController.authenticationInfo.accessToken, forKey: "accessToken")
        NSUserDefaults.standardUserDefaults().setObject(self.appDelegate.apiController.authenticationInfo.apiKey, forKey: "apiKey")
        NSUserDefaults.standardUserDefaults().setObject(self.appDelegate.apiController.authenticationInfo.accessKeyId, forKey: "accessKeyId")
        NSUserDefaults.standardUserDefaults().setObject(self.appDelegate.apiController.authenticationInfo.userName, forKey: "username")
        
        NSUserDefaults.standardUserDefaults().synchronize()
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loggedInView: AuthedView = storyboard.instantiateViewControllerWithIdentifier("authView") as! AuthedView
        self.presentViewController(loggedInView, animated: true, completion: nil)
    }
}

