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
    var apiController:ISApi!
    
    var eventStreamer = ISEventStreamer()
    var startRecording = false
    var locationFixed:Bool!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var manager:CLLocationManager!
    
    @IBAction func logOut(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loginView: ViewController = storyboard.instantiateViewControllerWithIdentifier("logIn") as! ViewController
        self.apiController.resetAccessKeys()
        self.apiController.resetAuth()
        loginView.apiController = self.apiController
        self.presentViewController(loginView, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        btnAuthInOut.setTitle(apiController.authenticationInfo.userName, forState: .Normal)
        self.startStopRecordingButton.enabled = false
        self.startStopRecordingButton.setTitle("Loading...", forState: .Normal)
        
        manager = CLLocationManager()
        manager.delegate = self
        locationFixed = false
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        
        apiController.getAccessKey { (success) -> Void in
            if (success) {
                print("successfully have access key")
                self.eventStreamer.accessKey = self.apiController.authenticationInfo.accessKey
                self.eventStreamer.bucketKey = "iOS GPS"
                
                NSUserDefaults.standardUserDefaults().setObject(self.eventStreamer.accessKey, forKey: "accessKey")
                NSUserDefaults.standardUserDefaults().setObject(self.eventStreamer.bucketKey, forKey: "bucketKey")
                
                self.startStopRecordingButton.enabled = true
                self.startStopRecordingButton.setTitle("Start", forState: .Normal)
            } else {
                self.logOut(self)
            }
        }
    }
    
    @IBOutlet weak var startStopRecordingButton: UIButton!
    @IBAction func startStopRecording(sender: AnyObject) {
        if (self.startRecording == false) {
            self.startRecording = true
            manager.startUpdatingLocation()
            startStopRecordingButton.setTitle("Stop", forState: .Normal)
        } else {
            self.startRecording = false
            manager.stopUpdatingLocation()
            startStopRecordingButton.setTitle("Start", forState: .Normal)
        }
    }
    
    
    @IBAction func newBucketButton(sender: AnyObject) {
        if (self.startRecording == true) {
            self.startStopRecording(sender)
        }
        
        self.eventStreamer.bucketKey = "iOS GPS (\(randomStringWithLength(5) as String as String))"
        self.eventStreamer.isBucketCreated = false
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
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status{
        case CLAuthorizationStatus.Restricted:
            print("location status: restricted")
        case CLAuthorizationStatus.Denied:
            print("location status: denied")
        case CLAuthorizationStatus.NotDetermined:
            print("location status: not determined")
        default:
            shouldIAllow = true
        }
        
        if (shouldIAllow == true) {
            print("location allowed")
        } else {
            print("location denied")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("Locations: \(locations)")
        
        let locationArray = locations as NSArray
        
        for location in locationArray {
            let locationObj = location as! CLLocation
            
            if (self.eventStreamer.accessKey != nil && self.startRecording) {
                let iso = NSDate.ISOStringFromDate(locationObj.timestamp)
                print(iso)
                var events = [EventDataPoint]()
                
                events.append(EventDataPoint(eventKey: "gps", value: "\(locationObj.coordinate.latitude), \(locationObj.coordinate.longitude)", isoDateTime: iso))
                events.append(EventDataPoint(eventKey: "speed", value: "\(locationObj.speed)", isoDateTime: iso))
                
                eventStreamer.sendData(events)
            }
        }
        
        let locationObj = locationArray.lastObject as! CLLocation
        let coordinate = locationObj.coordinate
        
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        
        print("Last location: \(coordinate.latitude), \(coordinate.longitude)")
        
        mapView.setRegion(coordinateRegion, animated: true)
        locationFixed = true
        mapView.showsUserLocation = true
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //print("Heading: \(newHeading)")
    }
}