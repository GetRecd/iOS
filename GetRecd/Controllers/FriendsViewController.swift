//
//  FriendsViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/29/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var searchController = UISearchController(searchResultsController: nil)
    var timerToQuery: Timer?
    var searchString = ""
    
    /// A `DispatchQueue` used for synchornizing the setting of `friends` to avoid threading issues with various `UITableView` delegate callbacks.
    var setterQueue = DispatchQueue(label: "SearchViewController")
    
    var friends = [User]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var findFriends = [User]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var requests = [User]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var addedFriends = Set<String>()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        addButton.isHidden = true
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        self.definesPresentationContext = true
        self.navigationItem.searchController = searchController
        view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.becomeFirstResponder()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return friends.count
        case 1:
            return findFriends.count
        case 2:
            return requests.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as? FriendCell else { return FriendCell() }
        
        var arr:[User] = []
        // Configure the cell...
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            arr = friends
        case 1:
            arr = findFriends
        case 2:
            arr = requests
        default:
            arr = []
        }
        
        cell.configureCell(user: arr[indexPath.row])
        
        return cell
    }
    
    @IBAction func didChangeSegment(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            addButton.isHidden = true
            searchController.searchBar.isHidden = false
        case 1:
            addButton.isHidden = false
            searchController.searchBar.isHidden = false
        case 2:
            searchController.searchBar.isHidden = true
            addButton.isHidden = true
        default:
            addButton.isHidden = true
            searchController.searchBar.isHidden = false
        }
    }
}

extension FriendsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        
        self.searchString = searchString
        
        // Check if user is still actively typing... if so, delay the call by one second:
        if let timer = timerToQuery {
            timer.invalidate()
        }
        
        timerToQuery = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.queryForSearch), userInfo: nil, repeats: false)
    }
    
    // The following functions are called after 1 second delay of user typing
    
    
    @objc func queryForSearch() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if searchString == "" {
                self.setterQueue.sync {
                    self.friends = []
                }
            } else {
                // Get friends from DataService and set friends array to results using searchString
            }
        case 1:
            if searchString == "" {
                self.setterQueue.sync {
                    self.findFriends = []
                }
            } else {
               // Search all users using searchString and set searchResults array
            }
        default:
            break
        }
    }
}

extension FriendsViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.friends = []
        self.findFriends = []
        self.addButton.isHidden = true
    }
}
