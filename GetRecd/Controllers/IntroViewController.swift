//
//  IntroViewController.swift
//  Get Recd
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Pastel
import LTMorphingLabel

class IntroViewController: UIViewController, LTMorphingLabelDelegate {

    @IBOutlet weak var mediaLabel: LTMorphingLabel!

    let mediaTypes = ["song", "artist", "movie", "tv show", "album"]
    var mediaCount = -1
    override func viewDidLoad() {
        super.viewDidLoad()

        mediaLabel.text = ""
        mediaLabel.delegate = self
        mediaLabel.morphingEffect = .evaporate

        if let gradientView = view as? PastelView {
            gradientView.startPastelPoint = .topRight
            gradientView.endPastelPoint = .bottomLeft

            gradientView.setColors([UIColor(red:0.35, green:0.28, blue:0.98, alpha:1.0),
                                    UIColor(red:0.78, green:0.43, blue:0.84, alpha:1.0),
                                    UIColor(red:0.19, green:0.14, blue:0.68, alpha:1.0)])

            gradientView.startAnimation()
        }

        let mediaLabelTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(mediaLabelAnimation), userInfo: nil, repeats: true)
        mediaLabelTimer.fire()

    }

    @objc func mediaLabelAnimation() {
        if mediaCount == mediaTypes.count - 1 {
            mediaCount = -1
        }

        mediaCount += 1

        //UIView.animate(withDuration: 0.5) {
        mediaLabel.text = mediaTypes[self.mediaCount]
            //self.mediaLabel.text = self.mediaTypes[self.mediaCount]
        //}

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    func morphingDidStart(_ label: LTMorphingLabel) {

    }

    func morphingDidComplete(_ label: LTMorphingLabel) {

    }

    func morphingOnProgress(_ label: LTMorphingLabel, progress: Float) {

    }
}

