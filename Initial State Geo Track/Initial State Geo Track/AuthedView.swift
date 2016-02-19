//
//  AuthedView.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/23/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class AuthedView : UIViewController,CLLocationManagerDelegate {
    
    @IBOutlet weak var btnAuthInOut: UIButton!
    var startRecording = false
    var locationFixed:Bool!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager:CLLocationManager!
    
    @IBAction func logOut(sender: AnyObject) {
        if (self.startRecording == true) {
            self.startStopRecording(sender)
        }
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loginView: LoginView = storyboard.instantiateViewControllerWithIdentifier("loginView") as! LoginView
        self.appDelegate.resetAuth()
        self.presentViewController(loginView, animated: true, completion: nil)
    }
    @IBOutlet weak var trackingLabel: UILabel!
    
    override func viewDidLoad() {
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        btnAuthInOut.setTitle(appDelegate.apiController.authenticationInfo.userName, forState: .Normal)
        self.startStopRecordingButton.enabled = false
        self.startStopRecordingButton.setTitle("Loading...", forState: .Normal)
        self.trackingLabel.hidden = true
        
        locationFixed = false
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        appDelegate.apiController.getAccessKey { (success) -> Void in
            if (success) {
                print("successfully have access key")
                self.appDelegate.eventStreamer.accessKey = self.appDelegate.apiController.authenticationInfo.accessKey
                self.appDelegate.eventStreamer.bucketKey = "iOS GPS"
                
                NSUserDefaults.standardUserDefaults().setObject(self.appDelegate.eventStreamer.accessKey, forKey: "accessKey")
                NSUserDefaults.standardUserDefaults().setObject(self.appDelegate.eventStreamer.bucketKey, forKey: "bucketKey")
                
                self.startStopRecordingButton.enabled = true
                self.startStopRecordingButton.setTitle("Start", forState: .Normal)
                let currentBucketKey:String = self.appDelegate.eventStreamer.bucketKey!
                self.newBucketButtonOutlet.setTitle("Bucket Key: \(currentBucketKey)", forState: .Normal)
            } else {
                self.logOut(self)
            }
        }
    }
    
    @IBOutlet weak var startStopRecordingButton: UIButton!
    @IBAction func startStopRecording(sender: AnyObject) {
        if (self.startRecording == false) {
            self.startRecording = true
            appDelegate.startRecording = true
            appDelegate.manager.startUpdatingLocation()
            locationManager.startUpdatingLocation()
            startStopRecordingButton.setTitle("Stop", forState: .Normal)
            self.trackingLabel.hidden = false
            
            self.trackingLabel.alpha = 1
            
//            UIView.animateWithDuration(0.7, delay: 0.0, options: [.Repeat, .Autoreverse, .CurveEaseInOut], animations:
//                {
//                    self.trackingLabel.alpha = 0
//                }, completion: nil)
            
        } else {
            self.startRecording = false
            appDelegate.startRecording = false
            appDelegate.manager.stopUpdatingLocation()
            locationManager.stopUpdatingLocation()
            startStopRecordingButton.setTitle("Start", forState: .Normal)
            self.trackingLabel.hidden = true
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationArray = locations as NSArray
        
        let locationObj = locationArray.lastObject as! CLLocation
        let coordinate = locationObj.coordinate
        
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        print("Map Location: \(coordinate.latitude), \(coordinate.longitude)")
        
        mapView.setRegion(coordinateRegion, animated: true)
        locationFixed = true
        mapView.showsUserLocation = true
    }
    
    @IBOutlet weak var newBucketButtonOutlet: UIButton!
    @IBAction func newBucketButton(sender: AnyObject) {
        if (self.startRecording == true) {
            self.startStopRecording(sender)
        }
        
        let currentBucketKey:String = "iOS GPS (\(randomStringWithLength(5) as String as String))"
        appDelegate.eventStreamer.bucketKey = currentBucketKey
        appDelegate.eventStreamer.isBucketCreated = false
        
        self.newBucketButtonOutlet.setTitle("Bucket Key: \(currentBucketKey)", forState: .Normal)
    }
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
}