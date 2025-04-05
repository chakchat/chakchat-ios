//
//  StartViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation
import UIKit

// MARK: - StartViewController
final class StartViewController: UIViewController {
    
    // MARK: - Properties
    private let image: UIImageView =  {
        let imageView = UIImageView(image: UIImage(named: "LaunchScreen"))
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(image)
        image.pinTop(view, 0)
        image.pinBottom(view, 0)
        image.pinLeft(view, 0)
        image.pinRight(view, 0)
    }
}
