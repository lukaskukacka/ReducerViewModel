//
//  Created by Lukas Kukacka on 2020-03-18.
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import Foundation

public struct Disposable {
    fileprivate var identifier: String
}

public final class Observable<T> {
    
    public var value: T {
        didSet {
            self.observers.forEach { $0.block(value) }
        }
    }
    
    private var observers: [(identifier: String, block: ((T) -> Void))] = []
    
    public init(value: T) {
        self.value = value
    }

    @discardableResult
    public func setAndStartObserving(block: @escaping (T) -> Void) -> Disposable {
        block(self.value)

        return self.startObserving(block: block)
    }
    
    @discardableResult
    public func startObserving(block: @escaping (T) -> Void) -> Disposable {
        let identifier = NSUUID().uuidString
        
        self.observers.append((identifier, block))
        
        return Disposable(identifier: identifier)
    }
    
    public func dispose(_ disposable: Disposable) {
        let index = self.observers.firstIndex { $0.identifier == disposable.identifier }
        
        guard let unwrappedIndex = index else { return }
        self.observers.remove(at: unwrappedIndex)
    }
}
