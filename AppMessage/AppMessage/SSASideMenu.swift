//
//  SSASideMenu.swift
//  SSASideMenuExample
//
//  Created by Sebastian Andersen on 06/10/14.
//  Copyright (c) 2015 Sebastian Andersen. All rights reserved.
//
// SwiftLint ignore all

import Foundation
import UIKit

extension UIViewController {
    
    var sideMenuViewController: SSASideMenu? {
        get {
            return getSideViewController(self)
        }
    }
    
    private func getSideViewController(viewController: UIViewController) -> SSASideMenu? {
        if let parent = viewController.parentViewController {
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

@objc protocol SSASideMenuDelegate {
    
    optional func sideMenuDidRecognizePanGesture(sideMenu: SSASideMenu, recongnizer: UIPanGestureRecognizer)
    optional func sideMenuWillShowMenuViewController(sideMenu: SSASideMenu, menuViewController: UIViewController)
    optional func sideMenuDidShowMenuViewController(sideMenu: SSASideMenu, menuViewController: UIViewController)
    optional func sideMenuWillHideMenuViewController(sideMenu: SSASideMenu, menuViewController: UIViewController)
    optional func sideMenuDidHideMenuViewController(sideMenu: SSASideMenu, menuViewController: UIViewController)
    
}

class SSASideMenu: UIViewController, UIGestureRecognizerDelegate {
    
    enum SSASideMenuPanDirection: Int {
        case Edge = 0
        case EveryWhere = 1
    }
    
    enum SSASideMenuType: Int {
        case Scale = 0
        case Slip = 1
    }
    
    enum SSAStatusBarStyle: Int {
        case Hidden = 0
        case Black = 1
        case Light = 2
    }
    
    private enum SSASideMenuSide: Int {
        case Left = 0
        case Right = 1
    }
    
    struct ContentViewShadow {
        
        var enabled: Bool = true
        var color: UIColor = UIColor.blackColor()
        var offset: CGSize = CGSizeZero
        var opacity: Float = 0.4
        var radius: Float = 8.0
        
        init(enabled: Bool = true, color: UIColor = UIColor.blackColor(), offset: CGSize = CGSizeZero, opacity: Float = 0.4, radius: Float = 8.0) {
            
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
        var statusBarStyle: SSAStatusBarStyle = .Black
        
        init(fade: Bool = true, scale: Bool = true, scaleBackground: Bool = true, parallaxEnabled: Bool = true, bouncesHorizontally: Bool = true, statusBarStyle: SSAStatusBarStyle = .Black) {
            
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
        
        var animationDuration: NSTimeInterval = 0.15
        var panGestureEnabled: Bool = true
        var panDirection: SSASideMenuPanDirection = .Edge
        var type: SSASideMenuType = .Scale
        var panMinimumOpenThreshold: UInt = 60
        var menuViewControllerTransformation: CGAffineTransform = CGAffineTransformMakeScale(1.5, 1.5)
        var backgroundTransformation: CGAffineTransform = CGAffineTransformMakeScale(1.7, 1.7)
        var endAllEditing: Bool = false
        
        init(animationDuration: NSTimeInterval = 0.15, panGestureEnabled: Bool = true, panDirection: SSASideMenuPanDirection = .Edge, panMinimumOpenThreshold: UInt = 60, menuViewControllerTransformation: CGAffineTransform = CGAffineTransformMakeScale(1.5, 1.5), backgroundTransformation: CGAffineTransform = CGAffineTransformMakeScale(1.7, 1.7), endAllEditing: Bool = false) {
            
            self.animationDuration = animationDuration
            self.panGestureEnabled = panGestureEnabled
            self.panDirection = panDirection
            self.panMinimumOpenThreshold = panMinimumOpenThreshold
            self.menuViewControllerTransformation = menuViewControllerTransformation
            self.backgroundTransformation = backgroundTransformation
            self.endAllEditing = endAllEditing
        }
    }
    
    func configure(configuration: MenuViewEffect) {
        fadeMenuView = configuration.fade
        scaleMenuView = configuration.scale
        scaleBackgroundImageView = configuration.scaleBackground
        parallaxEnabled = configuration.parallaxEnabled
        bouncesHorizontally = configuration.bouncesHorizontally
    }
    
    func configure(configuration: ContentViewShadow) {
        contentViewShadowEnabled = configuration.enabled
        contentViewShadowColor = configuration.color
        contentViewShadowOffset = configuration.offset
        contentViewShadowOpacity = configuration.opacity
        contentViewShadowRadius = configuration.radius
    }
    
    func configure(configuration: ContentViewEffect) {
        contentViewScaleValue = configuration.scale
        contentViewFadeOutAlpha = configuration.alpha
        contentViewInLandscapeOffsetCenterX = configuration.landscapeOffsetX
        contentViewInPortraitOffsetCenterX = configuration.portraitOffsetX
        parallaxContentMinimumRelativeValue = configuration.minParallaxContentRelativeValue
        parallaxContentMaximumRelativeValue = configuration.maxParallaxContentRelativeValue
    }
    
    func configure(configuration: SideMenuOptions) {
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
    @IBInspectable var parallaxEnabled: Bool = true
    @IBInspectable var bouncesHorizontally: Bool = true
    
    // MARK : Public Properties: MenuView
    @IBInspectable var statusBarStyle: SSAStatusBarStyle = .Black
    
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
    @IBInspectable var contentViewShadowColor: UIColor = UIColor.blackColor()
    @IBInspectable var contentViewShadowOffset: CGSize = CGSizeZero
    @IBInspectable var contentViewShadowOpacity: Float = 0.4
    @IBInspectable var contentViewShadowRadius: Float = 8.0
    
    // MARK : Public Properties: SideMenu
    @IBInspectable var animationDuration: NSTimeInterval = 0.15
    @IBInspectable var panGestureEnabled: Bool = true
    @IBInspectable var panDirection: SSASideMenuPanDirection = .Edge
    @IBInspectable var type: SSASideMenuType = .Scale
    @IBInspectable var panMinimumOpenThreshold: UInt = 60
    @IBInspectable var menuViewControllerTransformation: CGAffineTransform = CGAffineTransformMakeScale(1.5, 1.5)
    @IBInspectable var backgroundTransformation: CGAffineTransform = CGAffineTransformMakeScale(1.7, 1.7)
    
    // MARK : Internal Private Properties
    
    weak var delegate: SSASideMenuDelegate?
    
    private var visible: Bool = false
    private var leftMenuVisible: Bool = false
    private var rightMenuVisible: Bool = false
    private var originalPoint: CGPoint = CGPoint()
    private var didNotifyDelegate: Bool = false
    
    private let iOS8: Bool = kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1
    
    private let menuViewContainer: UIView = UIView()
    private let contentViewContainer: UIView = UIView()
    private let contentButton: UIButton = UIButton()
    
    private let backgroundImageView: UIImageView = UIImageView()
    
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
            view.bringSubviewToFront(contentViewContainer)
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
            view.bringSubviewToFront(contentViewContainer)
        }
    }


    // MARK : Initializers
  
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
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
    
    func hideMenuViewController() {
        hideMenuViewController(true)
    }
    
    
    private func showRightMenuViewController() {
        
        if let viewController = rightMenuViewController {
            
            showMenuViewController(.Right, menuViewController: viewController)
            
            UIView.animateWithDuration(animationDuration, animations: {[unowned self] () -> Void in
                
                self.animateMenuViewController(.Right)
                
                self.menuViewContainer.alpha = 1
                self.contentViewContainer.alpha = CGFloat(self.contentViewFadeOutAlpha)
                
                
                }, completion: {[unowned self] (Bool) -> Void in
                    self.animateMenuViewControllerCompletion(.Right, menuViewController: viewController)
            })
            statusBarNeedsAppearanceUpdate()
        }
        
    }
    
    private func showLeftMenuViewController() {
        
        if let viewController = leftMenuViewController {
            
            showMenuViewController(.Left, menuViewController: viewController)
            
            UIView.animateWithDuration(animationDuration, animations: {[unowned self] () -> Void in
                
                self.animateMenuViewController(.Left)
                
                self.menuViewContainer.alpha = 1
                self.contentViewContainer.alpha = CGFloat(self.contentViewFadeOutAlpha)
                
                }, completion: {[unowned self] (Bool) -> Void in
                    self.animateMenuViewControllerCompletion(.Left, menuViewController: viewController)
            })
            
            statusBarNeedsAppearanceUpdate()
            
        }
    }
    
    private func showMenuViewController(side: SSASideMenuSide, menuViewController: UIViewController) {
        
        menuViewController.view.hidden = false
        
        switch side {
            case .Left:
                leftMenuViewController?.beginAppearanceTransition(true, animated: true)
                rightMenuViewController?.view.hidden = true
            case .Right:
                rightMenuViewController?.beginAppearanceTransition(true, animated: true)
                leftMenuViewController?.view.hidden = true
        }
        
        if endAllEditing {
            view.window?.endEditing(true)
        }else {
            setupUserInteractionForContentButtonAndTargetViewControllerView(true, targetViewControllerViewInteractive: false)
        }
        
        setupContentButton()
        setupContentViewShadow()
        resetContentViewScale()
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    
    private func animateMenuViewController(side: SSASideMenuSide) {
        
        if type == .Scale {
            contentViewContainer.transform = CGAffineTransformMakeScale(CGFloat(contentViewScaleValue), CGFloat(contentViewScaleValue))
        } else {
            contentViewContainer.transform = CGAffineTransformIdentity
        }
        
        if side == .Left {
            let centerXLandscape = CGFloat(contentViewInLandscapeOffsetCenterX) + (iOS8 ? CGFloat(CGRectGetWidth(view.frame)) : CGFloat(CGRectGetHeight(view.frame)))
            let centerXPortrait = CGFloat(contentViewInPortraitOffsetCenterX) + CGFloat(CGRectGetWidth(view.frame))
            
            let centerX = UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ?  centerXLandscape : centerXPortrait
            
            contentViewContainer.center = CGPointMake(centerX, contentViewContainer.center.y)
            
        } else {
            
            let centerXLandscape = -CGFloat(self.contentViewInLandscapeOffsetCenterX)
            let centerXPortrait = CGFloat(-self.contentViewInPortraitOffsetCenterX)
            let centerX = UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ? centerXLandscape : centerXPortrait
            
            contentViewContainer.center = CGPointMake(centerX, contentViewContainer.center.y)
        }

        menuViewContainer.transform = CGAffineTransformIdentity
        
        if scaleBackgroundImageView {
            if let _ = backgroundImage {
                backgroundImageView.transform = CGAffineTransformIdentity
            }
        }
    }
    
    private func animateMenuViewControllerCompletion(side: SSASideMenuSide, menuViewController: UIViewController) {
        
        if !visible {
            self.delegate?.sideMenuDidShowMenuViewController?(self, menuViewController: menuViewController)
        }
        
        visible = true
        
        switch side {
            case .Left:
                leftMenuViewController?.endAppearanceTransition()
                leftMenuVisible = true
            case .Right:
                if contentViewContainer.frame.size.width == view.bounds.size.width &&
                    contentViewContainer.frame.size.height == view.bounds.size.height &&
                    contentViewContainer.frame.origin.x == 0 &&
                    contentViewContainer.frame.origin.y == 0 {
                        visible = false
                }
                rightMenuVisible = visible
                rightMenuViewController?.endAppearanceTransition()
        }
        
        
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        setupContentViewControllerMotionEffects()
    }
 
    private func presentMenuViewContainerWithMenuViewController(menuViewController: UIViewController?) {
        
        menuViewContainer.transform = CGAffineTransformIdentity
        menuViewContainer.frame = view.bounds
        
        if scaleBackgroundImageView {
            if backgroundImage != nil {
                backgroundImageView.transform = CGAffineTransformIdentity
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
    
    private func hideMenuViewController(animated: Bool) {
        
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
            
            self.contentViewContainer.transform = CGAffineTransformIdentity
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
            
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                
                animationsClosure()
                
                }, completion: { (Bool) -> Void in
                    completionClosure()
                    
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
            })
            
        }else {
            
            animationsClosure()
            completionClosure()
        }
        
        statusBarNeedsAppearanceUpdate()
        
    }
    
    // MARK : ViewController life cycle
    
    override func awakeFromNib() {
        
        if iOS8 {
            if let cntentViewStoryboardID = contentViewStoryboardID {
                contentViewController = storyboard?.instantiateViewControllerWithIdentifier(cntentViewStoryboardID)
            }
            if let lftViewStoryboardID = leftMenuViewStoryboardID {
                leftMenuViewController = storyboard?.instantiateViewControllerWithIdentifier(lftViewStoryboardID)             }
            if let rghtViewStoryboardID = rightMenuViewStoryboardID {
                rightMenuViewController = storyboard?.instantiateViewControllerWithIdentifier(rghtViewStoryboardID)
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        menuViewContainer.frame = view.bounds;
        menuViewContainer.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
        menuViewContainer.alpha = fadeMenuView ? 0 : 1
  
        contentViewContainer.frame = view.bounds
        contentViewContainer.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        setupViewController(contentViewContainer, targetViewController: contentViewController)
        setupViewController(menuViewContainer, targetViewController: leftMenuViewController)
        setupViewController(menuViewContainer, targetViewController: rightMenuViewController)
        
        if panGestureEnabled {
            view.multipleTouchEnabled = false
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SSASideMenu.panGestureRecognized(_:)))
            panGestureRecognizer.delegate = self
            view.addGestureRecognizer(panGestureRecognizer)
        }
        
        if let _ = backgroundImage {
            if scaleBackgroundImageView {
                backgroundImageView.transform = backgroundTransformation
            }
            backgroundImageView.frame = view.bounds
            backgroundImageView.contentMode = .ScaleAspectFill;
            backgroundImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
            view.addSubview(backgroundImageView)
        }
        
        view.addSubview(menuViewContainer)
        view.addSubview(contentViewContainer)

        setupMenuViewControllerMotionEffects()
        setupContentViewShadow()
        
    }
 
    
    // MARK : Setup
    
    private func setupViewController(targetView: UIView, targetViewController: UIViewController?) {
        if let viewController = targetViewController {
            
            addChildViewController(viewController)
            viewController.view.frame = view.bounds
            viewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            targetView.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
            
        }
    }
    
    private func hideViewController(targetViewController: UIViewController) {
            targetViewController.willMoveToParentViewController(nil)
            targetViewController.view.removeFromSuperview()
            targetViewController.removeFromParentViewController()
    }
    
    // MARK : Layout
    
    private func setupContentButton() {
        
        if contentButton.superview != nil{
            return
        } else {
            contentButton.addTarget(self, action: #selector(SSASideMenu.hideMenuViewController as (SSASideMenu) -> () -> ()), forControlEvents:.TouchUpInside)
            contentButton.autoresizingMask = .None
            contentButton.frame = contentViewContainer.bounds
            contentButton.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            contentButton.tag = 101
            contentViewContainer.addSubview(contentButton)
        }

    }
    
    private func statusBarNeedsAppearanceUpdate() {
        
        if self.respondsToSelector(#selector(UIViewController.setNeedsStatusBarAppearanceUpdate)) {
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
    }
    
    private func setupContentViewShadow() {
        
        if contentViewShadowEnabled {
            let layer: CALayer = contentViewContainer.layer
            let path: UIBezierPath = UIBezierPath(rect: layer.bounds)
            layer.shadowPath = path.CGPath
            layer.shadowColor = contentViewShadowColor.CGColor
            layer.shadowOffset = contentViewShadowOffset
            layer.shadowOpacity = contentViewShadowOpacity
            layer.shadowRadius = CGFloat(contentViewShadowRadius)
        }
        
    }
    
    //MARK : Helper Functions 
    
    private func resetContentViewScale() {
        let t: CGAffineTransform = contentViewContainer.transform
        let scale: CGFloat = sqrt(t.a * t.a + t.c * t.c)
        let frame: CGRect = contentViewContainer.frame
        contentViewContainer.transform = CGAffineTransformIdentity
        contentViewContainer.transform = CGAffineTransformMakeScale(scale, scale)
        contentViewContainer.frame = frame
    }
    
    private func setupUserInteractionForContentButtonAndTargetViewControllerView(contentButtonInteractive: Bool, targetViewControllerViewInteractive: Bool) {
        
        if let viewController = contentViewController {
            for view in viewController.view.subviews as [UIView] {
                if view.tag == 101 {
                    view.userInteractionEnabled = contentButtonInteractive
                }else {
                    view.userInteractionEnabled = targetViewControllerViewInteractive
                }
            }
        }
        
    }
    
    // MARK : Motion Effects (Private)
    
    private func removeMotionEffects(targetView: UIView) {
        for effect in targetView.motionEffects {
            targetView.removeMotionEffect(effect as UIMotionEffect)
        }
    }
    
    private func setupMenuViewControllerMotionEffects() {
        
        if parallaxEnabled {
            removeMotionEffects(menuViewContainer)
            
            // We need to refer to self in closures!
            UIView.animateWithDuration(0.2, animations: { [unowned self] () -> Void in
                
                let interpolationHorizontal: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                let interpolationVertical: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                self.menuViewContainer.addMotionEffect(interpolationHorizontal)
                self.menuViewContainer.addMotionEffect(interpolationVertical)
                
                })
        }
    }
    
    
    private func setupContentViewControllerMotionEffects() {
        
        if parallaxEnabled {
            
            removeMotionEffects(contentViewContainer)
            
            // We need to refer to self in closures!
            UIView.animateWithDuration(0.2, animations: { [unowned self] () -> Void in
                
                let interpolationHorizontal: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                let interpolationVertical: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
                interpolationHorizontal.minimumRelativeValue = self.parallaxContentMinimumRelativeValue
                interpolationHorizontal.maximumRelativeValue = self.parallaxContentMaximumRelativeValue
                
                self.contentViewContainer.addMotionEffect(interpolationHorizontal)
                self.contentViewContainer.addMotionEffect(interpolationVertical)
                
                })
        }
        
        
    }
    
    // MARK : View Controller Rotation handler
    
    override func shouldAutorotate() -> Bool {
        
        if let cntViewController = contentViewController {
            
            return cntViewController.shouldAutorotate()
        }
        return false
        
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if visible {
            
            menuViewContainer.bounds = view.bounds
            contentViewContainer.transform = CGAffineTransformIdentity
            contentViewContainer.frame = view.bounds
            
            if type == .Scale {
                contentViewContainer.transform = CGAffineTransformMakeScale(CGFloat(contentViewScaleValue), CGFloat(contentViewScaleValue))
            } else {
                contentViewContainer.transform = CGAffineTransformIdentity
            }
            
            var center: CGPoint
            if leftMenuVisible {
                
                let centerXLandscape = CGFloat(contentViewInLandscapeOffsetCenterX) + (iOS8 ? CGFloat(CGRectGetWidth(view.frame)) : CGFloat(CGRectGetHeight(view.frame)))
                let centerXPortrait = CGFloat(contentViewInPortraitOffsetCenterX) + CGFloat(CGRectGetWidth(view.frame))
                
                let centerX = UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ?  centerXLandscape : centerXPortrait
                
                center = CGPointMake(centerX, contentViewContainer.center.y)
            } else {
                
                let centerXLandscape = -CGFloat(self.contentViewInLandscapeOffsetCenterX)
                let centerXPortrait = CGFloat(-self.contentViewInPortraitOffsetCenterX)
                let centerX = UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ? centerXLandscape : centerXPortrait
                center = CGPointMake(centerX, contentViewContainer.center.y)
            }
            
            contentViewContainer.center = center
        }
        
        setupContentViewShadow()
        
    }

    
    // MARK : Status Bar Appearance Management
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        var style: UIStatusBarStyle
        
        switch statusBarStyle {
            case .Hidden:
                style = .Default
            case .Black:
                style = .Default
            case .Light:
                style = .LightContent
        }
        
        if visible || contentViewContainer.frame.origin.y <= 0, let cntViewController = contentViewController {
            style = cntViewController.preferredStatusBarStyle()
        }
        
        return style
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        
        var statusBarHidden: Bool
        
        switch statusBarStyle {
            case .Hidden:
                statusBarHidden = true
            default:
                statusBarHidden = false
            }
        
        if visible || contentViewContainer.frame.origin.y <= 0, let cntViewController = contentViewController {
            statusBarHidden = cntViewController.prefersStatusBarHidden()
        }
        
        return statusBarHidden
    }

    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        
        var statusBarAnimation: UIStatusBarAnimation = .None
        
        if let cntViewController = contentViewController, leftMenuViewController = leftMenuViewController {
            
            statusBarAnimation = visible ? leftMenuViewController.preferredStatusBarUpdateAnimation() : cntViewController.preferredStatusBarUpdateAnimation()
            
            if contentViewContainer.frame.origin.y > 10 {
                statusBarAnimation = leftMenuViewController.preferredStatusBarUpdateAnimation()
            } else {
                statusBarAnimation = cntViewController.preferredStatusBarUpdateAnimation()
            }
        }
        
        if let cntViewController = contentViewController, rghtMenuViewController = rightMenuViewController {
            
            statusBarAnimation = visible ? rghtMenuViewController.preferredStatusBarUpdateAnimation() : cntViewController.preferredStatusBarUpdateAnimation()
            
            if contentViewContainer.frame.origin.y > 10 {
                statusBarAnimation = rghtMenuViewController.preferredStatusBarUpdateAnimation()
            } else {
                statusBarAnimation = cntViewController.preferredStatusBarUpdateAnimation()
            }
        }
        
        return statusBarAnimation
        
    }

    
    // MARK : UIGestureRecognizer Delegate (Private)
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if interactivePopGestureRecognizerEnabled,
            let viewController = contentViewController as? UINavigationController
            where viewController.viewControllers.count > 1 && viewController.interactivePopGestureRecognizer!.enabled {
                return false
        }
        
        if gestureRecognizer is UIPanGestureRecognizer && !visible {
            
            switch panDirection {
            case .EveryWhere:
                return true
            case .Edge:
                let point = touch.locationInView(gestureRecognizer.view)
                if point.x < 20.0 || point.x > view.frame.size.width - 20.0 { return true }
                else { return false }
            }
        }
        
        return true
    }
    
    func panGestureRecognized(recognizer: UIPanGestureRecognizer) {
        
        delegate?.sideMenuDidRecognizePanGesture?(self, recongnizer: recognizer)
        
        if !panGestureEnabled {
            return
        }
        
        var point: CGPoint = recognizer.translationInView(view)
        
        if recognizer.state == .Began {
            setupContentViewShadow()
            
            originalPoint = CGPointMake(contentViewContainer.center.x - CGRectGetWidth(contentViewContainer.bounds) / 2.0,
                contentViewContainer.center.y - CGRectGetHeight(contentViewContainer.bounds) / 2.0)
            menuViewContainer.transform = CGAffineTransformIdentity
            
            if (scaleBackgroundImageView) {
                backgroundImageView.transform = CGAffineTransformIdentity
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
        
        if recognizer.state == .Changed {
            
            var delta: CGFloat = 0.0
            if visible {
                delta = originalPoint.x != 0 ? (point.x + originalPoint.x) / originalPoint.x : 0
            } else {
                delta = point.x / view.frame.size.width
            }
            
            delta = min(fabs(delta), 1.6)
            
            var contentViewScale: CGFloat = type == .Scale ? 1 - ((1 - CGFloat(contentViewScaleValue)) * delta) : 1
            
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
                backgroundImageView.transform = CGAffineTransformMakeScale(backgroundViewScale, backgroundViewScale)
            }
            
            if scaleMenuView {
                menuViewContainer.transform = CGAffineTransformMakeScale(menuViewScale, menuViewScale)
            }
            
            if scaleBackgroundImageView && backgroundViewScale < 1 {
                backgroundImageView.transform = CGAffineTransformIdentity
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
                point.x = max(point.x, -UIScreen.mainScreen().bounds.size.height)
            } else {
                point.x = min(point.x, UIScreen.mainScreen().bounds.size.height)
            }
            
            recognizer.setTranslation(point, inView: view)
            
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
                contentViewContainer.transform = CGAffineTransformMakeScale(oppositeScale, oppositeScale)
                contentViewContainer.transform = CGAffineTransformTranslate(contentViewContainer.transform, point.x, 0)
            } else {
                contentViewContainer.transform = CGAffineTransformMakeScale(contentViewScale, contentViewScale)
                contentViewContainer.transform = CGAffineTransformTranslate(contentViewContainer.transform, point.x, 0)
            }
            
            leftMenuViewController?.view.hidden = contentViewContainer.frame.origin.x < 0
            rightMenuViewController?.view.hidden = contentViewContainer.frame.origin.x > 0
            
            if  leftMenuViewController == nil && contentViewContainer.frame.origin.x > 0 {
                contentViewContainer.transform = CGAffineTransformIdentity
                contentViewContainer.frame = view.bounds
                visible = false
                leftMenuVisible = false
            } else if self.rightMenuViewController == nil && contentViewContainer.frame.origin.x < 0 {
                contentViewContainer.transform = CGAffineTransformIdentity
                contentViewContainer.frame = view.bounds
                visible = false
                rightMenuVisible = false
            }
            
            statusBarNeedsAppearanceUpdate()
        }
        
        if recognizer.state == .Ended {
            
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
                
            else if recognizer.velocityInView(view).x > 0 {
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