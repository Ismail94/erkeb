//
//  UpdateService.swift
//  erkeb
//
//  Created by Ismail on 04/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Firebase

class UpdateService {
    static var instance = UpdateService()
    //hier wordt de locatie van de passagier upgedated naar gelang zijn locatie doormiddel van de coordinaat
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        DataService.instance.REF_USERS.child(user.key).updateChildValues([COORDINAAT : [coordinate.latitude, coordinate.longitude]])
                    }
                }
            }
        })
    }
    //hier wordt de locatie van de passagier upgedated naar gelang zijn locatie doormiddel van de coordinaat
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot {
                    if driver.key == Auth.auth().currentUser?.uid{
                        if driver.childSnapshot(forPath: ACCOUNT_PICKUP_MODUS_AAN).value as? Bool == true {
                            DataService.instance.REF_DRIVERS.child(driver.key).updateChildValues([COORDINAAT : [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            }
        })
    }
    
    func observeTrips(handler: @escaping(_ coordinateDict: Dictionary<String, AnyObject>?) -> Void){
        DataService.instance.REF_TRIPS.observe(.value, with:  { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for trip in tripSnapshot{
                    if trip.hasChild(GEBRUIKER_PASSAGIER_KEY) && trip.hasChild(RIT_IS_AANVAARD){
                        if let tripDict = trip.value as? Dictionary<String, AnyObject>{
                            handler(tripDict)
                        }
                    }
                }
            }
        })
    }
    
    //via dit functie gaat de passagier een rit kunnen annvragen en doorsturen naar de bestuurder
    func updateTripsWithCoordinatesUponRequest(){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in userSnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        if !user.hasChild(GEBRUIKER_IS_BESTUURDER){
                            if let userDict = user.value as? Dictionary<String, AnyObject>{
                                let pickupArray = userDict[COORDINAAT] as! NSArray
                                let destinationArray = userDict[RIT_COORDINAAT] as! NSArray
                                
                                DataService.instance.REF_TRIPS.child(user.key).updateChildValues([GEBRUIKER_PICKUP_COORDINAAT: [pickupArray[0], pickupArray[1]], GEBRUIKER_BESTEMMING_CORDINAAT: [destinationArray[0], destinationArray[1]], GEBRUIKER_PASSAGIER_KEY: user.key, RIT_IS_AANVAARD: false ])
                            }
                        }
                    }
                }
            }
        })
    }

    //hier aanvaard de bestuurder de rit aan van de passagier
    func driverAcceptTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String){
        DataService.instance.REF_TRIPS.child(passengerKey).updateChildValues([BESTUURDER_KEY: driverKey, RIT_IS_AANVAARD: true])
        DataService.instance.REF_DRIVERS.child(driverKey).updateChildValues([BESTUURDER_IS_OP_RIT: true])
    }
    
    func cancelTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String?){
        DataService.instance.REF_TRIPS.child(passengerKey).removeValue()
        DataService.instance.REF_USERS.child(passengerKey).child(RIT_COORDINAAT).removeValue()
        if driverKey != nil {
            DataService.instance.REF_DRIVERS.child(driverKey!).updateChildValues([BESTUURDER_IS_OP_RIT: false])
        }
    }
}
