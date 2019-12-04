//
//  AppDelegate.swift
//  Restaurant-Demo
//
//  Created by yomi on 2017/11/24.
//  Copyright © 2017年 yomi. All rights reserved.
//

import UIKit
import Foundation
import GooglePlaces
import GoogleMaps
import Firebase
import Fabric
import Crashlytics
import Kingfisher

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        /* Init firebase configs */
        FirebaseApp.configure()
        
        /* Init fabric configs */
        Fabric.with([Crashlytics.self])
        Fabric.sharedSDK().debug = true

        /* Init google map api configs */
        GMSPlacesClient.provideAPIKey("AIzaSyAc5wnmJJydGYodnmlc2jFPQMeAgwLeBug")
        GMSServices.provideAPIKey("AIzaSyAc5wnmJJydGYodnmlc2jFPQMeAgwLeBug")
        
        /* Init YelpApiUtil*/
        YelpApiUtil.initizlize()
        
        /* Init image cache memory/disk size*/
        ImageCache.default.maxMemoryCost = 500 * 1024
        ImageCache.default.maxDiskCacheSize = 20 * 1024 * 1024
        ImageCache.default.maxCachePeriodInSecond = 60 * 60 * 24 * 1
        
        /* Navigation bar style */
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor(displayP3Red: 216.0/255.0, green: 74.0/255.0, blue: 32.0/255.0, alpha: 1.0)
            UIToolbar.appearance().backgroundColor = UIColor(displayP3Red: 216.0/255.0, green: 74.0/255.0, blue: 32.0/255.0, alpha: 1.0)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            UINavigationBar.appearance().tintColor = .white
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().barTintColor = UIColor(displayP3Red: 216.0/255.0, green: 74.0/255.0, blue: 32.0/255.0, alpha: 1.0)
            UIToolbar.appearance().barTintColor = UIColor(displayP3Red: 216.0/255.0, green: 74.0/255.0, blue: 32.0/255.0, alpha: 1.0)
            UINavigationBar.appearance().tintColor = UIColor.white
        }
        if let barFont = UIFont(name: "Avenir-Light", size: 36.0) {
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white, NSAttributedStringKey.font:barFont]
        }
        
        // ShortcutItem
        var isLaunchedFromShortcutItem = false
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            isLaunchedFromShortcutItem = true
            handleShortcutItem(shortcutItem: shortcutItem)
        }
        
        return !isLaunchedFromShortcutItem
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        self.handleShortcutItem(shortcutItem: shortcutItem)
    }
    
    func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) {
        // TODO: Route the quick action to main page and under searching status
        guard let actionStr = shortcutItem.type.components(separatedBy: ".").last, let action = QuickAction(rawValue:actionStr) else {
            return
        }
        
        if action == QuickAction.LocationSearchRestaurant {
            if let navController = self.window?.rootViewController as? UINavigationController, let restaurantListVc = navController.viewControllers[0] as? RestaurantListViewController {
                navController.popToRootViewController(animated: false)
                restaurantListVc.receiveShortcutItemAction(shortcutItemAction: action)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

