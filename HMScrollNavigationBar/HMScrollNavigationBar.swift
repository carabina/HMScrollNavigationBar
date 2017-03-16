//
//  HMScrollNavigationBar.swift
//  HMScrollNavigationBar
//
//  Created by Piotr Sękara on 15.03.2017.
//  Copyright © 2017 Handcrafted Mobile Sp. z o.o. All rights reserved.
//

import Foundation
import UIKit

private var HMNavigationBarManagerAssociationKey: UInt8 = 0

//MARK: UIViewController extension

public extension UIViewController {
    var navigationBarManager: HMNavigationBarManager! {
        get {
            var navigationBarManager = objc_getAssociatedObject(self, &HMNavigationBarManagerAssociationKey) as? HMNavigationBarManager
            if(navigationBarManager == nil) {
                navigationBarManager = HMNavigationBarManager()
                navigationBarManager?.view = self.view
                self.navigationBarManager = navigationBarManager
            }
            return navigationBarManager!
        }
        set(newValue) {
            objc_setAssociatedObject(self, &HMNavigationBarManagerAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}


//MARK: Protocols

public protocol NavBarAnimatable {
    func animateShowingNavBar()
    func animateHidingNavBar()
    func animateNavBarWithParams(scrollingHeight: CGFloat, scrollViewHeight: CGFloat)
}

public protocol HMManagerSetup {
    func setupManager(scrollView: UIScrollView, navBar: UIView)
}


//MARK: Implementation

open class HMNavigationBarManager: NSObject, NavBarAnimatable {
    
    var application: UIApplication = UIApplication.shared
    
    var scrollView: UIScrollView?
    var navBar : UIView?
    
    lazy private(set) var statusBarHeight: CGFloat = self.application.statusBarFrame.size.height
    
    var navBarHeight: CGFloat?
    var lastScrollingOffsetY: CGFloat = 0
    var startDraggingOffsetY: CGFloat = 0
    var view: UIView?
    
    public func animateShowingNavBar() {
        UIView.animate(withDuration: 0.1, animations: {
            self.navBar?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.navBarHeight!)
            self.navBar?.alpha = 1.0
            self.scrollView?.frame = CGRect(x: 0, y: self.navBarHeight!, width: self.view.frame.width, height: self.view.frame.height - self.navBarHeight!)
        })
    }
    
    public func animateHidingNavBar() {
        UIView.animate(withDuration: 0.1, animations: {
            self.navBar?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0)
            self.navBar?.alpha = 0.0
            self.scrollView?.frame = CGRect(x: 0, y: self.statusBarHeight, width: self.view.frame.width, height: self.view.frame.height - self.statusBarHeight)
        })
    }
    
    public func animateNavBarWithParams(scrollingHeight: CGFloat, scrollViewHeight: CGFloat) {
        UIView.animate(withDuration: 0.1, animations: {
            self.navBar?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: scrollingHeight)
            self.navBar?.alpha = scrollingHeight / self.navBarHeight!
            self.scrollView?.frame = CGRect(x: 0, y: scrollViewHeight, width: self.view.frame.width, height: self.view.frame.height - scrollViewHeight)
        })
    }
}

extension HMNavigationBarManager: UIScrollViewDelegate {
    
   
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offsetDelta = self.lastScrollingOffsetY - scrollView.contentOffset.y
        let offsetStart = -scrollView.contentInset.top
        let offsetEnd = floor(scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom - 0.5)
        let isBouncingTop = scrollView.contentOffset.y < 0 && self.navBar?.frame.height != self.navBarHeight ? true : false
        
        if self.lastScrollingOffsetY < offsetStart {
            offsetDelta = min(0, offsetDelta - (self.lastScrollingOffsetY - offsetStart))
        }
        
        if self.lastScrollingOffsetY > offsetEnd && offsetDelta < 0 {
            offsetDelta = max(0, offsetDelta - self.lastScrollingOffsetY + offsetEnd)
        }
        
        if(offsetEnd < self.navBarHeight!) {
            return
        }
        var scrollingHeight = (self.navBar?.frame.height)! + offsetDelta
        
        if self.lastScrollingOffsetY <= offsetEnd && offsetDelta < 0 && (self.navBar?.frame.height)! > 0 as CGFloat {
            scrollingHeight = max(scrollingHeight, 0)
            let scrollViewHeight = scrollingHeight > self.statusBarHeight ? scrollingHeight : self.statusBarHeight
            self.animateNavBarWithParams(scrollingHeight: scrollingHeight, scrollViewHeight: scrollViewHeight)
            
        } else if !isBouncingTop && self.lastScrollingOffsetY  >= offsetStart && self.lastScrollingOffsetY <= offsetEnd && offsetDelta > 0 && (self.navBar?.frame.height)! < self.navBarHeight! {
            if(self.startDraggingOffsetY == 0 || scrollView.contentOffset.y < self.startDraggingOffsetY - 250) {
                scrollingHeight = min(scrollingHeight, self.navBarHeight!)
                let scrollViewHeight = max(scrollingHeight, self.statusBarHeight)
                self.animateNavBarWithParams(scrollingHeight: scrollingHeight, scrollViewHeight: scrollViewHeight)
            }
        } else if isBouncingTop && self.navBar?.frame.height != self.navBarHeight {
            self.animateShowingNavBar()
        }
        self.lastScrollingOffsetY = scrollView.contentOffset.y
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.startDraggingOffsetY = scrollView.contentOffset.y
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetEnd = floor(scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom - 0.5)
        
        if(!decelerate || scrollView.contentOffset.y > offsetEnd) {
            let heightPercentage = (self.navBar?.frame.height)! / self.navBarHeight!
            if heightPercentage > 0.6 {
                self.animateShowingNavBar()
            } else {
                self.animateHidingNavBar()
            }
        }
        self.startDraggingOffsetY = 0
    }

}

extension HMNavigationBarManager: HMManagerSetup {
    public func setupManager(scrollView: UIScrollView, navBar: UIView) {
        self.scrollView = scrollView
        self.navBar = navBar
        self.navBarHeight = self.navBar?.frame.height
        self.scrollView?.delegate = self
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: OperationQueue.main, using: { _ in
            UIView.animate(withDuration: 0.0, animations: {
                self.navBar?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: (self.navBar?.frame.height)!)
                self.navBar?.alpha = (self.navBar?.frame.height)! / self.navBarHeight!
            })
        })
    }
}
