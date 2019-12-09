//
//  RestaurantListPresenter.swift
//  Restaurant-Demo
//
//  Created by yomi on 2018/3/1.
//  Copyright © 2018年 yomi. All rights reserved.
//

import UIKit
import CoreLocation
import GooglePlaces
import GooglePlacePicker

class RestaurantListPresenter: NSObject, RestaurantListPresenterProtocol, LocationStatusDelegate, ApiCallback, GMSPlacePickerViewControllerDelegate {
    
    private static let API_TAG_REQUEST_TOKEN = "API_TAG_REQUEST_TOKEN"
    private static let API_TAG_BUSINESS_SEARCH = "API_TAG_BUSINESS_SEARCH"
    
    private var mModel:RestaurantListModel?
    private var mView:RestaurantListViewProtocol?
    
    private var mJsonDecoder:JSONDecoder?
    private var mCurLocation:CLLocation?
    private var mSearchKeyword:String?
    private var mIsFirst = true
//    private var mIsNeedReFetch = false
    private var mShortcutItemAction:QuickAction?
    
    // MARK: - LocationStatusDelegate
    func isLocationAuthorized(isAuthorized: Bool) {
        guard isAuthorized else {
            // Use the taipei station as default location
            fetchRestaurantSummaryInfos()
            return
        }
        
        LocationManager.shared.requestLocationUpdate()
    }
    
    func didUpdateLocation(location: CLLocation) {
        self.mCurLocation = location
        LocationManager.shared.setDelegate(delegate: nil)
        LocationManager.shared.stopLocationUpdate()
        
        print("[Randy] didUpdateLocation")
        if self.mShortcutItemAction != nil {
            self.mShortcutItemAction = nil
            self.onLocationFloatItemClick()
        } else {
            fetchRestaurantSummaryInfos()
        }
    }
    
    // MARK:- GMSPlacePickerViewControllerDelegate
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        // To receive the results from the place picker 'self' will need to conform to
        // GMSPlacePickerViewControllerDelegate and implement this code.
        // Dismiss the place picker, as it cannot dismiss itself.
        self.mView?.doDismiss(animated: true, completion: nil)
        
        self.mCurLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
//        self.mIsNeedReFetch = true
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        self.mView?.doDismiss(animated: true, completion: nil)
    }
    
    // MARK:- fetchRestaurantSummaryInfos
    func fetchRestaurantSummaryInfos(isNeedShowLoading:Bool = true) {
        if isNeedShowLoading {
            self.mView?.showLoading(loadingContent: NSLocalizedString("Loading Data...", comment: ""))
        }
        
        let filterConfigs = self.mModel?.getFilterConfig()
        
        YelpApiUtil.businessSearch(apiTag: RestaurantListPresenter.API_TAG_BUSINESS_SEARCH
            , term: "Restaurants"
            , lat: (self.mCurLocation?.coordinate.latitude)!
            , lng: (self.mCurLocation?.coordinate.longitude)!
            , locale: YelpUtil.getPreferedLanguage()
            , openAt: (filterConfigs != nil && filterConfigs?.mOpenAt != nil) ? filterConfigs?.mOpenAt : nil
            , sortBy: (filterConfigs != nil && filterConfigs?.mSortingRule != nil) ? filterConfigs?.mSortingRule : nil
            , price: (filterConfigs != nil && filterConfigs?.mPrice != nil) ? filterConfigs?.mPrice : nil
            , callback: self)
    }
    
    // MARK:- ApiCallback
    func onError(apiTag:String, errorMsg:String) {
        self.mView?.closeLoading()
    }
    func onSuccess(apiTag:String, jsonData:Data?) {
        if apiTag == RestaurantListPresenter.API_TAG_REQUEST_TOKEN {
            LocationManager.shared.requestLocationUpdate()
        } else if apiTag == RestaurantListPresenter.API_TAG_BUSINESS_SEARCH {
            if let searchInfo = try?self.mJsonDecoder?.decode(YelpSearchInfo.self, from: jsonData!) {                
                // Compose the categories string
                for i in stride(from: 0, to: (searchInfo?.businesses?.count) ?? 0, by: 1) {
                    var categoriyTitles:[String] = [String]()
                    
                    for categoryInfo in (searchInfo?.businesses![i].categories!)! {
                        categoriyTitles.append(categoryInfo.title ?? "")
                    }
                    searchInfo?.businesses![i].categoriesStr = categoriyTitles.joined(separator: ",")
                }
                self.mModel?.setRestaurantSummaryInfos(summaryInfos: searchInfo?.businesses ?? [YelpRestaruantSummaryInfo]())
                self.mView?.refreshList(restaurantSummaryInfos: self.mModel?.getRestaurantSummaryInfos(keyword: ""))
            }
            self.mView?.closeLoading()
        }
    }
    
    
    // MARK:- RestaurantListPresenterProtocol
    
    func attachView(view:RestaurantListViewProtocol) {
        self.mView = view
    }
    
    func onViewDidLoad() {}
    
    func onViewDidAppear() {
        // Only the first time need to fetch data from API
        if self.mIsFirst {
            self.mIsFirst = false
            initConfig()
        }
//        else if self.mIsNeedReFetch {
//            self.mIsNeedReFetch = false
//            fetchRestaurantSummaryInfos()
//        }
    }
    
    func onViewDidDisappear() {}
    
    func initConfig() {
        self.mJsonDecoder = Util.getJsonDecoder()
        self.mJsonDecoder?.dateDecodingStrategy = .iso8601
        self.mModel = RestaurantListModel()
        self.mCurLocation = CLLocation(latitude: 25.047908, longitude: 121.517315)
        
        self.mView?.refreshFilterTagList(filterConfigs: self.mModel?.getFilterConfig())
        LocationManager.shared.setDelegate(delegate: self)
        LocationManager.shared.requestLocationUpdate()
    }
    
    func onSearchKeyworkChange(keyword: String?) {
        self.mSearchKeyword = keyword
        self.mView?.refreshList(restaurantSummaryInfos: self.mModel?.getRestaurantSummaryInfos(keyword: keyword))
    }
    
    func onHandleShortcutItemAction(shortcutItemAction: QuickAction?) {
        guard let action = shortcutItemAction else {
            return
        }
        
        self.mShortcutItemAction = action
        
        if action == QuickAction.LocationSearchRestaurant {
            LocationManager.shared.setDelegate(delegate: self)
            LocationManager.shared.requestLocationUpdate()
        } else {
            NSLog("[Randy] QuickAction.SearchRestaurant is not handled")
        }
    }
    
    func onFilterTagTap(tagType:TagType) {
        self.mModel?.clearFilterConfig(filterType: tagType)
        self.mView?.refreshFilterTagList(filterConfigs: self.mModel?.getFilterConfig())
        self.fetchRestaurantSummaryInfos()
    }
    
    func onEndRefreshToDefaultConfigs() {
        self.mModel?.resetFilterConfigToDefault()
        self.mView?.refreshFilterTagList(filterConfigs: self.mModel?.getFilterConfig())
        self.fetchRestaurantSummaryInfos()
    }
    
    func onLocationFloatItemClick() {
        guard LocationManager.shared.isAuthorized() else {
            let title = NSLocalizedString("Notice!!!", comment: "")
            let content = NSLocalizedString("Location services were previously denied. Please enable location services for this app in Settings.", comment: "")
            self.mView?.showAlertDialog(title: title, content: content) {
                action in
                self.mView?.doDismiss(animated: true, completion: nil)
            }
            return
        }
        
        let center = CLLocationCoordinate2D(latitude: (self.mCurLocation?.coordinate.latitude)!, longitude: (self.mCurLocation?.coordinate.longitude)!)
        let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.001,
                                               longitude: center.longitude + 0.001)
        let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.001,
                                               longitude: center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self as GMSPlacePickerViewControllerDelegate
        self.mView?.doPresent(placePicker, animated: true, completion: nil)
    }
    
    func onFilterFloatItemClick() {
        self.mView?.doPerformSegue(withIdentifier: "show_restaurant_filter", sender: nil)
    }
    
    func onNewFilterConfigsApply(filterConfigs:FilterConfigs?) {
        self.mModel?.setFilterConfig(filterConfig: filterConfigs)
//      self.mIsNeedReFetch = true
        self.mView?.refreshFilterTagList(filterConfigs: filterConfigs)
        fetchRestaurantSummaryInfos()
    }
    
    func onRestaurantListItemSelect(summaryInfo:YelpRestaruantSummaryInfo?) {
        self.mView?.doPerformSegue(withIdentifier: "show_restaurant_detail", sender: summaryInfo)
    }
}
