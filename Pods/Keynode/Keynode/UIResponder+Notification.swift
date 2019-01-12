//
//  UIResponder+Notification.swift
//  Keynode
//
//  Created by Kyohei Ito on 2017/11/23.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

extension UIResponder {
    @objc func firstResponder(_ sender: AnyObject?) {
        NotificationCenter.default.post(name: UIResponder.becomeFirstResponder, object: self, userInfo: nil)
    }

    /// first responder notification name
    public static let becomeFirstResponder = Notification.Name("UIResponderBecomeFirstResponder")
}
