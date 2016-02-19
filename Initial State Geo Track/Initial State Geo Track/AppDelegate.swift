//
//  AppDelegate.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/22/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Locksmith
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var manager:CLLocationManager!
    var apiController = ISApi(env: ISApi.Env.Dev)
    var eventStreamer = ISEventStreamer(env: ISEventStreamer.Env.Dev)
    var startRecording = false
    var coordinateRegion:MKCoordinateRegion!
    
    var authenticationInfo:[String:AnyObject]! = nil

    func resetAuth(){
        self.apiController.resetAccessKeys()
        self.apiController.resetAuth()
        self.eventStreamer.accessKey = ""
        
        do {
            try Locksmith.deleteDataForUserAccount("initialstate")
        } catch {
            print("failed to delete auth data from keychain")
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        Fabric.with([Crashlytics.self])
        
        let authInfo = Locksmith.loadDataForUserAccount("initialstate")
        if (authInfo != nil) {
            self.apiController.setAuthenticationInfo(authInfo!["accessKeyId"] as! String, at: authInfo!["accessToken"] as! String, apik: authInfo!["apiKey"] as! String, un: authInfo!["username"] as! String)
            self.eventStreamer.accessKey = authInfo!["accessKey"] as? String
            self.authenticationInfo = authInfo
        }
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        
        if (self.authenticationInfo != nil) {
            let authedViewController = storyboard.instantiateViewControllerWithIdentifier("authedView") as! AuthedView
            
            self.window?.rootViewController = authedViewController
            self.window?.makeKeyAndVisible()
        }
        else {
            let loginViewController = storyboard.instantiateViewControllerWithIdentifier("loginView") as! LoginView
            self.window?.rootViewController = loginViewController
            self.window?.makeKeyAndVisible()
        }
        
        IQKeyboardManager.sharedManager().enable = true
                
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = false
        
        return true
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
                
                //gps
                events.append(EventDataPoint(eventKey: "gps", value: "\(locationObj.coordinate.latitude), \(locationObj.coordinate.longitude)", isoDateTime: iso))
                
                //speed
                var speed:Double = 0
                if (locationObj.speed > 0) {
                    speed = locationObj.speed
                    speed = speed * 2.236936
                }
                events.append(EventDataPoint(eventKey: "speed (mph)", value: "\(speed)", isoDateTime: iso))
                
                //altidue
                var altitude:Double = 0
                if (locationObj.altitude > 0) {
                    altitude = locationObj.altitude
                }
                events.append(EventDataPoint(eventKey: "altitude (meters)", value: "\(altitude)", isoDateTime: iso))
                
                //floor
                if (locationObj.floor != nil) {
                    let floor = locationObj.floor!.level
                    events.append(EventDataPoint(eventKey: "floor", value: "\(floor)", isoDateTime: iso))
                }
                
                //course
                if (locationObj.course != -1) {
                    let course:Double = locationObj.course
                    events.append(EventDataPoint(eventKey: "course (deg)", value: "\(course)", isoDateTime: iso))
                }
                
                eventStreamer.sendData(events)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //print("Heading: \(newHeading)")
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        print("in background")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        print("in foreground")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

