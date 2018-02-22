//
//  MusicService.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/20/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer

class MusicService {
    
    static let sharedInstance = MusicService()
    let applicationMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    func requestAppleMusicPermission(success: @escaping (SKCloudServiceAuthorizationStatus) -> ()) {
        
        SKCloudServiceController.requestAuthorization { (status: SKCloudServiceAuthorizationStatus) in
            success(status)
        }
        
    }
    
    func getAppleMusicRegionCode() {
        let serviceController = SKCloudServiceController()
        serviceController.requestStorefrontIdentifier { (storefrontId, error) in
            
            guard error == nil else {
                
                print("An error occured. Handle it here.")
                return
                
            }
            
            guard let storefrontId = storefrontId, storefrontId.characters.count >= 6 else {
                
                print("Handle the error - the callback didn't contain a valid storefrontID.")
                return
                
            }
            
            let startIndex = storefrontId.startIndex
            let endIndex = storefrontId.index(storefrontId.startIndex, offsetBy: 5)
            let trimmedId = storefrontId[startIndex...endIndex]
            
            print("Success! The user's storefront ID is: \(trimmedId)")
            
        }
    }
}
