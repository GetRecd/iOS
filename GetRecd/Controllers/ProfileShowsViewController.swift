//
//  ProfileShowsViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth
import WebKit

class ProfileShowsViewController: UITableViewController {
    var showIds = [(String)]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    let blurEffectView = UIVisualEffectView(effect: nil)
    
    
    var videoView = WKWebView()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.navigationItem.hidesBackButton = true
        let saveButton = UIButton(type: .custom)
        saveButton.frame = CGRect(x: 0.0, y: 0.0, width: 35, height: 35)
        saveButton.setImage(UIImage(named:"save-button"), for: .normal)
        saveButton.addTarget(self, action: #selector(onCheck(_:)), for: .touchUpInside)
        
        let navBarItem = UIBarButtonItem(customView: saveButton)
        let currWidth = navBarItem.customView?.widthAnchor.constraint(equalToConstant: 24)
        currWidth?.isActive = true
        let currHeight = navBarItem.customView?.heightAnchor.constraint(equalToConstant: 24)
        currHeight?.isActive = true
        self.navigationItem.rightBarButtonItem = navBarItem
        
        blurEffectView.isUserInteractionEnabled = true
        blurEffectView.effect = UIBlurEffect(style: .dark)
        //always fill the view
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.blurEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimissTrailer)))
        
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(userScript)
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        wkWebConfig.requiresUserActionForMediaPlayback = false
        
        videoView = WKWebView(frame: CGRect(x: 8, y: (self.view.frame.height / 2) - ((self.view.frame.width - 16) * (9 / 32)), width: self.view.frame.width - 16, height: (self.view.frame.width - 16) * (9 / 16)), configuration: wkWebConfig)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DataService.sharedInstance.getLikedShows(uid: Auth.auth().currentUser!.uid, sucesss: { (showIds) in
            self.showIds = showIds
        }) { (error) in
            // TODO: Show error that liked shows not appearing
            print(error.localizedDescription)
        }
        
    }

    @IBAction func onCheck(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return showIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

        let show = showIds[indexPath.row]
        cell.artworkView.tag = indexPath.row
        cell.artworkView.isUserInteractionEnabled = true
        cell.artworkView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTrailer(_:))))
        TVService.sharedInstance.getShow(with: show) { (show) in
            cell.show = show
        }

        return cell
    }
    @objc func dimissTrailer() {
        
        videoView.removeFromSuperview()
        blurEffectView.removeFromSuperview()
        
        
    }
    @objc func showTrailer(_ sender: Any) {
        let tap = sender as! UITapGestureRecognizer
        let artworkView = tap.view!
        
        let movieId = showIds[artworkView.tag]
        MovieService.sharedInstance.getShowVideo(id: Int(movieId)!, width: Int(view.frame.width - 16), height: Int((view.frame.width - 16) * (9 / 16)), success: { (htm) in
            
            
            DispatchQueue.main.async {
                
                
                self.blurEffectView.frame = self.view.bounds
                self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                self.view.addSubview(self.blurEffectView) //if you have more UIViews, use an insertSubview
                
                self.videoView.loadHTMLString(htm, baseURL: nil)
                
                self.view.addSubview(self.videoView)
            }
        }) {
            print("Error loading video")
        }
    }
}
