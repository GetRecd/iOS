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
    /** The `DataService` singleton. */
    static let instance = DataService()

    // Firebase Database references.
    private var _REF_USERS = Database.database().reference().child("Users")
    private var _REF_USERS_LIKES = Database.database().reference().child("UsersLikes")
    private var _REF_USERS_FRIENDS = Database.database().reference().child("UsersFriends")
    private var _REF_USERS_SPOTIFY_PLAYLISTS = Database.database().reference().child("UsersSpotifyPlaylists")

    // Firebase Storage references.
    private var _REF_PROFILE_PICS = Storage.storage().reference().child("profile-pics")
    
    var REF_PROFILE_PICS: StorageReference {
        return _REF_PROFILE_PICS
    }

    /**
     * Updates a user's entry in the Firebase database, creating one if absent.
     *
     * - parameter uid: The user's unique ID.
     * - parameter userData: A dictionary of user data.
     */
    func createOrUpdateUser(uid: String, userData: [String:Any]) {
        _REF_USERS.child(uid).updateChildValues(userData)
    }
    
    /**
     * Retrieves a user entry matching the given user ID.
     *
     * - parameter uid: The (unique) user ID.
     * - parameter handler: The handler that will be invoked upon a successful `User` retrieval.
     */
    func getUser(uid: String,  handler: @escaping (_ user: User) -> ()) {
        _REF_USERS.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDict = snapshot.value as? [String:Any] else {
                print("Failed retrieving a user.")
                return
            }
            
            handler(User(userDict: userDict, userID: snapshot.key))
            return
        }) { (error) in
            print("Failure retrieving a user: \(error.localizedDescription)")
            return
        }
    }
    
    /**
      * Retrieves a user's profile picture.
      *
      * - parameter user: The user whose photo is to be retrieved.
      * - parameter handler: The handler that will be invoked upon a successful `UIImage` retrieval.
      */
    func getProfilePicture(user: User, handler: @escaping (_ image: UIImage) -> ()) {
        guard let url = URL(string: user.profilePictureURL) else {
            return
        }
        
        let session = URLSession(configuration: .default)
        let getImageFromUrl = session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print("Error downloading image: \(String(describing: error))")
            } else {
                guard let _ = response as? HTTPURLResponse else {
                    print("No response from server.")
                    return
                }
                
                if let imageData = data {
                    guard let image = UIImage(data: imageData) else {
                        return
                    }
                    
                    handler(image)
                    return
                } else {
                    print("The image file is corrupted.")
                }
            }
        }
        
        getImageFromUrl.resume()
    }
    
    /**
      * Deletes a user from the database.
      *
      * - parameter uid: The (unique) user ID.
      */
    func deleteUser(uid: String) {
        print("Deleting user with UID: \(uid)")
        _REF_USERS.child(uid).removeValue()
    }
    
    /**
     * Returns an array of `User` objects whose names contain `nameSubstring`.
     *
     * - parameter nameSubstring: A substring of a user's name to match.
     */
    func findUsersByName(nameSubstring: String) -> [User] {
        var matchingUsers = [User]()
        _REF_USERS.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            if let userEntries = snapshot.value as? Dictionary<String, AnyObject> {
                for uid in userEntries.keys {
                    self.getUser(uid: uid) { (user) in
                        if user.name.lowercased().contains(nameSubstring.lowercased()) {
                            matchingUsers.append(user)
                        }
                    }
                }
            }
        })
        return matchingUsers
    }

    func setUserSpotifyPlaylist(uid: String, uri: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        _REF_USERS_SPOTIFY_PLAYLISTS.child(uid).child("uri").setValue(uri) { (error, ref) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func getUserSpotifyPlaylist(uid: String, success: @escaping (String) -> (), failure: @escaping (Error)->()) {
        _REF_USERS_SPOTIFY_PLAYLISTS.child(uid).child("uri").observe(.value) { (snapshot) in
            let uri = snapshot.value as! String
            success(uri)
        }
    }
    
    func likeSongs(appleMusicSongs: Set<String>, spotifySongs: Set<String>, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        let currUserAppleMusicLikesRef = currUserLikesRef.child("AppleMusic")
        let currUserSpotifyLikesRef = currUserLikesRef.child("Spotify")
        
        let songGroup = DispatchGroup()
        
        for song in appleMusicSongs {
            songGroup.enter()
            currUserAppleMusicLikesRef.child(song).setValue(true) { (error, reference) in
                if let error = error {
                    failure(error)
                } else {
                    songGroup.leave()
                }
            }
        }
        
        for song in spotifySongs {
            songGroup.enter()
            currUserSpotifyLikesRef.child(song).setValue(true) { (error, reference) in
                if let error = error {
                    failure(error)
                } else {
                    songGroup.leave()
                }
            }
        }
        
        songGroup.notify(queue: DispatchQueue .global()) {
            MusicService.sharedInstance.addToSpotifyPlaylist(songs: spotifySongs, success: {
                success()
            }, failure: { (error) in
                failure(error)
            })
        }
    }
    
    func getLikedSongs(sucesss: @escaping ([(String, Song.SongType)]) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        
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

    func getLikedSpotifySongs(sucesss: @escaping ([String]) -> ()) {
        let currUserSpotfyLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid).child("Spotify")
        
        currUserSpotfyLikesRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }
            
            var result: [String] = []
            
            for (key, _) in data {
                result.append(key)
            }
            
            sucesss(result)
        }
    }
    
    func likeMovies(movies: Set<Int>, success: @escaping () -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        let currentUserMovieLikesRef = currUserLikesRef.child("Movies")

        for movie in movies {
            currentUserMovieLikesRef.child("\(movie)").setValue(true)
        }

        success()
    }

    func getLikedMovies(sucesss: @escaping ([(String)]) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        currUserLikesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }

            var result = [(String)]()

            if let movies = data["Movies"] as? [String: Bool] {
                for (key, _) in movies {
                    result.append((key))
                }
            }

            sucesss(result)
        })
    }

    func likeShows(shows: Set<Int>, success: @escaping () -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        let currentUserShowLikes = currUserLikesRef.child("Shows")

        for show in shows {
            currentUserShowLikes.child("\(show)").setValue(true)
        }

        success()
    }

    func getLikedShows(sucesss: @escaping ([(String)]) -> ()) {
        let currUserLikesRef = _REF_USERS_LIKES.child(Auth.auth().currentUser!.uid)
        currUserLikesRef.observe(.value) { (snapshot) in
            guard let data = snapshot.value as? [String: Any] else {
                return
            }

            var result = [(String)]()

            if let shows = data["Shows"] as? [String: Bool] {
                for (key, _) in shows {
                    result.append((key))
                }
            }

            sucesss(result)
        }
    }
}
