//
//  SSASideMenu.swift
//  SSASideMenuExample
//
//  Created by Sebastian Andersen on 06/10/14.
//  Copyright (c) 2015 Sebastian Andersen. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    var sideMenuViewController: SSASideMenu? {
        get {
            return getSideViewController(self)
        }
    }
    
    fileprivate func getSideViewController(_ viewController: UIViewController) -> SSASideMenu? {
        if let parent = viewController.parent {
            if parent is SSASideMenu {
                return parent as? SSASideMenu
            }else {
                return getSideViewController(parent)
            }
        }
        return nil
    }
    
    @IBAction func presentLeftMenuViewController() {
        
        sideMenuViewController?._presentLeftMenuViewController()
    }
    
    @IBAction func presentRightMenuViewController() {
        
        sideMenuViewController?._presentRightMenuViewController()
    }
}

@objc protocol SSASideMenuDelegate: class {
    @objc  optional func sideMenuDidRecognizePanGesture(_ sideMenu: SSASideMenu, recongnizer: UIPanGestureRecognizer)
    @objc  optional func sideMenuWillShowMenuViewController(_ sideMenu: SSASideMenu, menuViewController: UIViewController)
    @objc  optional func sideMenuDidShowMenuViewController(_ sideMenu: SSASideMenu, menuViewController: UIViewController)
    @objc  optional func sideMenuWillHideMenuViewController(_ sideMenu: SSASideMenu, menuViewController: UIViewController)
    @objc  optional func sideMenuDidHideMenuViewController(_ sideMenu: SSASideMenu, menuViewController: UIViewController)
}

class SSASideMenu: UIViewController, UIGestureRecognizerDelegate {
    
    enum SSASideMenuPanDirection: Int {
        case edge = 0
        case everyWhere = 1
    }
    
    enum SSASideMenuType: Int {
        case scale = 0
        case slip = 1
    }
    
    enum SSAStatusBarStyle: Int {
        case hidden = 0
        case black = 1
        case light = 2
    }
    
    fileprivate enum SSASideMenuSide: Int {
        case left = 0
        case right = 1
    }
    
    struct ContentViewShadow {
        
        var enabled: Bool = true
        var color: UIColor = UIColor.black
        var offset: CGSize = CGSize.zero
        var opacity: Float = 0.4
        var radius: Float = 8.0
        
        init(enabled: Bool = true, color: UIColor = UIColor.black, offset: CGSize = CGSize.zero, opacity: Float = 0.4, radius: Float = 8.0) {
            
            self.enabled = false
            self.color = color
            self.offset = offset
            self.opacity = opacity
            self.radius = radius
        }
    }
    
    struct MenuViewEffect {
        
        var fade: Bool = true
        var scale: Bool = true
        var scaleBackground: Bool = true
        var parallaxEnabled: Bool = true
        var bouncesHorizontally: Bool = true
        var statusBarStyle: SSAStatusBarStyle = .black
        
        init(fade: Bool = true, scale: Bool = true, scaleBackground: Bool = true, parallaxEnabled: Bool = true, bouncesHorizontally: Bool = true, statusBarStyle: SSAStatusBarStyle = .black) {
            
            self.fade = fade
            self.scale = scale
            self.scaleBackground = scaleBackground
            self.parallaxEnabled = parallaxEnabled
            self.bouncesHorizontally = bouncesHorizontally
            self.statusBarStyle = statusBarStyle
        }
    }
    
    struct ContentViewEffect {
        
        var alpha: Float = 1.0
        var scale: Float = 0.7
        var landscapeOffsetX: Float = 30
        var portraitOffsetX: Float = 30
        var minParallaxContentRelativeValue: Float = -25.0
        var maxParallaxContentRelativeValue: Float = 25.0
        var interactivePopGestureRecognizerEnabled: Bool = true
        
        init(alpha: Float = 1.0, scale: Float = 0.7, landscapeOffsetX: Float = 30, portraitOffsetX: Float = 30, minParallaxContentRelativeValue: Float = -25.0, maxParallaxContentRelativeValue: Float = 25.0, interactivePopGestureRecognizerEnabled: Bool = true) {
            
            self.alpha = alpha
            self.scale = scale
            self.landscapeOffsetX = landscapeOffsetX
            self.portraitOffsetX = portraitOffsetX
            self.minParallaxContentRelativeValue = minParallaxContentRelativeValue
            self.maxParallaxContentRelativeValue = maxParallaxContentRelativeValue
            self.interactivePopGestureRecognizerEnabled = interactivePopGestureRecognizerEnabled
        }
    }
    
    struct SideMenuOptions {
        
        var animationDuration: Float = 0.35
        var panGestureEnabled: Bool = true
        var panDirection: SSASideMenuPanDirection = .edge
        var type: SSASideMenuType = .scale
        var panMinimumOpenThreshold: UInt = 60
        var menuViewControllerTransformation: CGAffineTransform = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
        var backgroundTransformation: CGAffineTransform = CGAffineTransform.init(scaleX: 1.7, y: 1.7)
        var endAllEditing: Bool = false
        
        init(animationDuration: Float = 0.35, panGestureEnabled: Bool = true, panDirection: SSASideMenuPanDirection = .edge, type: SSASideMenuType = .scale, panMinimumOpenThreshold: UInt = 60, menuViewControllerTransformation: CGAffineTransform = CGAffineTransform(scaleX: 1.5, y: 1.5), backgroundTransformation: CGAffineTransform = CGAffineTransform(scaleX: 1.7, y: 1.7), endAllEditing: Bool = false) {
            
            self.animationDuration = animationDuration
            self.panGestureEnabled = panGestureEnabled
            self.panDirection = panDirection
            self.type = type
            self.panMinimumOpenThreshold = panMinimumOpenThreshold
            self.menuViewControllerTransformation = menuViewControllerTransformation
            self.backgroundTransformation = backgroundTransformation
            self.endAllEditing = endAllEditing
        }
    }
    
    func configure(_ configuration: MenuViewEffect) {
        fadeMenuView = configuration.fade
        scaleMenuView = configuration.scale
        scaleBackgroundImageView = configuration.scaleBackground
        parallaxEnabled = configuration.parallaxEnabled
        bouncesHorizontally = configuration.bouncesHorizontally
    }
    
    func configure(_ configuration: ContentViewShadow) {
        contentViewShadowEnabled = configuration.enabled
        contentViewShadowColor = configuration.color
        contentViewShadowOffset = configuration.offset
        contentViewShadowOpacity = configuration.opacity
        contentViewShadowRadius = configuration.radius
    }
    
    func configure(_ configuration: ContentViewEffect) {
        contentViewScaleValue = configuration.scale
        contentViewFadeOutAlpha = configuration.alpha
        contentViewInLandscapeOffsetCenterX = configuration.landscapeOffsetX
        contentViewInPortraitOffsetCenterX = configuration.portraitOffsetX
        parallaxContentMinimumRelativeValue = configuration.minParallaxContentRelativeValue
        parallaxContentMaximumRelativeValue = configuration.maxParallaxContentRelativeValue
    }
    
    func configure(_ configuration: SideMenuOptions) {
        animationDuration = configuration.animationDuration
        panGestureEnabled = configuration.panGestureEnabled
        panDirection = configuration.panDirection
        type = configuration.type
        panMinimumOpenThreshold = configuration.panMinimumOpenThreshold
        menuViewControllerTransformation = configuration.menuViewControllerTransformation
        backgroundTransformation = configuration.backgroundTransformation
        endAllEditing = configuration.endAllEditing
    }
    
    // MARK : Storyboard Support
    @IBInspectable var contentViewStoryboardID: String?
    @IBInspectable var leftMenuViewStoryboardID: String?
    @IBInspectable var rightMenuViewStoryboardID: String?
    
    // MARK : Private Properties: MenuView & BackgroundImageView
    @IBInspectable var fadeMenuView: Bool =  true
    @IBInspectable var scaleMenuView: Bool = true
    @IBInspectable var scaleBackgroundImageView: Bool = true
    @IBInspectable var parallaxEnabled: Bool = false
    @IBInspectable var bouncesHorizontally: Bool = true
    
    // MARK : Public Properties: MenuView
    var statusBarStyle: SSAStatusBarStyle = .black
    
    // MARK : Private Properties: ContentView
    @IBInspectable var contentViewScaleValue: Float = 0.7
    @IBInspectable var contentViewFadeOutAlpha: Float = 1.0
    @IBInspectable var contentViewInLandscapeOffsetCenterX: Float = 30.0
    @IBInspectable var contentViewInPortraitOffsetCenterX: Float = 30.0
    @IBInspectable var parallaxContentMinimumRelativeValue: Float = -25.0
    @IBInspectable var parallaxContentMaximumRelativeValue: Float = 25.0
    
    // MARK : Public Properties: ContentView
    @IBInspectable var interactivePopGestureRecognizerEnabled: Bool = true
    @IBInspectable var endAllEditing: Bool = false
    
    // MARK : Private Properties: Shadow for ContentView
    @IBInspectable var contentViewShadowEnabled: Bool = true
    @IBInspectable var contentViewShadowColor: UIColor = UIColor.black
    @IBInspectable var contentViewShadowOffset: CGSize = CGSize.zero
    @IBInspectable var contentViewShadowOpacity: Float = 0.4
    @IBInspectable var contentViewShadowRadius: Float = 8.0
    
    // MARK : Public Properties: SideMenu
    @IBInspectable var animationDuration: Float = 0.35
    @IBInspectable var panGestureEnabled: Bool = true
    var panDirection: SSASideMenuPanDirection = .edge
    var type: SSASideMenuType = .scale
    @IBInspectable var panMinimumOpenThreshold: UInt = 60
    @IBInspectable var menuViewControllerTransformation: CGAffineTransform = CGAffineTransform(scaleX: 1.5, y:1.5)
    @IBInspectable var backgroundTransformation: CGAffineTransform = CGAffineTransform(scaleX: 1.7, y:1.7)
    
    // MARK : Internal Private Properties
    
    weak var delegate: SSASideMenuDelegate?
    
    fileprivate var visible: Bool = false
    fileprivate var leftMenuVisible: Bool = false
    fileprivate var rightMenuVisible: Bool = false
    fileprivate var originalPoint: CGPoint = CGPoint()
    fileprivate var didNotifyDelegate: Bool = false
    
    fileprivate let iOS8: Bool = kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1
    
    fileprivate let menuViewContainer: UIView = UIView()
    fileprivate let contentViewContainer: UIView = UIView()
    fileprivate let contentButton: UIButton = UIButton()
    
    fileprivate let backgroundImageView: UIImageView = UIImageView()
    
    // MARK : Public Properties
    
    @IBInspectable var backgroundImage: UIImage? {
        willSet {
            if let bckImage = newValue {
                backgroundImageView.image = bckImage
            }
        }
    }
    
    var contentViewController: UIViewController? {
        willSet  {
            setupViewController(contentViewContainer, targetViewController: newValue)
        }
        didSet {
            if let controller = oldValue {
                hideViewController(controller)
            }
            setupContentViewShadow()
            if visible {
                setupContentViewControllerMotionEffects()
            }
        }
    }
    
    var leftMenuViewController: UIViewController? {
        willSet  {
            setupViewController(menuViewContainer, targetViewController: newValue)
        }
        didSet {
            if let controller = oldValue {
                hideViewController(controller)
            }
            setupMenuViewControllerMotionEffects()
            view.bringSubview(toFront: contentViewContainer)
        }
    }
    
    var rightMenuViewController: UIViewController? {
        willSet  {
            setupViewController(menuViewContainer, targetViewController: newValue)
        }
        didSet {
            if let controller = oldValue {
                hideViewController(controller)
            }
            setupMenuViewControllerMotionEffects()
            view.bringSubview(toFront: contentViewContainer)
        }
    }
    
    
    // MARK : Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init(contentViewController: UIViewController, leftMenuViewController: UIViewController) {
        self.init()
        self.contentViewController = contentViewController
        self.leftMenuViewController = leftMenuViewController
        
    }
    
    convenience init(contentViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        self.contentViewController = contentViewController
        self.rightMenuViewController = rightMenuViewController
    }
    
    convenience init(contentViewController: UIViewController, leftMenuViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        self.contentViewController = contentViewController
        self.leftMenuViewController = leftMenuViewController
        self.rightMenuViewController = rightMenuViewController
    }
    
    //MARK : Present / Hide Menu ViewControllers
    
    func _presentLeftMenuViewController() {
        presentMenuViewContainerWithMenuViewController(leftMenuViewController)
        showLeftMenuViewController()
    }
    
    func _presentRightMenuViewController() {
        presentMenuViewContainerWithMenuViewController(rightMenuViewController)
        showRightMenuViewController()
    }
    
    @objc func hideMenuViewController() {
        hideMenuViewController(true)
    }
    
    fileprivate func showRightMenuViewController() {
        
        if let viewController = rightMenuViewController {
            
            showMenuViewController(.right, menuViewController: viewController)
            
            UIView.animate(withDuration: TimeInterval(animationDuration), animations: {[unowned self] () -> Void in
                
                self.animateMenuViewController(.right)
                
                self.menuViewContainer.alpha = 1
                self.contentViewContainer.alpha = CGFloat(self.contentViewFadeOutAlpha)
                
                
                }, completion: {[unowned self] (Bool) -> Void in
                    self.animateMenuViewControllerCompletion(.right, menuViewController: viewController)
            })
            statusBarNeedsAppearanceUpdate()
        }
        
    }
    
    fileprivate func showLeftMenuViewController() {
        
        if let viewController = leftMenuViewController {
            
            showMenuViewController(.left, menuViewController: viewController)
            
            UIView.animate(withDuration: TimeInterval(animationDuration), animations: {[unowned self] () -> Void in
                
                self.animateMenuViewController(.left)
                
                self.menuViewContainer.alpha = 1
                self.contentViewContainer.alpha = CGFloat(self.contentViewFadeOutAlpha)
                
                }, completion: {[unowned self] (Bool) -> Void in
                    self.animateMenuViewControllerCompletion(.left, menuViewController: viewController)
            })
            
            statusBarNeedsAppearanceUpdate()
            
        }
    }
    
    fileprivate func showMenuViewController(_ side: SSASideMenuSide, menuViewController: UIViewController) {
        
        menuViewController.view.isHidden = false
        
        switch side {
        case .left:
            leftMenuViewController?.beginAppearanceTransition(true, animated: true)
            rightMenuViewController?.view.isHidden = true
        case .right:
            rightMenuViewController?.beginAppearanceTransition(true, animated: true)
            leftMenuViewController?.view.isHidden = true
        }
        
        if endAllEditing {
            view.window?.endEditing(true)
        }else {
            setupUserInteractionForContentButtonAndTargetViewControllerView(true, targetViewControllerViewInteractive: false)
        }
        
        setupContentButton()
        setupContentViewShadow()
        resetContentViewScale()
        
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    
    fileprivate func animateMenuViewController(_ side: SSASideMenuSide) {
        
        if type == .scale {
            contentViewContainer.transform = CGAffineTransform(scaleX: CGFloat(contentViewScaleValue), y: CGFloat(contentViewScaleValue))
        } else {
            contentViewContainer.transform = CGAffineTransform.identity
        }
        
        if side == .left {
            let centerXLandscape = CGFloat(contentViewInLandscapeOffsetCenterX) + (iOS8 ? CGFloat(view.frame.width) : CGFloat(view.frame.height))
            let centerXPortrait = CGFloat(contentViewInPortraitOffsetCenterX) + CGFloat(view.frame.width)
            
            let centerX = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ?  centerXLandscape : centerXPortrait
            
            contentViewContainer.center = CGPoint(x: centerX, y: contentViewContainer.center.y)
            // contentViewContainer.frame.origin.x = self.view.frame.width * 0.75
            
        } else {
            
            let centerXLandscape = -CGFloat(self.contentViewInLandscapeOffsetCenterX)
            let centerXPortrait = CGFloat(-self.contentViewInPortraitOffsetCenterX)
            
            let centerX = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ? centerXLandscape : centerXPortrait
            
            contentViewContainer.center = CGPoint.init(x: centerX, y: contentViewContainer.center.y)
        }
        
        menuViewContainer.transform = CGAffineTransform.identity
        
        if scaleBackgroundImageView {
            if let _ = backgroundImage {
                backgroundImageView.transform = CGAffineTransform.identity
            }
        }
    }
    
    fileprivate func animateMenuViewControllerCompletion(_ side: SSASideMenuSide, menuViewController: UIViewController) {
        
        if !visible {
            self.delegate?.sideMenuDidShowMenuViewController?(self, menuViewController: menuViewController)
        }
        
        visible = true
        
        switch side {
        case .left:
            leftMenuViewController?.endAppearanceTransition()
            leftMenuVisible = true
        case .right:
            if contentViewContainer.frame.size.width == view.bounds.size.width &&
                contentViewContainer.frame.size.height == view.bounds.size.height &&
                contentViewContainer.frame.origin.x == 0 &&
                contentViewContainer.frame.origin.y == 0 {
                visible = false
            }
            rightMenuVisible = visible
            rightMenuViewController?.endAppearanceTransition()
        }
        
        
        UIApplication.shared.endIgnoringInteractionEvents()
        setupContentViewControllerMotionEffects()
    }
    
    fileprivate func presentMenuViewContainerWithMenuViewController(_ menuViewController: UIViewController?) {
        
        menuViewContainer.transform = CGAffineTransform.identity
        menuViewContainer.frame = view.bounds
        
        if scaleBackgroundImageView {
            if backgroundImage != nil {
                backgroundImageView.transform = CGAffineTransform.identity
                backgroundImageView.frame = view.bounds
                backgroundImageView.transform = backgroundTransformation
            }
        }
        
        if scaleMenuView {
            menuViewContainer.transform = menuViewControllerTransformation
        }
        menuViewContainer.alpha = fadeMenuView ? 0 : 1
        
        if let viewController = menuViewController {
            delegate?.sideMenuWillShowMenuViewController?(self, menuViewController: viewController)
        }
        
    }
    
    fileprivate func hideMenuViewController(_ animated: Bool) {
        
        let isRightMenuVisible: Bool = rightMenuVisible
        
        let visibleMenuViewController: UIViewController? = isRightMenuVisible ? rightMenuViewController : leftMenuViewController
        
        visibleMenuViewController?.beginAppearanceTransition(true, animated: true)
        
        if isRightMenuVisible, let viewController = rightMenuViewController {
            delegate?.sideMenuWillHideMenuViewController?(self, menuViewController: viewController)
        }
        
        if !isRightMenuVisible, let viewController = leftMenuViewController {
            delegate?.sideMenuWillHideMenuViewController?(self, menuViewController: viewController)
        }
        
        if !endAllEditing {
            setupUserInteractionForContentButtonAndTargetViewControllerView(false, targetViewControllerViewInteractive: true)
        }
        
        visible = false
        leftMenuVisible = false
        rightMenuVisible = false
        contentButton.removeFromSuperview()
        
        let animationsClosure: () -> () =  {[unowned self] () -> () in
            
            self.contentViewContainer.transform = CGAffineTransform.identity
            self.contentViewContainer.frame = self.view.bounds
            
            if self.scaleMenuView {
                self.menuViewContainer.transform = self.menuViewControllerTransformation
            }
            self.menuViewContainer.alpha = self.fadeMenuView ? 0 : 1
            self.contentViewContainer.alpha = CGFloat(self.contentViewFadeOutAlpha)
            
            if self.scaleBackgroundImageView {
                if self.backgroundImage != nil {
                    self.backgroundImageView.transform = self.backgroundTransformation
                }
            }
            if self.parallaxEnabled {
                self.removeMotionEffects(self.contentViewContainer)
            }
        }
        
        let completionClosure: () -> () =  {[unowned self] () -> () in
            
            visibleMenuViewController?.endAppearanceTransition()
            
            if isRightMenuVisible, let viewController = self.rightMenuViewController {
                self.delegate?.sideMenuDidHideMenuViewController?(self, menuViewController: viewController)
            }
            
            if !isRightMenuVisible, let viewController = self.leftMenuViewController {
                self.delegate?.sideMenuDidHideMenuViewController?(self, menuViewController: viewController)
            }
        }
        
        if animated {
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            UIView.animate(withDuration: TimeInterval(animationDuration), animations: { () -> Void in
                
                animationsClosure()
                
            }, completion: { (Bool) -> Void in
                completionClosure()
                
                UIApplication.shared.endIgnoringInteractionEvents()
            })
        }else {
            
            animationsClosure()
            completionClosure()
        }
        
        statusBarNeedsAppearanceUpdate()
    }
    
    // MARK : ViewController life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if iOS8 {
            if let cntentViewStoryboardID = contentViewStoryboardID {
                contentViewController = storyboard?.instantiateViewController(withIdentifier: cntentViewStoryboardID)
                
            }
            if let lftViewStoryboardID = leftMenuViewStoryboardID {
                leftMenuViewController = storyboard?.instantiateViewController(withIdentifier: lftViewStoryboardID)
            }
            if let rghtViewStoryboardID = rightMenuViewStoryboardID {
                rightMenuViewController = storyboard?.instantiateViewController(withIdentifier: rghtViewStoryboardID)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        menuViewContainer.frame = view.bounds;
        menuViewContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        menuViewContainer.alpha = fadeMenuView ? 0 : 1
        
        contentViewContainer.frame = view.bounds
        contentViewContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupViewController(contentViewContainer, targetViewController: contentViewController)
        setupViewController(menuViewContainer, targetViewController: leftMenuViewController)
        setupViewController(menuViewContainer, targetViewController: rightMenuViewController)
        
        if panGestureEnabled {
            view.isMultipleTouchEnabled = false
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized(_:)))
            panGestureRecognizer.delegate = self
            view.addGestureRecognizer(panGestureRecognizer)
        }
        
        if let _ = backgroundImage {
            if scaleBackgroundImageView {
                backgroundImageView.transform = backgroundTransformation
            }
            backgroundImageView.frame = view.bounds
            backgroundImageView.contentMode = .scaleAspectFill;
            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
            view.addSubview(backgroundImageView)
        }
        
        view.addSubview(menuViewContainer)
        view.addSubview(contentViewContainer)
        
        setupMenuViewControllerMotionEffects()
        setupContentViewShadow()
        
    }
    
    // MARK : Setup
    
    fileprivate func setupViewController(_ targetView: UIView, targetViewController: UIViewController?) {
        if let viewController = targetViewController {
            
            addChildViewController(viewController)
            viewController.view.frame = view.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            targetView.addSubview(viewController.view)
            viewController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate func hideViewController(_ targetViewController: UIViewController) {
        targetViewController.willMove(toParentViewController: nil)
        targetViewController.view.removeFromSuperview()
        targetViewController.removeFromParentViewController()
    }
    
    // MARK : Layout
    
    fileprivate func setupContentButton() {
        
        if let _ = contentButton.superview {
            return
        } else {
            contentButton.addTarget(self, action: #selector(SSASideMenu.hideMenuViewController as (SSASideMenu) -> () -> ()), for:.touchUpInside)
            contentButton.autoresizingMask = UIViewAutoresizing()
            contentButton.frame = contentViewContainer.bounds
            contentButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentButton.tag = 101
            contentViewContainer.addSubview(contentButton)
        }
        
    }
    
    fileprivate func statusBarNeedsAppearanceUpdate() {
        
        if self.responds(to: #selector(UIViewController.setNeedsStatusBarAppearanceUpdate)) {
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
    }
    
    fileprivate func setupContentViewShadow() {
        
        if contentViewShadowEnabled {
            let layer: CALayer = contentViewContainer.layer
            let path: UIBezierPath = UIBezierPath(rect: layer.bounds)
            layer.shadowPath = path.cgPath
            layer.shadowColor = contentViewShadowColor.cgColor
            layer.shadowOffset = contentViewShadowOffset
            layer.shadowOpacity = contentViewShadowOpacity
            layer.shadowRadius = CGFloat(contentViewShadowRadius)
        }
        
    }
    
    //MARK : Helper Functions
    
    fileprivate func resetContentViewScale() {
        let t: CGAffineTransform = contentViewContainer.transform
        let scale: CGFloat = sqrt(t.a * t.a + t.c * t.c)
        let frame: CGRect = contentViewContainer.frame
        contentViewContainer.transform = CGAffineTransform.identity
        contentViewContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
        contentViewContainer.frame = frame
    }
    
    fileprivate func setupUserInteractionForContentButtonAndTargetViewControllerView(_ contentButtonInteractive: Bool, targetViewControllerViewInteractive: Bool) {
        
        if let viewController = contentViewController {
            for view in viewController.view.subviews {
                if view.tag == 101 {
                    view.isUserInteractionEnabled = contentButtonInteractive
                }else {
                    view.isUserInteractionEnabled = targetViewControllerViewInteractive
                }
            }
        }
    }
    
    // MARK : Motion Effects (Private)
    
    fileprivate func removeMotionEffects(_ targetView: UIView) {
        let targetViewMotionEffects = targetView.motionEffects
        for effect in targetViewMotionEffects {
            targetView.removeMotionEffect(effect)
        }
    }
    
    fileprivate func setupMenuViewControllerMotionEffects() {
        
        if parallaxEnabled {
            removeMotionEffects(menuViewContainer)
            
            // We need to refer to self in closures!
            UIView.animate(withDuration: 0.2, animations: { [unowned self] () -> Void in
                
                let interpolationHorizontal: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                let interpolationVertical: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                self.menuViewContainer.addMotionEffect(interpolationHorizontal)
                self.menuViewContainer.addMotionEffect(interpolationVertical)
            })
        }
    }
    
    fileprivate func setupContentViewControllerMotionEffects() {
        
        if parallaxEnabled {
            
            removeMotionEffects(contentViewContainer)
            
            // We need to refer to self in closures!
            UIView.animate(withDuration: 0.2, animations: { [unowned self] () -> Void in
                
                let interpolationHorizontal: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                let interpolationVertical: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                self.contentViewContainer.addMotionEffect(interpolationHorizontal)
                self.contentViewContainer.addMotionEffect(interpolationVertical)
            })
        }
    }
    
    // MARK : View Controller Rotation handler
    
    override var shouldAutorotate: Bool {
        
        if let cntViewController = contentViewController {
            
            return cntViewController.shouldAutorotate
        }
        return false
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        if visible {
            
            menuViewContainer.bounds = view.bounds
            contentViewContainer.transform = CGAffineTransform.identity
            contentViewContainer.frame = view.bounds
            
            if type == .scale {
                contentViewContainer.transform = CGAffineTransform(scaleX: CGFloat(contentViewScaleValue), y: CGFloat(contentViewScaleValue))
            } else {
                contentViewContainer.transform = CGAffineTransform.identity
            }
            
            var center: CGPoint
            if leftMenuVisible {
                
                let centerXLandscape = CGFloat(contentViewInLandscapeOffsetCenterX) + (iOS8 ? CGFloat(view.frame.width) : CGFloat(view.frame.height))
                let centerXPortrait = CGFloat(contentViewInPortraitOffsetCenterX) + CGFloat(view.frame.width)
                
                let centerX = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ?  centerXLandscape : centerXPortrait
                
                center = CGPoint.init(x: centerX, y: contentViewContainer.center.y)
                
            } else {
                
                let centerXLandscape = -CGFloat(self.contentViewInLandscapeOffsetCenterX)
                let centerXPortrait = CGFloat(-self.contentViewInPortraitOffsetCenterX)
                
                let centerX = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ? centerXLandscape : centerXPortrait
                
                center = CGPoint.init(x: centerX, y: contentViewContainer.center.y)
            }
            
            contentViewContainer.center = center
        }
        
        setupContentViewShadow()
    }
    
    // MARK : Status Bar Appearance Management
    override var preferredStatusBarStyle: UIStatusBarStyle{
        var style: UIStatusBarStyle
        
        switch statusBarStyle {
        case .hidden:
            style = .default
        case .black:
            style = .default
        case .light:
            style = .lightContent
        }
        
        if visible || contentViewContainer.frame.origin.y <= 0, let cntViewController = contentViewController {
            style = cntViewController.preferredStatusBarStyle
        }
        
        return style
    }
    
    override var prefersStatusBarHidden: Bool{
        var statusBarHidden: Bool
        
        switch statusBarStyle {
        case .hidden:
            statusBarHidden = true
        default:
            statusBarHidden = false
        }
        
        if visible || contentViewContainer.frame.origin.y <= 0, let cntViewController = contentViewController {
            statusBarHidden = cntViewController.prefersStatusBarHidden
        }
        
        return statusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        
        var statusBarAnimation: UIStatusBarAnimation = .none
        
        if let cntViewController = contentViewController, let leftMenuViewController = leftMenuViewController {
            
            statusBarAnimation = visible ? leftMenuViewController.preferredStatusBarUpdateAnimation : cntViewController.preferredStatusBarUpdateAnimation
            
            if contentViewContainer.frame.origin.y > 10 {
                statusBarAnimation = leftMenuViewController.preferredStatusBarUpdateAnimation
            } else {
                statusBarAnimation = cntViewController.preferredStatusBarUpdateAnimation
            }
        }
        
        if let cntViewController = contentViewController, let rghtMenuViewController = rightMenuViewController {
            
            statusBarAnimation = visible ? rghtMenuViewController.preferredStatusBarUpdateAnimation : cntViewController.preferredStatusBarUpdateAnimation
            
            if contentViewContainer.frame.origin.y > 10 {
                statusBarAnimation = rghtMenuViewController.preferredStatusBarUpdateAnimation
            } else {
                statusBarAnimation = cntViewController.preferredStatusBarUpdateAnimation
            }
        }
        
        return statusBarAnimation
    }
    
    // MARK : UIGestureRecognizer Delegate (Private)
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if interactivePopGestureRecognizerEnabled,
            let viewController = contentViewController as? UINavigationController
            , viewController.viewControllers.count > 1 && viewController.interactivePopGestureRecognizer!.isEnabled {
            return false
        }
        
        if gestureRecognizer is UIPanGestureRecognizer && !visible {
            
            switch panDirection {
            case .everyWhere:
                return true
            case .edge:
                let point = touch.location(in: gestureRecognizer.view)
                if point.x < 20.0 || point.x > view.frame.size.width - 20.0 { return true }
                else { return false }
            }
        }
        
        return true
    }
    
    @objc func panGestureRecognized(_ recognizer: UIPanGestureRecognizer) {
        
        delegate?.sideMenuDidRecognizePanGesture?(self, recongnizer: recognizer)
        
        if !panGestureEnabled {
            return
        }
        
        var point: CGPoint = recognizer.translation(in: view)
        
        if recognizer.state == .began {
            setupContentViewShadow()
            
            originalPoint = CGPoint.init(x: contentViewContainer.center.x - contentViewContainer.bounds.width / 2.0, y: contentViewContainer.center.y - contentViewContainer.bounds.height / 2.0)
            menuViewContainer.transform = CGAffineTransform.identity
            
            if (scaleBackgroundImageView) {
                backgroundImageView.transform = CGAffineTransform.identity
                backgroundImageView.frame = view.bounds
            }
            
            menuViewContainer.frame = view.bounds
            setupContentButton()
            
            if endAllEditing {
                view.window?.endEditing(true)
            }else {
                setupUserInteractionForContentButtonAndTargetViewControllerView(true, targetViewControllerViewInteractive: false)
            }
            
            didNotifyDelegate = false
        }
        
        if recognizer.state == .changed {
            
            var delta: CGFloat = 0.0
            if visible {
                delta = originalPoint.x != 0 ? (point.x + originalPoint.x) / originalPoint.x : 0
            } else {
                delta = point.x / view.frame.size.width
            }
            
            delta = min(fabs(delta), 1.6)
            
            var contentViewScale: CGFloat = type == .scale ? 1 - ((1 - CGFloat(contentViewScaleValue)) * delta) : 1
            
            var backgroundViewScale: CGFloat = backgroundTransformation.a - ((backgroundTransformation.a - 1) * delta)
            var menuViewScale: CGFloat = menuViewControllerTransformation.a - ((menuViewControllerTransformation.a - 1) * delta)
            
            if !bouncesHorizontally {
                contentViewScale = max(contentViewScale, CGFloat(contentViewScaleValue))
                backgroundViewScale = max(backgroundViewScale, 1.0)
                menuViewScale = max(menuViewScale, 1.0)
            }
            
            menuViewContainer.alpha = fadeMenuView ? delta : 0
            contentViewContainer.alpha = 1 - (1 - CGFloat(contentViewFadeOutAlpha)) * delta
            
            if scaleBackgroundImageView {
                backgroundImageView.transform = CGAffineTransform(scaleX: backgroundViewScale, y: backgroundViewScale)
            }
            
            if scaleMenuView {
                menuViewContainer.transform = CGAffineTransform(scaleX: menuViewScale, y: menuViewScale)
            }
            
            if scaleBackgroundImageView && backgroundViewScale < 1 {
                backgroundImageView.transform = CGAffineTransform.identity
            }
            
            if bouncesHorizontally && visible {
                if contentViewContainer.frame.origin.x > contentViewContainer.frame.size.width / 2.0 {
                    point.x = min(0.0, point.x)
                }
                
                if contentViewContainer.frame.origin.x < -(contentViewContainer.frame.size.width / 2.0) {
                    point.x = max(0.0, point.x)
                }
            }
            
            // Limit size
            if point.x < 0 {
                point.x = max(point.x, -UIScreen.main.bounds.size.height)
            } else {
                point.x = min(point.x, UIScreen.main.bounds.size.height)
            }
            
            recognizer.setTranslation(point, in: view)
            
            if !didNotifyDelegate {
                if point.x > 0  && !visible, let viewController = leftMenuViewController {
                    delegate?.sideMenuWillShowMenuViewController?(self, menuViewController: viewController)
                }
                if point.x < 0 && !visible, let viewController = rightMenuViewController {
                    delegate?.sideMenuWillShowMenuViewController?(self, menuViewController: viewController)
                }
                didNotifyDelegate = true
            }
            
            if contentViewScale > 1 {
                let oppositeScale: CGFloat = (1 - (contentViewScale - 1))
                contentViewContainer.transform = CGAffineTransform(scaleX: oppositeScale, y: oppositeScale)
                contentViewContainer.transform = contentViewContainer.transform.translatedBy(x: point.x, y: 0)
            } else {
                contentViewContainer.transform = CGAffineTransform(scaleX: contentViewScale, y: contentViewScale)
                contentViewContainer.transform = contentViewContainer.transform.translatedBy(x: point.x, y: 0)
            }
            leftMenuViewController?.view.isHidden = contentViewContainer.frame.origin.x < 0
            rightMenuViewController?.view.isHidden = contentViewContainer.frame.origin.x > 0
            
            if  leftMenuViewController == nil && contentViewContainer.frame.origin.x > 0 {
                contentViewContainer.transform = CGAffineTransform.identity
                contentViewContainer.frame = view.bounds
                visible = false
                leftMenuVisible = false
            } else if self.rightMenuViewController == nil && contentViewContainer.frame.origin.x < 0 {
                contentViewContainer.transform = CGAffineTransform.identity
                contentViewContainer.frame = view.bounds
                visible = false
                rightMenuVisible = false
            }
            statusBarNeedsAppearanceUpdate()
        }
        
        if recognizer.state == .ended {
            
            didNotifyDelegate = false
            if panMinimumOpenThreshold > 0 &&
                contentViewContainer.frame.origin.x < 0 &&
                contentViewContainer.frame.origin.x > -CGFloat(panMinimumOpenThreshold) ||
                contentViewContainer.frame.origin.x > 0 &&
                contentViewContainer.frame.origin.x < CGFloat(panMinimumOpenThreshold)  {
                
                hideMenuViewController()
            }
            else if contentViewContainer.frame.origin.x == 0 {
                hideMenuViewController(false)
            }
                
            else if recognizer.velocity(in: view).x > 0 {
                if contentViewContainer.frame.origin.x < 0 {
                    hideMenuViewController()
                } else if leftMenuViewController != nil {
                    showLeftMenuViewController()
                }
            }
            else {
                if contentViewContainer.frame.origin.x < 20 &&  rightMenuViewController != nil{
                    showRightMenuViewController()
                } else {
                    hideMenuViewController()
                }
            }
        }
    }
}
