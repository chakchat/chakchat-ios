//
//  ForwardMessagePresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 19.04.2025.
//

import UIKit

final class ForwardMessagePresenter: ForwardMessagePresentationLogic {
    
    weak var view: ForwardMessageViewController?
    
    func showForwardStatus(_ message: String, _ status: Bool) {
        view?.showForwardState(message, status)
    }
}
