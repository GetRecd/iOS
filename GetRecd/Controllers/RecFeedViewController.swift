//
//  RecFeedViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/26/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class RecFeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var currentUser: User?
    var refresher: UIRefreshControl!
    
    @IBOutlet weak var recFeedTableView: UITableView!
    
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var movies = [Movie]() {
        didSet {
            DispatchQueue.main.async {
                self.recFeedTableView.reloadData()
            }
        }
    }
    
    var shows = [Show]() {
        didSet {
            DispatchQueue.main.async {
                self.recFeedTableView.reloadData()
            }
        }
    }
    
    var songs = [Song]() {
        didSet {
            DispatchQueue.main.async {
                self.recFeedTableView.reloadData()
            }
        }
    }
    
    var likedAppleMusicSongs = Set<String>()
    var likedSpotifySongs = Set<String>()
    var likedMovies = Set<Int>()
    var likedTVShows = Set<Int>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        likeButton.isHidden = true
        
        getCurrentUser()
        
        getMovies()
        
        recFeedTableView.delegate = self
        recFeedTableView.dataSource = self
        
        refresher = UIRefreshControl()
        recFeedTableView.addSubview(refresher)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getCurrentUser()
    }
    
    func getCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DataService.instance.getUser(userID: uid) { (user) in
            self.currentUser = user
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch  segmentedControl.selectedSegmentIndex {
        case 0:
            return songs.count
        case 1:
            return movies.count
        case 2:
            return shows.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segmentedControl.selectedSegmentIndex {
            case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
            
            // Reset the cell from previous use:
            cell.artistLabel.text = ""
            cell.artworkView.image = UIImage()
            cell.nameLabel.text = ""
            
            cell.tag = indexPath.row
            cell.artworkView.tag = indexPath.row
            let song = songs[indexPath.row]
            cell.song = song
            return cell
            case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
            
            // Reset the cell from previous use:
            cell.releaseLabel.text = ""
            cell.nameLabel.text = ""
            cell.artworkView.image = UIImage()
            
            cell.tag = indexPath.row
            cell.artworkView.tag = indexPath.row
            let movie = movies[indexPath.row]
            cell.movie = movie
            return cell
            case 2:
            // Note: we're using a movie cell as a tv show cell as well for efficiency 😄
            let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
            
            // Reset the cell from previous use:
            cell.releaseLabel.text = ""
            cell.nameLabel.text = ""
            cell.artworkView.image = UIImage()
            
            cell.tag = indexPath.row
            cell.artworkView.tag = indexPath.row
            let show = shows[indexPath.row]
            cell.show = show
            return cell
            default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if let cell = tableView.cellForRow(at: indexPath) as? SongCell {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    switch cell.song.type {
                    case .AppleMusic:
                        likedAppleMusicSongs.remove(cell.song.id)
                    case .Spotify:
                        likedSpotifySongs.remove(cell.song.id)
                    default:
                        break
                    }
                } else {
                    cell.accessoryType = .checkmark
                    switch cell.song.type {
                    case .AppleMusic:
                        likedAppleMusicSongs.insert(cell.song.id)
                    case .Spotify:
                        likedSpotifySongs.insert(cell.song.id)
                    default:
                        break
                    }
                }
            }
            
            if likedAppleMusicSongs.count > 0 || likedSpotifySongs.count > 0 {
                likeButton.isHidden = false
            } else {
                likeButton.isHidden = true
            }
            tableView.deselectRow(at: indexPath, animated: true)
        case 1:
            if let cell = tableView.cellForRow(at: indexPath) as? MovieCell {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    likedMovies.remove(cell.movie.id)
                } else {
                    cell.accessoryType = .checkmark
                    likedMovies.insert(cell.movie.id)
                }
            }
            
            if likedMovies.count > 0 {
                likeButton.isHidden = false
            } else {
                likeButton.isHidden = true
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        case 2:
            if let cell = tableView.cellForRow(at: indexPath) as? MovieCell {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    likedTVShows.remove(cell.show.id)
                } else {
                    cell.accessoryType = .checkmark
                    likedTVShows.insert(cell.show.id)
                }
            }
            
            if likedTVShows.count > 0 {
                likeButton.isHidden = false
            } else {
                likeButton.isHidden = true
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    @IBAction func didSelectSegment(_ sender: Any) {
        DispatchQueue.main.async {
            self.recFeedTableView.reloadData()
        }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            refresher.addTarget(self, action: #selector(self.getSongs), for: UIControlEvents.valueChanged)
        case 1:
            refresher.addTarget(self, action: #selector(self.getMovies), for: UIControlEvents.valueChanged)
        case 2:
            refresher.addTarget(self, action: #selector(self.getShows), for: UIControlEvents.valueChanged)
        default:
            recFeedTableView.reloadData()
        }
    }
    
    @IBAction func onAdd(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            DataService.instance.likeSongs(appleMusicSongs: likedAppleMusicSongs, spotifySongs: likedSpotifySongs, success: {
            })
        case 1:
            DataService.instance.likeMovies(movies: likedMovies, success: {
            })
        case 2:
            DataService.instance.likeShows(shows: likedTVShows, success: {
            })
        default:
            break
        }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @objc func getMovies() {
        DataService.instance.getLikedMovies { (likedMovies) in
            self.movies = []
            
            for cell in self.recFeedTableView.visibleCells {
                cell.accessoryType = .none
                self.likeButton.isHidden = true
            }
            
            // add top 5 recommended movies if they have less than 5 saved movies, else add top 2 if less than 10, else top 1
            // Checks to make sure that reccomended movies aren't shown more than once and that user has not already liked them
            
            for id in likedMovies {
                MovieService.sharedInstance.getRecommendedMovies(id: id, success: { (movies) in
                    for i in 0...movies.count-1 {
                        
                        let movieArrcontains = self.movies.contains(where: { (movie) -> Bool in
                            return movie.id == movies[i].id
                        })
                        
                        let likedArrContains = likedMovies.contains(where: { (id) -> Bool in
                            return Int(id) == movies[i].id
                        })
                        
                        if !movieArrcontains && !likedArrContains {
                            self.movies.append(movies[i])
                        }
                        
                        if likedMovies.count < 5, self.movies.count == 5 {
                                break
                        } else if likedMovies.count < 10, self.movies.count == 2 {
                                break
                        } else if self.movies.count == 1 {
                            break
                        }
                    }
                })
            }
            
            self.refresher.endRefreshing()
        }
    }
    
    // TODO
    @objc func getSongs() {
        
    }
    
    // TODO
    @objc func getShows() {
        
    }
}
