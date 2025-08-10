//
//  ViewController.swift
//  AsyncReactorKitSample
//
//  Created by 박종우 on 8/3/25.
//

import UIKit
import Combine
import AsyncReactor

class ViewController: UIViewController, Store {

    typealias Reactor = ViewReactor

    private var cancellable: Set<AnyCancellable> = []

    private let incrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Increment", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 25)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        return button
    }()

    private let decrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Decrement", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 25)
        button.titleLabel?.textColor = .systemBlue
        return button
    }()

    private let navigateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reset", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 25)
        button.titleLabel?.textColor = .systemBlue
        return button
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        return stackView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24)
        return label
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        self.reactor = ViewReactor()

        self.view.addSubview(self.label)
        self.view.addSubview(self.stackView)
        self.view.addSubview(self.navigateButton)

        self.stackView.addArrangedSubview(self.incrementButton)
        self.stackView.addArrangedSubview(self.decrementButton)
        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.label.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18),
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -18),
            self.stackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -18),

            self.navigateButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18),
            self.navigateButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -18),
            self.navigateButton.bottomAnchor.constraint(equalTo: self.stackView.topAnchor, constant: -20)
        ])

        self.incrementButton.addTarget(self, action: #selector(self.incrementButtonTapped(_:)), for: .touchUpInside)
        self.decrementButton.addTarget(self, action: #selector(self.decrementButtonTapped(_:)), for: .touchUpInside)
        self.navigateButton.addTarget(self, action: #selector(self.navigateButtonTapped(_:)), for: .touchUpInside)
    }

    func state(_ state: ViewReactor.State) {
        state.$number
            .sink { [weak self] count in
                self?.label.text = "\(count)"
            }
            .store(in: &self.cancellable)
    }

    @objc private func incrementButtonTapped(_ sender: UIButton) {
        self.send(.increase)
        self.send(.increase)
    }

    @objc private func decrementButtonTapped(_ sender: UIButton) {
        self.send(.decrease)
    }

    @objc private func navigateButtonTapped(_ sender: UIButton) {
        self.send(.reset)
    }
}

