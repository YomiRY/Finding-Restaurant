//
//  RestaurantDetailViewController2.swift
//  Restaurant-Demo
//
//  Created by yomi on 2018/3/17.
//  Copyright © 2018年 yomi. All rights reserved.
//

import UIKit
import Kingfisher

class RestaurantDetailViewController: UITableViewController, RestaurantDetailViewProtocol, UICollectionViewDataSource, UICollectionViewDelegate {
    
    private static let CELL_ID = "restaurant_detail_photo_cell"
    
    @IBOutlet weak var mIvMainPhotoImageView: UIImageView!
    @IBOutlet weak var mIvStaticMapImageView: UIImageView!
    @IBOutlet weak var mLbAddressLabel: UILabel!
    @IBOutlet weak var mBtnPhoneButton: UIButton!
    @IBOutlet weak var mLbTypeLabel: UILabel!
    @IBOutlet weak var mLbPriceLabel: UILabel!
    @IBOutlet weak var mLbReviews: UILabel!
    @IBOutlet weak var mLbIsOpenStatusLabel: UILabel!
    @IBOutlet weak var mCvRestaurantPhotoCollectionView: UICollectionView!
    @IBOutlet weak var mIvRatingImage: UIImageView!
    @IBOutlet var mTcReviewCellItems: [UITableViewCell]!
    @IBOutlet weak var mLbOpenHoursTitleLabel: UILabel!
    @IBOutlet weak var mTcOpenHoursCell: UITableViewCell!
    @IBOutlet weak var mVOpenHoursContentView: UIView!    
    @IBOutlet weak var mLbNoOpenHoursHintLabel: UILabel!
    
    private var mLoadingAlertController:UIAlertController?
    private var mPresenter:RestaurantDetailPresenterProtocol?
    var mRestaurantSummaryInfo:YelpRestaruantSummaryInfo?
    var mRestaurantDetailInfo:YelpRestaruantDetailInfo?
    private var mRestaurantDetailPhotos:[String]?
    private var mReviewDetailInfos:[YelpReviewDetailInfo]?
    
    // MARK:- Lif cycle & initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        
        self.mPresenter = RestaurantDetailPresenter()
        self.mPresenter?.attachView(view: self)
        self.mPresenter?.onInitParameters(summaryInfo: self.mRestaurantSummaryInfo)
        self.mPresenter?.onViewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.mPresenter?.onViewDidAppear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.mPresenter?.onViewDidDisappear()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initView() {
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.title = self.mRestaurantSummaryInfo?.name ?? ""
        let lat = self.mRestaurantSummaryInfo?.coordinates?.latitude
        let lng = self.mRestaurantSummaryInfo?.coordinates?.longitude
        
        self.tableView.estimatedRowHeight = UITableViewAutomaticDimension
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.mIvStaticMapImageView.kf.cancelDownloadTask()
        self.mIvStaticMapImageView.kf.setImage(with: URL(string: GoogleApiUtil.createStaticMapUrl(lat: lat!, lng: lng!, w: 200, h: 200)), placeholder:  #imageLiteral(resourceName: "no_image"))
    }
    
    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    
    // MARK:- TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Review section
        
        if indexPath.section == 2 {
            self.mPresenter?.onReviewItemSelect(reviewDetail: self.mReviewDetailInfos![indexPath.row])
        }
    }
    
    // MARK:- CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mRestaurantDetailPhotos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RestaurantDetailViewController.CELL_ID, for: indexPath) as? RestaurantDetailPhotoCollectionViewCell else {
            fatalError("Cell is not of kind UICollectionViewCell")
        }
        
        cell.setPhotoUrl(url: self.mRestaurantDetailPhotos?[indexPath.row])
        
        return cell
    }
    
    // Mark:- CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoUrlStrs = self.mRestaurantDetailPhotos else {
            return
        }
        show(Util.createPhotoGallery(sourceViewController:self, currentImgIndex: indexPath.row, urlStrs: photoUrlStrs), sender: nil)
    }
    
    
    // MARK: - onStaticMapPressed
    @IBAction func onStaticMapPressed(_ sender: Any) {
        let lat = self.mRestaurantSummaryInfo?.coordinates?.latitude
        let lng = self.mRestaurantSummaryInfo?.coordinates?.longitude
        let alertController = UIAlertController(title: NSLocalizedString("Select a action", comment: ""), message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        let navigationAction = UIAlertAction(title: NSLocalizedString("Navigation", comment: ""), style: .default) { (action) in
            let url = URL(string: String(format:"http://maps.apple.com/?daddr=%f,%f&dirflg=d", lat!, lng!))
            
            Util.openUrl(url: url!)
        }
        let streetViewAction = UIAlertAction(title: NSLocalizedString("Street View", comment: ""), style: .default) { (action) in
            let panormaViewController = PanoramaViewController()
            panormaViewController.mLat = lat!
            panormaViewController.mLng = lng!
            self.navigationController?.pushViewController(panormaViewController, animated: true)
        }
        alertController.addAction(navigationAction)
        alertController.addAction(streetViewAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - onPhoneButtonPressed
    @IBAction func onPhoneButtonPressed(_ sender: Any) {
        let rawPhoneNum = self.mBtnPhoneButton.titleLabel?.text ?? ""
        let phoneNum = rawPhoneNum.replacingOccurrences(of: "+", with: "")
        let url = URL(string: "tel://\(phoneNum)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url!)
        } else {
            UIApplication.shared.openURL(url!)
        }
    }
    
    // MARK:- RestaurantDetailViewProtocol
    func refreshBasicInfo(summaryInfo:YelpRestaruantSummaryInfo?, detailInfo: YelpRestaruantDetailInfo?) {
        if detailInfo == nil || summaryInfo == nil {
            return;
        }
        self.mIvMainPhotoImageView.kf.cancelDownloadTask()
        self.mIvMainPhotoImageView.kf.setImage(with: URL(string: (detailInfo?.image_url)!), placeholder: #imageLiteral(resourceName: "no_image"))
        //mIvStreetImageView: UIImageView!
        self.mLbAddressLabel.text = detailInfo?.location?.display_address?.joined()
        self.mBtnPhoneButton.setTitle(detailInfo?.phone, for: .normal)
        
        var categoriyTitles:[String] = [String]()
        for categoryInfo in (summaryInfo?.categories)! {
            categoriyTitles.append(categoryInfo.title ?? "")
        }
        self.mLbTypeLabel.text = categoriyTitles.joined(separator: ",")
        self.mIvRatingImage.image = YelpBaseInfo.getRatingImage(rating: detailInfo?.rating ?? 0.0)
        self.mLbPriceLabel.text = detailInfo?.price ?? ""
        self.mLbReviews.text = "\(detailInfo?.review_count ?? 0) " + NSLocalizedString("Reviews", comment: "");
        
        self.mLbIsOpenStatusLabel.text = "N/A"
        if let hours = detailInfo?.hours, let isOpenNow = hours[0].is_open_now {
            self.mLbIsOpenStatusLabel.text = (isOpenNow) ? "OPEN" : "CLOSE"
        }
        
        self.mRestaurantDetailPhotos = detailInfo?.photos
        self.mCvRestaurantPhotoCollectionView.register(UINib(nibName:"RestaurantDetailPhotoCollectionViewCell", bundle:nil), forCellWithReuseIdentifier: RestaurantDetailViewController.CELL_ID)
        self.mCvRestaurantPhotoCollectionView.reloadData()
        
        // Add open hour informations
        var prevView:OpenHourRowView? = nil
        if let hoursInfo:YelpRestaurantHoursInfo = detailInfo?.hours?[0],
            let openHourAry = hoursInfo.open {
            for i in 0..<7 {
                var businessTime:YelpResaruantBusinessTime? = nil
                for hourInfo in openHourAry {
                    if hourInfo.day == i {
                        businessTime = hourInfo
                        break;
                    }
                }
                
                let openHourRowView = OpenHourRowView()
                let isNowWeekDayMatch = YelpUtil.isNowWeekDayFromYelpIndex(index: Util.getNowWeekDay(), yelpIndex: businessTime?.day ?? -1)
                if isNowWeekDayMatch {
                    openHourRowView.mLbDayLabel.font = UIFont.boldSystemFont(ofSize: 17)
                    openHourRowView.mLbOpenTiemRangeLabel.font = UIFont.boldSystemFont(ofSize: 17)
                } else {
                    openHourRowView.mLbDayLabel.font = UIFont.systemFont(ofSize: 17)
                    openHourRowView.mLbOpenTiemRangeLabel.font = UIFont.systemFont(ofSize: 17)
                }
                
                openHourRowView.mLbDayLabel.text = YelpUtil.getWeekDayStrByIndex(index: i)
                openHourRowView.mLbOpenTiemRangeLabel.text = (businessTime == nil || i != businessTime?.day) ? NSLocalizedString("NOT OPEN", comment: "") : String.init(format: "%@ - %@", businessTime?.start ?? "N/A", businessTime?.end ?? "N/A")
                
                openHourRowView.translatesAutoresizingMaskIntoConstraints = false
                self.mVOpenHoursContentView.addSubview(openHourRowView)
                openHourRowView.leftAnchor.constraint(equalTo: self.mVOpenHoursContentView.leftAnchor, constant: 0).isActive = true
                openHourRowView.rightAnchor.constraint(equalTo: self.mVOpenHoursContentView.rightAnchor, constant: 0).isActive = true
                openHourRowView.heightAnchor.constraint(equalToConstant: 30).isActive = true
                if prevView == nil {
                    openHourRowView.topAnchor.constraint(equalTo: self.mLbOpenHoursTitleLabel.bottomAnchor, constant: 10).isActive = true
                } else {
                    if i == 6 {
                        openHourRowView.bottomAnchor.constraint(equalTo: self.mVOpenHoursContentView.bottomAnchor, constant: -10).isActive = true
                    }
                    openHourRowView.topAnchor.constraint(equalTo: (prevView?.bottomAnchor)!, constant: 5).isActive = true
                }
                prevView = openHourRowView
            }
            self.mLbNoOpenHoursHintLabel.isHidden = true
        } else {            
            self.mLbNoOpenHoursHintLabel.isHidden = false
        }
        
        self.tableView.reloadData()
    }
    
    func refreshReviewInfo(reviews: [YelpReviewDetailInfo]?) {
        if reviews == nil {
            return
        }
        self.mReviewDetailInfos = reviews
        let reviewsCount = reviews?.count ?? 0
        for i in 0..<reviewsCount {
            let review = reviews![i]
            if let user = review.user {
                let reviewCellItem = self.mTcReviewCellItems[i]
                (reviewCellItem.viewWithTag(2) as? UILabel)?.text = user.name
                (reviewCellItem.viewWithTag(4) as? UILabel)?.text = review.text
                (reviewCellItem.viewWithTag(1) as? UIImageView)?.kf.cancelDownloadTask()
                (reviewCellItem.viewWithTag(1) as? UIImageView)?.kf.setImage(with: URL(string: (user.image_url ?? "")), placeholder:  #imageLiteral(resourceName: "user-header"))
                (reviewCellItem.viewWithTag(3) as? UIImageView)?.image = YelpBaseInfo.getRatingImage(rating: Double.init(review.rating!))
            }
        }
        
        // Hide the remain TableViewCellItems without data
        for i in stride(from: self.mTcReviewCellItems.count - 1, through: reviewsCount, by: -1) {
            self.mTcReviewCellItems[i].isHidden = true
            self.tableView.contentSize.height -= self.mTcReviewCellItems[i].frame.size.height
        }
    }
    
    func doPresent(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        ImageCache.default.clearMemoryCache()
        self.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    func doDismiss(animated flag: Bool, completion: (() -> Void)?) {
        self.dismiss(animated: flag, completion: completion)
    }
    
    func doPerformSegue(withIdentifier identifier: String, sender: Any?) {
        ImageCache.default.clearMemoryCache()
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    func showLoading(loadingContent: String) {
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
}
