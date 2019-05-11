//
//  ContainerVC.swift
//  erkeb
//
//  Created by Ismail on 27/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
// library that provides the Api for core animation: slide menu etc
import QuartzCore


//Check which VC open or collapsed
enum SlideOutState {
    case collapsed
    case MenuLeftPanelExpanded
}
//Which VC I want to show
enum ShowWhichVC {
    case homeVC
}

var showVC: ShowWhichVC = .homeVC

class ContainerVC: UIViewController {
    
    var homeVC: HomeVC!
    var menuLeftPanelVC: MenuLeftPanelVC!
    var centerController: UIViewController!
    var currentState: SlideOutState = .collapsed{
        didSet{
            let shouldShowShadow = (currentState != .collapsed)
            
            couldShowShadowCenterViewController(status: shouldShowShadow)
        }
    }
    
    var isHidden = false
    let centerPanelExpandedOffset: CGFloat = 130
    
    var tap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC)

        // Do any additional setup after loading the view.
    }
    
    //initialze VC to the center of the screen
    func initCenter(screen: ShowWhichVC){
        var presentingController: UIViewController
        showVC = screen
        
        if homeVC == nil{
            homeVC = UIStoryboard.homeViewController()
            homeVC.delegate = self
        }
        presentingController = homeVC
        
        //removing everything in the centercontroller before passing new VC so we not use a lot of memory
        if let con = centerController{
            con.view.removeFromSuperview()
            con.removeFromParent()
        }
        centerController = presentingController
        view.addSubview(centerController.view)
        addChild(centerController)
        centerController.didMove(toParent: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return isHidden
    }
}

extension ContainerVC: CenterVCDelegate{
    func toggleMenuLeftPanel() {
        let notAlreadyExpanded = (currentState != .MenuLeftPanelExpanded)
        
        if notAlreadyExpanded{
            addMenuLeftPanelViewController()
        }
        animateMenuLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addMenuLeftPanelViewController() {
        if menuLeftPanelVC == nil{
            menuLeftPanelVC = UIStoryboard.menuLeftViewController()
            addChildSidePanelViewController(menuLeftPanelVC!)
        }
    }
    
    func addChildSidePanelViewController(_ sidePanelController: MenuLeftPanelVC){
        //here we determine the layers for the VCs
        view.insertSubview(sidePanelController.view, at: 0)
        addChild(sidePanelController)
        sidePanelController.didMove(toParent: self)
    }
    
    @objc func animateMenuLeftPanel(shouldExpand: Bool) {
        if shouldExpand{
            isHidden = !isHidden
            animateStatusBar()
            
            setupWhiteCoverView()
            currentState = .MenuLeftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffset)
        } else {
            isHidden = !isHidden
            animateStatusBar()
            
            hideWhiteCoverView()
            animateCenterPanelXPosition(targetPosition: 0) { (finished) in
                if finished == true {
                    self.currentState = .collapsed
                    self.menuLeftPanelVC = nil
                }
            }
        }
    }
    
    //would slide the menu panel
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func setupWhiteCoverView() {
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 22
        
        self.centerController.view.addSubview(whiteCoverView)
        whiteCoverView.fadeTo(alphaValue: 0.2, withDuration: 0.2)
       
        tap = UITapGestureRecognizer(target: self, action: #selector(animateMenuLeftPanel(shouldExpand:)))
        tap.numberOfTapsRequired = 1
        
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func hideWhiteCoverView(){
        centerController.view.removeGestureRecognizer(tap)
        for subview in self.centerController.view.subviews{
            if subview.tag == 22 {
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }, completion: {(finished) in
                    subview.removeFromSuperview()
                })
            }
        }
    }
    
    func couldShowShadowCenterViewController(status: Bool){
        if status == true {
            centerController.view.layer.shadowOpacity = 0.2
        } else {
            centerController.view.layer.shadowOpacity = 0.0
        }
        
    }
    
    func animateStatusBar(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
}

private extension UIStoryboard{
    // Access to storyboard
    class func mainStoryboard() -> UIStoryboard{
         return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    //Instanstiate MenuLeftPanelVC
    class func menuLeftViewController() -> MenuLeftPanelVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: "MenuLeftPanelVC") as? MenuLeftPanelVC
    }
    
    class func homeViewController() -> HomeVC?{
        return mainStoryboard().instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
    }
}
