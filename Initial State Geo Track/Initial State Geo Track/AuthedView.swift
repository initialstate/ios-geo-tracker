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
        let locationObj = locationArray.lastObject as! CLLocation
        let coordinate = locationObj.coordinate
        
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        
        print("Last location: \(coordinate.latitude), \(coordinate.longitude)")
        
        mapView.setRegion(coordinateRegion, animated: true)
        locationFixed = true
        mapView.showsUserLocation = true
        
        if (self.eventStreamer.accessKey != nil && self.startRecording) {
            let iso = NSDate.ISOStringFromDate(locationObj.timestamp)
            print(iso)
            var events = [EventDataPoint]()
            
            events.append(EventDataPoint(eventKey: "gps", value: "\(coordinate.latitude), \(coordinate.longitude)", isoDateTime: iso))
            events.append(EventDataPoint(eventKey: "speed", value: "\(locationObj.speed)", isoDateTime: iso))
            
            eventStreamer.sendData(events)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //print("Heading: \(newHeading)")
    }
}