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


//Checkt welke VC open of dicht gaat
enum SlideOutState {
    case collapsed
    case MenuLeftPanelExpanded
}
//Welke VC wil ik laten zien
enum ShowWhichVC {
    case homeVC
}

var showVC: ShowWhichVC = .homeVC

class ContainerVC: UIViewController {
    
    var homeVC: HomeVC!
    var menuLeftPanelVC: MenuLeftPanelVC!
    var centerController: UIViewController!
    var currentState: SlideOutState = .collapsed {
        didSet {
            let shouldShowShadow = (currentState != .collapsed)
            
            souldShowShadowCenterViewController(status: shouldShowShadow)
        }
    }
    
    var isHidden = false
    let centerPanelExpandedOffset: CGFloat = 130
    
    var tap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC)
    }
    
    //initialze VC tot de centrum van het scherm
    func initCenter(screen: ShowWhichVC) {
        var presentingController: UIViewController
        
        showVC = screen
        
        if homeVC == nil {
            homeVC = UIStoryboard.homeViewController()
            homeVC.delegate = self
        }
        
        presentingController = homeVC
        
        //verwijdert alles in de centercontroller voordat we naar een nieuwe VC gaan zodat we niet zoveel geheugen gebruiken
        if let con = centerController {
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

extension ContainerVC: CenterVCDelegate {
    func toggleMenuLeftPanel() {
        let notAlreadyExpanded = (currentState != .MenuLeftPanelExpanded)
        
        if notAlreadyExpanded {
            addMenuLeftPanelViewController()
        }
        animateMenuLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addMenuLeftPanelViewController() {
        if menuLeftPanelVC == nil {
            menuLeftPanelVC = UIStoryboard.menuLeftViewController()
            addChildSidePanelViewController(menuLeftPanelVC!)
        }
    }
    
    func addChildSidePanelViewController(_ sidePanelController: MenuLeftPanelVC) {
        //here we determine the layers for the VCs
        view.insertSubview(sidePanelController.view, at: 0)
        addChild(sidePanelController)
        sidePanelController.didMove(toParent: self)
    }
    
    @objc func animateMenuLeftPanel(shouldExpand: Bool) {
        if shouldExpand {
            isHidden = !isHidden
            animateStatusBar()
            
            setupWhiteCoverView()
            currentState = .MenuLeftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffset)
        } else {
            isHidden = !isHidden
            animateStatusBar()
            
            hideWhiteCoverView()
            animateCenterPanelXPosition(targetPosition: 0, completion:  { (finished) in
                if finished == true {
                    self.currentState = .collapsed
                    self.menuLeftPanelVC = nil
                }
            })
        }
    }
    
    //hier schuift de menu panel
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
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
        for subview in self.centerController.view.subviews {
            if subview.tag == 22 {
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }, completion: {(finished) in
                    subview.removeFromSuperview()
                })
            }
        }
    }
    
    func souldShowShadowCenterViewController(status: Bool){
        if status == true {
            centerController.view.layer.shadowOpacity = 0.2
        } else {
            centerController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
}

private extension UIStoryboard{
    // Access to storyboard
    class func mainStoryboard() -> UIStoryboard{
         return UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
    }
    
    //Instanstiate MenuLeftPanelVC
    class func menuLeftViewController() -> MenuLeftPanelVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: VC_MENU_LINKS_PANEL) as? MenuLeftPanelVC
    }
    
    class func homeViewController() -> HomeVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: VC_HOME) as? HomeVC
    }
}
