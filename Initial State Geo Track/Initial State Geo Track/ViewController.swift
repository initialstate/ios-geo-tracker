//
//  ViewController.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/22/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var apiController = ISApi()
    
    
    @IBOutlet weak var onePasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //self.onePasswordButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())
        
        emailAddress.keyboardType = UIKeyboardType.EmailAddress
        

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
        apiController.auth(emailAddress.text!, pass: password.text!) { (tfaRequired: Bool, success: Bool) -> Void in
            
            if (!success) {
                if (tfaRequired) {
                    print("tfa required")
                } else {
                    print("finished")
                }
            } else {
                print("successful auth")
                
                let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                let loggedInView: AuthedView = storyboard.instantiateViewControllerWithIdentifier("authView") as! AuthedView
                loggedInView.apiController = self.apiController
                self.presentViewController(loggedInView, animated: true, completion: nil)
            }
        }
    }
}

