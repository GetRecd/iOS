//
//  FriendCell.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/29/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(user: User) {
        DataService.instance.getUser(uid: user.userID) { (user) in
            self.nameLabel.text = user.name
        }
        
        DataService.instance.getProfilePicture(user: user) { (image) in
            self.profilePic.image = image
        }
    }

}
