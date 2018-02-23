//
//  DataService.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/3/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class DataService {
    // Static instance variable used to call DataService functions
    static let instance = DataService()
    private var _REF_USERS = Database.database().reference().child("Users")
    private var _REF_USERLIKES = Database.database().reference().child("UsersLikes")

    // Firebase Storage reference (TODO: Need to create storage)
    private var _REF_PROFILE_PICS = Storage.storage().reference().child("profile-pics")
    
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    
    var REF_PROFILE_PICS: StorageReference {
        return _REF_PROFILE_PICS
    }
    
    // Adds/updates user's entry in the Firebase database
    func createOrUpdateUser(uid: String, userData: [String:Any]) {
        REF_USERS.child(uid).updateChildValues(userData)
    }
    
    // Retrives user based on userID/user's key in Firebase
    func getUser(userID: String,  handler: @escaping (_ user: User) -> ()) {
        DataService.instance.REF_USERS.child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            guard let userDict = snapshot.value as? [String:Any] else {
                print("ERROR GETTING USER DICT")
                return
            }
            
            let user = User(userDict: userDict, userID: snapshot.key)
            handler(user)
            return
        }) { (error) in
            print("ERROR \(error.localizedDescription)")
            return
        }
    }
    
    // Gets a user's profile picture from Firebase Storage
    func getProfilePicture(user: User, handler: @escaping (_ image: UIImage) -> ()) {
        guard let url = URL(string: user.profilePictureURL) else {
            return
        }
        
        let session = URLSession(configuration: .default)
        
        //creating a dataTask to get profile picture
        let getImageFromUrl = session.dataTask(with: url) { (data, response, error) in
            
            if error != nil {
                //displaying the message
                print("Error downloading image: \(String(describing: error))")
            } else {
                guard let _ = response as? HTTPURLResponse else {
                    print("No response from server")
                    return
                }
                
                if let imageData = data {
                    guard let image = UIImage(data: imageData) else {
                        return
                    }
                    
                    handler(image)
                    return
                } else {
                    print("Image file is corrupted")
                }
            }
        }
        
        getImageFromUrl.resume()
    }
    
    func deleteUser(uid: String) {
        print("DELETING USER: \(uid)")
        REF_USERS.child(uid).removeValue()
    }
    
    
    func likeSongs(appleMusicSongs: Set<String>, spotifySongs: Set<String>, success: @escaping () -> ()) {
        let currUserLikesRef = _REF_USERLIKES.child(Auth.auth().currentUser!.uid)
        let currUserAppleMusicLikesRef = currUserLikesRef.child("AppleMusic")
        let currUserSpotifyLikesRef = currUserLikesRef.child("Spotify")
        
        for song in appleMusicSongs {
            currUserAppleMusicLikesRef.child(song).setValue(true)
        }
        
        for song in spotifySongs {
            currUserSpotifyLikesRef.child(song).setValue(true)
        }
        
        success()
    }
    
    func getLikedSongs(sucesss: @escaping ([(String, Song.SongType)]) -> ()) {
        let currUserLikesRef = _REF_USERLIKES.child(Auth.auth().currentUser!.uid)
        
        currUserLikesRef.observe(.value) { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }
            
            var result = [(String, Song.SongType)]()
            if let appleMusicList = data["AppleMusic"] as? [String: Bool] {
                for (key, _) in appleMusicList {
                    result.append((key, Song.SongType.AppleMusic))
                }
            }
            
            if let spotifyMusicList = data["Spotify"] as? [String: Bool] {
                for (key, _) in spotifyMusicList {
                    result.append((key, Song.SongType.Spotify))
                }
            }
            
            sucesss(result)
        }
    }
}
