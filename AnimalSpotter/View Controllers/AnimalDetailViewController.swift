//
//  AnimalDetailViewController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 10/31/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

class AnimalDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var apiController: APIController?
    var animalName: String?
    
    @IBOutlet weak var timeSeenLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var animalImageView: UIImageView!
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        getDetails()
    }
    
    private func getDetails() {
        guard let animalName = animalName else { return }
        
        // MARK: - call api controller's fetch details
        apiController?.fetchDetails(for: animalName, completion: { result in
            if let animal = try? result.get() {
                DispatchQueue.main.async {
                    self.updateViews(with: animal)
                }
                // MARK: - fetch the image
                self.apiController?.fetchImage(at: animal.imageURL, completion: { result in
                    if let image = try? result.get() {
                        DispatchQueue.main.async {
                            self.animalImageView.image = image
                        }
                    }
                })
            }
        })
    }
    
    private func updateViews(with animal: Animal) {
        title = animal.name
        descriptionLabel.text = animal.description
        coordinatesLabel.text = "lat: \(animal.latitude), long: \(animal.longitude)"
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        timeSeenLabel.text = df.string(from: animal.timeSeen)
    }
}
