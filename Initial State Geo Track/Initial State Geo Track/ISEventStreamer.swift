//
//  ISEventStreamer.swift
//  Initial State Geo Track
//
//  Created by David Sulpy on 1/26/16.
//  Copyright © 2016 Initial State Technologies, Inc. All rights reserved.
//

import Foundation
import Alamofire

class ISEventStreamer {
    
    var bucketKey:String? = nil
    var accessKey:String? = nil
    var isBucketCreated:Bool = false
    let BaseUrl = "https://groker-dev.initialstate.com/api"
    
    func sendData(eventArray: [EventDataPoint]) {
        
        if (false == isBucketCreated) {
            createBucket(self.bucketKey, callback: { (bucketResult) -> Void in
                print(bucketResult)
            })
        }
        
        let url = "\(BaseUrl)/events"
        let headers = ["X-IS-AccessKey": self.accessKey!, "X-IS-BucketKey": self.bucketKey!]
        
        var requestData: [[String: AnyObject]] = []
        
        for x in eventArray {
            requestData.append([
                "key": x.eventKey,
                "value": x.value,
                "iso8601": x.isoDateTime
                ])
        }
        
        let requestBody: [String: AnyObject] = [
            "events": requestData
        ]
        
        Alamofire.request(.POST, url, parameters: requestBody, headers: headers, encoding: .JSON)
            .responseJSON{ response in
                print("Called Url: \(response.request)")
                print("request: \(requestBody)")
                
                
                
        }
        
    }
    
    func createBucket(bucketKey: String?, callback: (bucketResult: BucketResult?) -> Void) {
        if (bucketKey != nil) {
            self.bucketKey = bucketKey
        } else {
            self.bucketKey = "iOS GPS"
        }
        
        let url = "\(BaseUrl)/buckets"
        
        let request: [String: AnyObject] = [
            "bucketName": self.bucketKey!,
            "bucketKey": self.bucketKey!
        ]
        
        let headers = ["X-IS-AccessKey": self.accessKey!]
        
        Alamofire.request(.POST, url, parameters: request, headers: headers, encoding: .JSON)
        .responseJSON{ response in
            print("Called Url: \(response.request)")
            print("request: \(request)")
        
            if (response.response?.statusCode >= 200 && response.response?.statusCode < 300){
                if (response.response?.statusCode == 201) {
                    print("successfully created bucket")
                    
                } else if (response.response?.statusCode == 204) {
                    print("bucket already created")
                    
                }
                self.isBucketCreated = true
                
                let bucketResult = BucketResult()
                bucketResult.set(self.bucketKey!, bn: self.bucketKey!)
                callback(bucketResult: bucketResult)
            } else {
                if (response.response?.statusCode == 401) {
                    print("access key invalud")
                    callback(bucketResult: nil)
                } else if (response.response?.statusCode == 402) {
                    print("payment required")
                    callback(bucketResult: nil)
                } else if (response.response?.statusCode == 429) {
                    print("too many requests")
                    callback(bucketResult: nil)
                }
            }
            
        }
    }
    
}


class BucketResult : NSCoder {
    var bucketKey: String = ""
    var bucketName: String = ""
    
    override init() {}
    
    required init(coder aDecoder: NSCoder) {
        self.bucketKey = aDecoder.decodeObjectForKey("bucketKey") as! String
        self.bucketName = aDecoder.decodeObjectForKey("bucketName") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(bucketKey, forKey: "bucketKey")
        aCoder.encodeObject(bucketName, forKey: "bucketName")
    }
    
    func set(bk: String, bn: String) {
        bucketKey = bk
        bucketName = bn
    }
}