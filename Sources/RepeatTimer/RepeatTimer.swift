//
//  RepeatTimer.swift
//
//  Created by Grigory Avdyushin on 05/02/2017.
//  Copyright © 2019 Grigory Avdyushin. All rights reserved.
//

import Foundation

class RepeatTimer {

    class TimerState {
        func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return true
        }
    }

    class RunningState: TimerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == PausedState.self || stateClass == StoppedState.self
        }
    }

    class StoppedState: TimerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == RunningState.self
        }
    }

    class PausedState: TimerState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == RunningState.self || stateClass == StoppedState.self
        }
    }

    class TimerStateMachine {

        private let states: [TimerState]
        private(set) var currentState: TimerState?

        init(states: [TimerState]) {
            self.states = states
        }

        @discardableResult
        func enter(_ stateClass: AnyClass) -> Bool {
            if currentState?.isValidNextState(stateClass) != false /* nil or true */ {
                currentState = states.first { type(of: $0) == stateClass }
                return true
            }
            return false
        }
    }


    typealias TimeEventHandler = (RepeatTimer) -> Void

    private let timerQueue = DispatchQueue(
        label: "ru.avdyushin.\(RepeatTimer.self)",
        qos: .userInteractive
    )

    private let timeEventHandler: TimeEventHandler
    private let timeInterval: DispatchTimeInterval
    private let callbackQueue: DispatchQueue

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now(), repeating: timeInterval, leeway: .nanoseconds(10))
        timer.setEventHandler { [weak self] in
            self?.callbackQueue.async {
                guard let self = self else {
                    return
                }
                self.timeEventHandler(self)
            }
        }
        return timer
    }()

    private var startTime: TimeInterval = 0.0
    private var pauseTime: TimeInterval = 0.0

    private let stateMachine = TimerStateMachine(states: [
        StoppedState(),
        RunningState(),
        PausedState()
        ])

    var state: TimerState? {
        return stateMachine.currentState
    }

    var elapsedTimeInterval: TimeInterval {
        return Date.timeIntervalSinceReferenceDate - startTime
    }

    init(repeatInterval timeInterval: DispatchTimeInterval = .milliseconds(500),
         queue: DispatchQueue = DispatchQueue.main,
         eventHandler: @escaping TimeEventHandler) {

        precondition(timeInterval != .never)
        precondition(timeInterval != .microseconds(0))

        self.timeInterval = timeInterval
        self.timeEventHandler = eventHandler
        self.callbackQueue = queue
        self.stateMachine.enter(StoppedState.self)
    }

    deinit {
// Release of suspended timer cause a crash in realtime!
//        void
//        _dispatch_source_xref_release(dispatch_source_t ds)
//        {
//            if (slowpath(DISPATCH_OBJECT_SUSPENDED(ds))) {
//                // Arguments for and against this assert are within 6705399
//                DISPATCH_CLIENT_CRASH("Release of a suspended object");
//            }
//            _dispatch_wakeup(ds);
//            _dispatch_release(ds);
//        }
        if !(stateMachine.currentState is RunningState) {
            timer.resume()
        }
    }

    func start() {

        switch stateMachine.currentState {
        case is StoppedState:
            // Start new
            startTime = Date.timeIntervalSinceReferenceDate
        case is PausedState:
            // Resume
            startTime += (Date.timeIntervalSinceReferenceDate - pauseTime)
        default:
            ()
        }

        if stateMachine.enter(RunningState.self) {
            timer.resume()
        } else {
            assertionFailure("Can't switch to running state")
        }
    }

    func pause() {
        if stateMachine.enter(PausedState.self) {
            pauseTime = Date.timeIntervalSinceReferenceDate
            timer.suspend()
        } else {
            assertionFailure("Can't switch to paused state")
        }
    }

    func stop() {
        // Don't suspend already suspended Timers
        if stateMachine.currentState is RunningState {
            timer.suspend()
        }
        if !stateMachine.enter(StoppedState.self) {
            assertionFailure("Can't stop Timer")
        }
    }
}
