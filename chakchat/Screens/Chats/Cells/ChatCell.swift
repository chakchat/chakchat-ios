//
//  ChatCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.03.2025.
//

import UIKit

final class ChatCell: UITableViewCell {
    
    // MARK: - Constants
    static let cellIdentifier: String = "ChatCell"
    
    private enum Constants {
        static let size: CGFloat = 50
        static let radius: CGFloat = 25
        static let picX: CGFloat = 5
        static let picY: CGFloat = 10
        static let borderWidth: CGFloat = 5
    }
    
    // MARK: - Properties
    private let nicknameLabel: UILabel = UILabel()
    private let iconImageView: UIImageView = UIImageView()
    private let shimmerLayer: ShimmerView = ShimmerView(
        frame: CGRect(
            x: Constants.picX,
            y: Constants.picY,
            width: Constants.size,
            height: Constants.size
        )
    )
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    func configure(_ image: URL?, _ name: String) {
        self.nicknameLabel.text = name
        if let url = image {
            loadImage(from: url)
        } else {
            shimmerLayer.isHidden = true
            let color = UIColor.random()
            let image = UIImage.imageWithText(
                text: LocalizationManager.shared.localizedString(for: name),
                size: CGSize(width: Constants.size, height: Constants.size),
                color: color,
                borderWidth: Constants.borderWidth
            )
            
            self.iconImageView.image = image
        }
    }
    
    func configureCell() {
        configureShimmerView()
        configurePhoto()
        configureName()
    }
    
    private func configureShimmerView() {
        contentView.addSubview(shimmerLayer)
        shimmerLayer.layer.cornerRadius = Constants.radius
        shimmerLayer.startAnimating()
    }
    
    private func configurePhoto() {
        contentView.addSubview(iconImageView)
        iconImageView.layer.cornerRadius = Constants.radius
        iconImageView.layer.masksToBounds = true
        iconImageView.pinCenterY(contentView)
        iconImageView.pinLeft(contentView.leadingAnchor, Constants.picX)
        iconImageView.setWidth(Constants.size)
        iconImageView.setHeight(Constants.size)
    }
    
    private func configureName() {
        contentView.addSubview(nicknameLabel)
        nicknameLabel.font = Fonts.systemR20
        nicknameLabel.textColor = Colors.text
        nicknameLabel.pinCenterY(contentView)
        nicknameLabel.pinLeft(iconImageView.trailingAnchor, 10)
    }
    
    // MARK: - Supporting Methods
    private func loadImage(from imageURL: URL) {
        if let cachedImage = ImageCacheManager.shared.getImage(for: imageURL as NSURL) {
            self.shimmerLayer.isHidden = true
            self.iconImageView.image = cachedImage
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    return
                }
                
                ImageCacheManager.shared.saveImage(image, for: imageURL as NSURL)
                
                DispatchQueue.main.async {
                    self?.shimmerLayer.isHidden = true
                    self?.iconImageView.image = image
                }
            }.resume()
        }
    }
}
