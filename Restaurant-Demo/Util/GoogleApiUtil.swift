//
//  GoogleApiUtil.swift
//  Restaurant-Demo
//
//  Created by yomi on 2017/12/5.
//  Copyright © 2017年 yomi. All rights reserved.
//

import Foundation

class GoogleApiUtil {
    
    private static let GOOGLE_MAP_API_URL:String = "https://maps.googleapis.com/maps/api";
    private static let GOOGLE_STATIC_MAP:String = "\(GOOGLE_MAP_API_URL)/staticmap";
    
    public static func createStaticMapUrl(lat:Double, lng:Double, w:Int, h:Int) -> String {
        let centerLatLngStr = String.init(format: "%f,%f", lat, lng)
        return "\(GOOGLE_STATIC_MAP)?center=\(centerLatLngStr)&&markers=color:red%7Clabel:S%7C\(centerLatLngStr)&size=\(w)x\(h)&scale=2&zoom=16&language=zh-TW&key=AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ";
    }
}
