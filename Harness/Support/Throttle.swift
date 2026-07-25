//
//  Throttle.swift
//  Harness
//
//  Created by Spencer Hartland on 7/21/26.
//

import Foundation

final class Throttle {
    private let interval: TimeInterval
    private var lastFire: Date = .distantPast
    private var pending: DispatchWorkItem?

    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func send(_ action: @escaping () -> Void) {
        pending?.cancel()
        let elapsed = Date().timeIntervalSince(lastFire)
        if elapsed >= interval {
            lastFire = .now
            action()
        } else {
            let work = DispatchWorkItem { [weak self] in
                self?.lastFire = .now
                action()
            }
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval - elapsed), execute: work)
        }
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }
}
