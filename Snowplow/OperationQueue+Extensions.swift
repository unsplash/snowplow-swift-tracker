//
//  OperationQueue+Extensions.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

extension OperationQueue {

    convenience init(with name: String, serial: Bool = false) {
        self.init()
        self.name = name
        if serial {
            maxConcurrentOperationCount = 1
        }
    }

    func addOperationWithDependencies(_ operation: Operation) {
        for dependencies in operation.dependencies {
            addOperationWithDependencies(dependencies)
        }
        addOperation(operation)
    }

}
