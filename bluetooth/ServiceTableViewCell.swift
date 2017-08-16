//
//  ServiceTableViewCell.swift
//  bluetooth
//
//  Created by Ewa Korszaczuk on 16.08.2017.
//  Copyright © 2017 Ewa Korszaczuk. All rights reserved.
//

import UIKit

class ServiceTableViewCell: UITableViewCell {

    @IBOutlet var serviceCharacteristicsButton: UIButton!
    @IBOutlet var serviceNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        serviceNameLabel.text = "name"
        // Initialization code
    }
    @IBAction func characteristicsButtonPressed(_ sender: Any) {
    }
}
