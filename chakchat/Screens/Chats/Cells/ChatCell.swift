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
    private let messageLabel: UILabel = UILabel()
    private let uncheckCircleView: UIView = UIView()
    private let messageAmountLabel: UILabel = UILabel()
    private let dateLabel: UILabel = UILabel()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    func configure(_ image: URL?, _ name: String, _ message: String, _ uncheckAmount: Int, _ date: Date) {
        self.nicknameLabel.text = name
        update(message: message, messagesAmount: uncheckAmount, date: date)
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
        configureMessage()
        configureUncheck()
        configureMessageAmountLabel()
        configureDateLabel()
    }
    
    func update(message: String, messagesAmount: Int, date: Date) {
        messageLabel.text = message
        dateLabel.text = formatDate(date)
        if messagesAmount < 1 {
            uncheckCircleView.isHidden = true
            messageAmountLabel.isHidden = true
        } else {
            uncheckCircleView.isHidden = false
            messageAmountLabel.isHidden = false
            messageAmountLabel.text = String(messagesAmount)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        let dateFormatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else {
            dateFormatter.dateFormat = "dd.MM.yyyy"
        }
        
        return dateFormatter.string(from: date)
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
        nicknameLabel.pinTop(contentView, 16)
        nicknameLabel.pinLeft(iconImageView.trailingAnchor, 10)
    }
    
    private func configureMessage() {
        contentView.addSubview(messageLabel)
        messageLabel.font =  Fonts.systemR16
        messageLabel.textColor = .gray
        messageLabel.pinBottom(contentView, 16)
        messageLabel.pinLeft(iconImageView.trailingAnchor, 10)
    }
    
    private func configureUncheck() {
        uncheckCircleView.setHeight(20)
        uncheckCircleView.setWidth(20)
        uncheckCircleView.layer.cornerRadius = 10
        uncheckCircleView.backgroundColor = .systemBlue
        uncheckCircleView.clipsToBounds = true
        contentView.addSubview(uncheckCircleView)
        uncheckCircleView.pinRight(contentView, 5)
        uncheckCircleView.pinBottom(contentView, 16)
    }
    
    private func configureMessageAmountLabel() {
        messageAmountLabel.textColor = .white
        messageAmountLabel.font = Fonts.systemR16
        messageAmountLabel.textAlignment = .center
        uncheckCircleView.addSubview(messageAmountLabel)
        messageAmountLabel.pinTop(uncheckCircleView.topAnchor, 0)
        messageAmountLabel.pinLeft(uncheckCircleView.leadingAnchor, 0)
        messageAmountLabel.pinRight(uncheckCircleView.trailingAnchor, 0)
        messageAmountLabel.pinBottom(uncheckCircleView.bottomAnchor, 0)
    }
    
    private func configureDateLabel() {
        contentView.addSubview(dateLabel)
        dateLabel.font =  Fonts.systemR16
        dateLabel.textColor = .gray
        dateLabel.pinTop(contentView, 16)
        dateLabel.pinRight(contentView, 5)
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
