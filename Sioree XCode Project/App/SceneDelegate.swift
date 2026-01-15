//
//  SceneDelegate.swift
//  Sioree
//

import UIKit
import StripePaymentSheet

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        StripeAPI.handleURLCallback(with: url)
    }
}


