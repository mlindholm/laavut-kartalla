//
//  NSLayoutConstraintExtension.swift
//  Laavut
//
//  Created by Mathias Lindholm on 26.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation
import UIKit


extension NSLayoutConstraint {

    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {

        NSLayoutConstraint.deactivateConstraints([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier

        NSLayoutConstraint.activateConstraints([newConstraint])

        return newConstraint
    }
}