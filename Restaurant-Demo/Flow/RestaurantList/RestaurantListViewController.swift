//
//  RestaurantListViewController2.swift
//  Restaurant-Demo
//
//  Created by yomi on 2018/3/3.
//  Copyright © 2018年 yomi. All rights reserved.
//

import UIKit
import TagListView
import GooglePlaces
import GooglePlacePicker
import Kingfisher

class RestaurantListViewController: UITableViewController, RestaurantListViewProtocol, UISearchResultsUpdating, TagListViewDelegate, UIViewControllerPreviewingDelegate {
    
    private static let CELL_ID = "menu_cell"
    
    @IBOutlet weak var mTlvFilterRuleTagList: TagListView!
    @IBOutlet weak var mVFilterRuleListContainerView: UIView!
    
    private var mScNameSearchController:UISearchController?
    private var mRcRefreshControl:UIRefreshControl?
    private var mLoadingAlertController:UIAlertController?
    private var mPresenter:RestaurantListPresenterProtocol?
    private var mRestaurantSummaryInfos: [YelpRestaruantSummaryInfo]?
    private var mShortcutItemAction:QuickAction?
    var mFilterConfig:FilterConfigs?
    private var mCurSearchText = ""
    private var mIsViewAppear = false
    private var mIsFirstDisp = true
    
    // MARK:- Life cycle & initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        
        // 3D touch preview for restaurant detail
        if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            registerForPreviewing(with: self as UIViewControllerPreviewingDelegate, sourceView: self.view)
        }
        self.mRestaurantSummaryInfos = Array<YelpRestaruantSummaryInfo>()
        self.mPresenter = RestaurantListPresenter()
        self.mPresenter?.attachView(view: self)
        self.mPresenter?.onViewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.mIsViewAppear = true
        
        self.receiveShortcutItemAction(shortcutItemAction: self.mShortcutItemAction)
        self.mPresenter?.onViewDidAppear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.mIsViewAppear = false
        self.mPresenter?.onViewDidDisappear()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initView() {
        /* Init NavigationController  */
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        /* Init TableView  */
        self.mRcRefreshControl = UIRefreshControl()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 30
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = self.mRcRefreshControl
        } else {
            self.tableView.addSubview(self.mRcRefreshControl!)
        }
        self.mRcRefreshControl?.addTarget(self, action: #selector(refreshListToDefaultConfigs), for:.valueChanged)
        self.mRcRefreshControl?.attributedTitle = NSAttributedString(string: NSLocalizedString("Loading Data...", comment: ""))
        
        /* Init tag list view */
        self.mTlvFilterRuleTagList.textFont = UIFont.systemFont(ofSize: 16)
        
        /* Init SearchController */
        self.mScNameSearchController = UISearchController(searchResultsController: nil)
        self.mScNameSearchController?.initStyle(updater: self, placeholoderTxt: NSLocalizedString("Please input the search keyword", comment: ""))
        self.navigationItem.searchController = self.mScNameSearchController
        // Hide the search bar when scrolling up, Default is true. if setup as false it will always display
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        /* Init float button */
        let floaty = Floaty()
        floaty.buttonImage =  #imageLiteral(resourceName: "menu_icon")
        floaty.openAnimationType = .pop
        floaty.hasShadow = false
        floaty.sticky = true
        floaty.paddingX = 20
        floaty.paddingY = 20
        floaty.itemTitleColor = UIColor.darkGray
        // FIXME: LocationPicker for iOS has beed deprecated and closed QQ
        // Locate user's location
        //        floaty.addItem(icon:  #imageLiteral(resourceName: "location_icon")) { (floatItem) in
        //            self.mPresenter?.onLocationFloatItemClick()
        //        }
        // filter
        floaty.addItem(icon:  #imageLiteral(resourceName: "filter")) { (floatItem) in
            self.mPresenter?.onFilterFloatItemClick()
        }
        self.view.addSubview(floaty)
    }
    
    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier;
        
        if identifier == "show_restaurant_detail" {
            let destViewController = segue.destination as! RestaurantDetailViewController
            let summaryInfo = sender as! YelpRestaruantSummaryInfo
            
            destViewController.mRestaurantSummaryInfo = summaryInfo
        }
    }
    
    // MARK: - Unwind Segue
    @IBAction func unwindToRestaurantList(segue: UIStoryboardSegue) {
        let segueIdentifier = segue.identifier
        
        if segueIdentifier == "press_apply_unwind_segue" {
            segue.source.dismiss(animated: true) {
                self.mPresenter?.onNewFilterConfigsApply(filterConfigs: self.mFilterConfig)
            }
        }
    }
    
    // MARK: - UIRefreshController pull-to-refresh target
    @objc func refreshListToDefaultConfigs(_ sender: Any) {
        // Use the taipei station as default location
        self.mPresenter?.onEndRefreshToDefaultConfigs()
        self.mCurSearchText = ""
    }
    
    // MARK:- UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // Avoid continue update searching result when click list item
        guard self.mCurSearchText != searchController.searchBar.text else {
            return
        }
        self.mCurSearchText = searchController.searchBar.text ?? ""
        self.mPresenter?.onSearchKeyworkChange(keyword: self.mCurSearchText)
    }
    
    // MARK:- TablViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mRestaurantSummaryInfos?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantListViewController.CELL_ID) as? RestaurantInfoTableViewCell else {
            fatalError("Cell is not of kind RestaurantInfoTableViewCell")
        }
        let restaurantInfo = self.mRestaurantSummaryInfos![indexPath.row]
        
        cell.mLbNameLabel.text = restaurantInfo.name
        cell.mLbDistanceLabel.text = String(format: "%.2fm", arguments: [restaurantInfo.distance!])
        cell.mLbPriceLabel.text = restaurantInfo.price ?? ""
        cell.mLbReviewsLabel.text = (restaurantInfo.review_count != nil) ? "\(restaurantInfo.review_count ?? 0) " + NSLocalizedString("Reviews", comment: "") : ""
        cell.mLbAddressLabel.text = restaurantInfo.location?.display_address?.joined()
        cell.mIvPhotoImageView.kf.cancelDownloadTask()
        cell.mIvPhotoImageView.kf.setImage(with: URL(string: restaurantInfo.image_url ?? ""), placeholder:  #imageLiteral(resourceName: "no_image"))
        cell.mIvRatingImage.image = YelpBaseInfo.getRatingImage(rating: restaurantInfo.rating ?? 0.0)
        cell.mLbTypeLabel.text = restaurantInfo.categoriesStr
        
        return cell
    }
    
    // MARK: - Table view data delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: It's workaround to avoid the crash when searchcontroller is activie and go back from detail page
//        self.mScNameSearchController?.isActive = false
        
        self.mPresenter?.onRestaurantListItemSelect(summaryInfo: self.mRestaurantSummaryInfos?[indexPath.row])
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // get the cell row and cell according to the touch position
        guard let indxPath = self.tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indxPath) else {
            return nil
        }
        
        guard let restaurantDetailViewController = storyboard?.instantiateViewController(withIdentifier: "restaurant_detail_view_controller") as? RestaurantDetailViewController else {
            return nil
        }
        
        let summaryInfo = self.mRestaurantSummaryInfos?[indxPath.row]
        restaurantDetailViewController.mRestaurantSummaryInfo = summaryInfo
        restaurantDetailViewController.preferredContentSize = CGSize(width: 0.0, height: self.view.frame.size.height * 0.66)
        previewingContext.sourceRect = cell.frame
        
        return restaurantDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    // MARK:- RestaurantListViewProtocol
    
    func receiveShortcutItemAction(shortcutItemAction: QuickAction?) {
        self.mShortcutItemAction = shortcutItemAction
        
        if self.mShortcutItemAction != nil, self.mIsViewAppear, !self.mIsFirstDisp {
            //[TODO:]
            // flow won't go to refreshList, so call onHandleShortcutItemAction directly.
            self.mPresenter?.onHandleShortcutItemAction(shortcutItemAction: self.mShortcutItemAction)
            self.mShortcutItemAction = nil
        }
    }
    
    func refreshList(restaurantSummaryInfos: [YelpRestaruantSummaryInfo]?) {
        self.mRestaurantSummaryInfos = restaurantSummaryInfos
        self.mIsFirstDisp = false
        self.mRcRefreshControl?.endRefreshing()
        self.tableView.reloadData()
        
        if self.mShortcutItemAction != nil {
            // TODO:
            // flow from app first launched, it will do refresh list.
            self.mPresenter?.onHandleShortcutItemAction(shortcutItemAction: self.mShortcutItemAction)
            self.mShortcutItemAction = nil
        }
    }
    
    func refreshFilterTagList(filterConfigs: FilterConfigs?) {
        self.mTlvFilterRuleTagList.removeAllTags()
        if let sortRuleStr = filterConfigs?.mSortingRuleDisplayStr {
            let tagView = self.mTlvFilterRuleTagList.addTag(sortRuleStr)
            tagView.onTap = {
                tagView in
                guard self.mTlvFilterRuleTagList.tagViews.count > 1 else {
                    return
                }
                self.mTlvFilterRuleTagList.removeTagView(tagView)
                self.mPresenter?.onFilterTagTap(tagType: TagType.sorting_rule)
            }
        }
        if let openAt = filterConfigs?.mOpenAt {
            let openDate = Date(timeIntervalSince1970: Double(openAt))
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let tagView = self.mTlvFilterRuleTagList.addTag(NSLocalizedString("OPEN AT ", comment: "") + formatter.string(from: openDate))
            tagView.onTap = {
                tagView in
                guard self.mTlvFilterRuleTagList.tagViews.count > 1 else {
                    return
                }
                self.mTlvFilterRuleTagList.removeTagView(tagView)
                self.mPresenter?.onFilterTagTap(tagType: TagType.open_at)
            }
        }
        if let priceStr = filterConfigs?.mPriceDisplayStr {
            let tagView = self.mTlvFilterRuleTagList.addTag(priceStr)
            tagView.onTap = {
                tagView in
                guard self.mTlvFilterRuleTagList.tagViews.count > 1 else {
                    return
                }
                self.mTlvFilterRuleTagList.removeTagView(tagView)
                self.mPresenter?.onFilterTagTap(tagType: TagType.price)
            }
        }
    }
    
    func showLoading(loadingContent:String) {
        self.mLoadingAlertController = UIAlertController(title: nil, message: loadingContent, preferredStyle: .alert)
        self.mLoadingAlertController?.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:10,y:5, width:50, height:50))
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        self.mLoadingAlertController?.view.addSubview(loadingIndicator)
        self.present(self.mLoadingAlertController!, animated: true, completion: nil)
    }
    
    func closeLoading() {
        if self.mLoadingAlertController != nil {
            self.dismiss(animated: true, completion: nil)
            self.mLoadingAlertController = nil
        }
    }
    
    func showAlertDialog(title: String, content: String, handler: ((UIAlertAction) -> Void)?) {
        let alertDialog = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:handler)
        alertDialog.addAction(okAction)
        self.present(alertDialog, animated: true, completion: nil)
    }
    
    func doPresent(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Swift.Void)?) {
        self.navigationController?.navigationBar.prefersLargeTitles = false
        ImageCache.default.clearMemoryCache()
        self.navigationController?.pushViewController(viewControllerToPresent, animated: true)
    }
    func doDismiss(animated flag: Bool, completion: (() -> Swift.Void)?) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.popViewController(animated: true)
    }
    
    func doPerformSegue(withIdentifier identifier: String, sender: Any?) {
        ImageCache.default.clearMemoryCache()
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}
