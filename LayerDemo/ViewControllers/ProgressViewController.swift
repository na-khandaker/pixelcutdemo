//
//  ProgressViewController.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit


// MARK: - ProgressViewController
class ProgressViewController: UIViewController {
    var progressView = UIProgressView(progressViewStyle: .default)
    var titleLabel = UILabel()
    var cancelHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        
        titleLabel.text = "Exporting Video"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        progressView.progress = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, progressView])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 250),
            
//            view.widthAnchor.constraint(equalToConstant: 300),
//            view.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func cancelTapped() {
        cancelHandler?()
        dismiss(animated: true)
    }
    
    func updateProgress(_ progress: Float) {
        progressView.setProgress(progress, animated: true)
    }
}

