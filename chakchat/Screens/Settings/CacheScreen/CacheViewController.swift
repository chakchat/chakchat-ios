//
//  CacheViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 23.02.2025.
//


import UIKit

class CacheViewController: UIViewController {
    
    private enum Constants {
        static let arrowLabel: String = "arrow.left"
    }
    
    private let cacheInfoLabel = UILabel()
    private let storageInfoLabel = UILabel()
    private let clearCacheButton = UIButton(type: .system)
    private let cacheLimitSlider = UISlider()
    private let cacheLimitLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel: UILabel = UILabel()
    private let stackView = UIStackView()
    private let interactor: CacheBusinessLogic
    
    
    init(interactor: CacheBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureViews()

    }
    
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        configureBackButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configureConstraints()
        setupActions()
        updateCacheInfo()
        loadCurrentCacheLimit()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowLabel), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.font = Fonts.systemB20
        titleLabel.text = LocalizationManager.shared.localizedString(for: "data_and_memory")
        titleLabel.textAlignment = .center
    }
    
    
    private func configureViews() {
 
        configureStackView()
        configureCacheInfoLabel()
        configureStorageInfoLabel()
        configureClearCacheButton()
        configureCacheLimitLabel()
        configureCacheLimitSlider()
        configureActivityIndicator()
    }
    
    private func configureConstraints() {
        view.addSubview(stackView)
        view.addSubview(clearCacheButton)
        view.addSubview(cacheLimitLabel)
        view.addSubview(cacheLimitSlider)
        view.addSubview(activityIndicator)
        
        stackView.pinTop(view.safeAreaLayoutGuide.topAnchor, 20)
        stackView.pinHorizontal(view, 20)
        
        clearCacheButton.pinTop(stackView.bottomAnchor, 30)
        clearCacheButton.pinCenterX(view)
        clearCacheButton.setWidth(200)
        clearCacheButton.setHeight(50)
        
        cacheLimitLabel.pinTop(clearCacheButton.bottomAnchor, 40)
        cacheLimitLabel.pinHorizontal(view, 20)
        
        cacheLimitSlider.pinTop(cacheLimitLabel.bottomAnchor, 10)
        cacheLimitSlider.pinHorizontal(view, 20)
        
        activityIndicator.pinCenter(view)
    }
    
    // MARK: - UI Configuration
    private func configureStackView() {
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.addArrangedSubview(cacheInfoLabel)
        stackView.addArrangedSubview(storageInfoLabel)
    }
    
    private func configureCacheInfoLabel() {
        cacheInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        cacheInfoLabel.textAlignment = .center
        cacheInfoLabel.numberOfLines = 0
        cacheInfoLabel.textColor = .label
    }
    
    private func configureStorageInfoLabel() {
        storageInfoLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        storageInfoLabel.textAlignment = .center
        storageInfoLabel.numberOfLines = 0
        storageInfoLabel.textColor = .secondaryLabel
    }
    
    private func configureClearCacheButton() {
        clearCacheButton.setTitle(LocalizationManager.shared.localizedString(for: "clear_cache"), for: .normal)
        clearCacheButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        clearCacheButton.backgroundColor = .systemRed
        clearCacheButton.tintColor = Colors.backgroundSettings
        clearCacheButton.layer.cornerRadius = 10
    }
    
    private func configureCacheLimitLabel() {
        cacheLimitLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cacheLimitLabel.textAlignment = .center
    }
    
    private func configureCacheLimitSlider() {
        cacheLimitSlider.minimumValue = 10
        cacheLimitSlider.maximumValue = 1000
        let currentLimit = ImageCacheManager.shared.getCurrentCacheLimit()
        cacheLimitSlider.value = Float(currentLimit)
    }
    
    private func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
    }
    
    // MARK: - Cache Management
    private func updateCacheInfo() {
        activityIndicator.startAnimating()
        
        ImageCacheManager.shared.getFormattedCacheInfo { [weak self] info in
            DispatchQueue.main.async {
                self?.cacheInfoLabel.text = info
                self?.activityIndicator.stopAnimating()
            }
        }
        
        updateStorageInfo()
    }
    
    private func updateStorageInfo() {
        guard let storageInfo = ImageCacheManager.shared.getDeviceStorageInfo() else {
            storageInfoLabel.text = LocalizationManager.shared.localizedString(for: "cant_get_info_storage")
            return
        }
        
        let totalGB = String(format: "%.1f", storageInfo.total)
        let freeGB = String(format: "%.1f", storageInfo.free)
        storageInfoLabel.text = "\(LocalizationManager.shared.localizedString(for: "total_memory")) \(totalGB) GB\n\(LocalizationManager.shared.localizedString(for: "free_memory")) \(freeGB) GB"
    }
    
    private func loadCurrentCacheLimit() {
        let currentLimit = ImageCacheManager.shared.getCurrentCacheLimit()
        cacheLimitSlider.value = Float(currentLimit)
        updateCacheLimitLabel(value: currentLimit)
    }
    
    private func updateCacheLimitLabel(value: Int) {
        cacheLimitLabel.text = "\(LocalizationManager.shared.localizedString(for: "cache_limit")) \(value) MB"
    }
    
    // MARK: - Actions
    private func setupActions() {
        clearCacheButton.addTarget(self, action: #selector(clearCacheTapped), for: .touchUpInside)
        cacheLimitSlider.addTarget(self, action: #selector(cacheLimitChanged), for: .valueChanged)
    }
    
    @objc private func clearCacheTapped() {
        let alert = UIAlertController(
            title: LocalizationManager.shared.localizedString(for: "clean_cache"),
            message: LocalizationManager.shared.localizedString(for: "clean_cache_message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: LocalizationManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LocalizationManager.shared.localizedString(for: "clean"), style: .destructive) { [weak self] _ in
            self?.performClearCache()
        })
        
        present(alert, animated: true)
    }
    
    private func performClearCache() {
        activityIndicator.startAnimating()
        clearCacheButton.isEnabled = false
        
        ImageCacheManager.shared.clearCache()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateCacheInfo()
            self?.clearCacheButton.isEnabled = true
            self?.activityIndicator.stopAnimating()
            
            let alert = UIAlertController(
                title: LocalizationManager.shared.localizedString(for: "cache_is_cleaned"),
                message: nil,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    @objc private func cacheLimitChanged() {
        let newValue = Int(cacheLimitSlider.value)
        updateCacheLimitLabel(value: newValue)
        ImageCacheManager.shared.setCacheLimit(megabytes: newValue)
    }
    
    @objc private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
}
