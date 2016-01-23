//
//  AuthedView.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/23/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import UIKit


class AuthedView : UIViewController {
    
    @IBOutlet weak var btnAuthInOut: UIButton!
    var apiController:ISApi!
    
    override func viewDidLoad() {
        btnAuthInOut.setTitle(apiController.authenticationInfo.userName, forState: .Normal)
    }
    
}