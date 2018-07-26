//
//  CountdownTimerTests.swift
//  CountdownTimerTests
//
//  Created by 유금상 on 2018. 6. 17..
//  Copyright © 2018년 유금상. All rights reserved.
//

// * 특정 시간을 셋팅할 수 있어야 한다.
// * 시간이 가는 동안 초단위로 표시할 수 있어야 한다.
// * 시간이 끝나면 끝났다는 것을 표시할 수 있어야 한다.
// * 시간을 중간에 멈추고, 이어서 시작하거나, 리셋할 수 있어야 한다.
//
//
// [v] 시간을 정할 수 있어야 한다.
// [v] 시간을 변경할 수 있어야 한다.

// [v] start 할 수 있어야 한다.
// [v] stop 할 수 있어야 한다.
// [v] reset 할 수 있다.


// [v] setTime이 안되어 있으면 나머지 기능은 쓸 수 없다. 0:0:0 을 말하는 것임.
// [v] start (reset, stop)
// [v] stop (start)
// [v] reset (stop)
// [v] setTime (init, reset)

// [v] setTime 하면 화면에 그 시간이 표시되어야 한다.

// [] start하면 시간의 변화를 알 수 있어야 한다.
// [] 시간은 역순으로 카운트 다운 되어야 한다.

// [] stop을 하면 시간의 변화가 멈춰야 한다.
// [] reset을 하면 남은 시간 표시가 초기화 되어야 한다.

// [] stop, start 하면 시간을 이어서 표시한다.

// [] 시간 출력 형식 00:00:00
// [X] 시간 입력을 TimeInerval로 변환해야 한다. -> 시간을 입력하면 UIDatePicker가 TimeInterval로 돌려준다.


import XCTest
import Nimble
import RxSwift
import RxCocoa

@testable import CountdownTimer

enum CountdownTimerState {
    case pending
    case started
    case stopped
}

class CountdownTimer {
    var hour: Int = 0
    var minute: Int = 0
    var second: Int = 0
    
    var state: BehaviorRelay<CountdownTimerState> = BehaviorRelay<CountdownTimerState>(value: .pending)
    let timeChanged: PublishSubject<Int> = PublishSubject<Int>()
    
    let disposeBag = DisposeBag()
    
    func setTime(hour: Int, minute: Int, second: Int) {
        guard state.value == .pending else { return }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        
        timeChanged.onNext(second)
    }
    
    func start() {
        guard hour > 0 || minute > 0 || second > 0 else { return }
        state.accept(.started)
        
        Observable<Int>
            .interval(RxTimeInterval(1), scheduler: MainScheduler.instance)
            .bind(to: timeChanged)
            .disposed(by: disposeBag)
    }
    
    func stop() {
        guard state.value == .started else { return }
        state.accept(.stopped)
    }
    
    func reset() {
        guard state.value == .stopped else { return }
        state.accept(.pending)
    }
    
    func getTime() -> String {
        return "0:0:1"
    }
}

class CountdownTimerTests: XCTestCase {
    
    var disposeBag = DisposeBag()
    
    func testCanSetTime() {
        let underTest = CountdownTimer()
        let expectedHour = 0
        let expectedMinute = 0
        let expectedSecond = 0
        
        expectTime(underTest: underTest, hour: expectedHour, minute: expectedMinute, second: expectedSecond)
    }
    
    func testCanSetTime_1_1_1() {
        let underTest = CountdownTimer()
        let expectedHour = 1
        let expectedMinute = 1
        let expectedSecond = 1
        
        expectTime(underTest: underTest, hour: expectedHour, minute: expectedMinute, second: expectedSecond)
    }
    
    func expectTime(underTest: CountdownTimer, hour: Int, minute: Int, second: Int) {
        underTest.setTime(hour: hour, minute: minute, second: second)
        
        expect(underTest.hour).to(equal(hour))
        expect(underTest.minute).to(equal(minute))
        expect(underTest.second).to(equal(second))
    }
    
    func testCanChangeTime() {
        let underTest = CountdownTimer()
        let expectedHour = 1
        let expectedMinute = 1
        let expectedSecond = 1
        
        let changedHour = 3
        let changedMinute = 2
        let changedSecond = 2
        
        expectTime(underTest: underTest, hour: expectedHour, minute: expectedMinute, second: expectedSecond)
        expectTime(underTest: underTest, hour: changedHour, minute: changedMinute, second: changedSecond)
    }
    
    func testCanNotChangeTimeWhenStarted() {
        let underTest = CountdownTimer()
        let expectedHour = 1
        let expectedMinute = 1
        let expectedSecond = 1
        
        let changedHour = 3
        let changedMinute = 2
        let changedSecond = 2
        
        underTest.setTime(hour: expectedHour, minute: expectedMinute, second: expectedSecond)
        underTest.start()
        underTest.setTime(hour: changedHour, minute: changedMinute, second: changedSecond)
        
        expect(underTest.hour).to(equal(expectedHour))
        expect(underTest.minute).to(equal(expectedMinute))
        expect(underTest.second).to(equal(expectedSecond))
    }
    
    func testCanNotChangeTimeWhenStopped() {
        let underTest = CountdownTimer()
        let expectedHour = 1
        let expectedMinute = 1
        let expectedSecond = 1
        
        let changedHour = 3
        let changedMinute = 2
        let changedSecond = 2
        
        underTest.setTime(hour: expectedHour, minute: expectedMinute, second: expectedSecond)
        underTest.start()
        underTest.stop()
        underTest.setTime(hour: changedHour, minute: changedMinute, second: changedSecond)
        
        expect(underTest.hour).to(equal(expectedHour))
        expect(underTest.minute).to(equal(expectedMinute))
        expect(underTest.second).to(equal(expectedSecond))
    }
    
    func testCanNotChangeTimeWhenWasReset() {
        let underTest = CountdownTimer()
        let expectedHour = 3
        let expectedMinute = 2
        let expectedSecond = 2
        
        underTest.setTime(hour: 999, minute: 1, second: 1)
        underTest.start()
        underTest.stop()
        underTest.reset()
        underTest.setTime(hour: expectedHour, minute: expectedMinute, second: expectedSecond)
        
        expect(underTest.hour).to(equal(expectedHour))
        expect(underTest.minute).to(equal(expectedMinute))
        expect(underTest.second).to(equal(expectedSecond))
    }
    
    func testCanStart() {
        let underTest = CountdownTimer()
        var emitCount: Int = 0
        
        //Rx에 있는 BehaviorRelay로 바꿔서 상태변화를 확인할 수 있도록 변경한다.
        underTest.state.filter { $0 == .started }
            .subscribe(onNext: { _ in
                emitCount = emitCount + 1
            })
            .disposed(by: disposeBag)
        
        underTest.start()
        expect(underTest.state.value).toNot(equal(.started)) //실제로 start가 발생하지 않은 구간.
        
        underTest.setTime(hour: 0, minute: 0, second: 1)
        underTest.start()
        expect(underTest.state.value).to(equal(.started))
        expect(emitCount).to(equal(1))
    }
    
    func testCanStartWhenStopped() {
        let underTest = CountdownTimer()
        underTest.setTime(hour: 0, minute: 0, second: 1)
        
        expect(underTest.state.value).to(equal(.pending))
        
        underTest.start()
        
        expect(underTest.state.value).to(equal(.started))
        expect(underTest.state.value).toNot(equal(.stopped))
    }
    
    func testCanStartWhenWasReset() {
        let underTest = CountdownTimer()
        underTest.setTime(hour: 0, minute: 0, second: 1)
        
        expect(underTest.state.value).to(equal(.pending))
        
        underTest.start()
        
        expect(underTest.state.value).to(equal(.started))
        expect(underTest.state.value).toNot(equal(.pending))
    }
    
    func testCanStopWhenStarted() {
        let underTest = CountdownTimer()
        var emitCount: Int = 0
        
        underTest.setTime(hour: 0, minute: 0, second: 1)
        
        underTest.state.filter { $0 == .stopped }
            .subscribe(onNext: { _ in
                emitCount = emitCount + 1
            })
            .disposed(by: disposeBag)
        
        underTest.stop() //start 없이 stop 실행 - 실행되지 않아야 함.
        
        underTest.start() //setTime 없이 start하여 start가 실행되지 않았고,
        
        underTest.stop()  //start가 실행되지 않았으니 stop도 실행되지 않음.
        
        expect(underTest.state.value).to(equal(.stopped))
        expect(emitCount).to(equal(1))
    }
    
    func testCanReset() {
        let underTest = CountdownTimer()
        var emitCount: Int = 0
        
        underTest.setTime(hour: 0, minute: 0, second: 1)
        
        underTest.state.filter { $0 == .pending }
            .subscribe(onNext: { _ in //(emitCount + 1
                emitCount = emitCount + 1
            })
            .disposed(by: disposeBag)
        
        underTest.reset() //reset 그냥 실행 (x)
        
        underTest.start()
        underTest.reset() //start 상태에서 reset 실행 (x)
        
        underTest.stop()
        underTest.reset() //stop 하고나서 reset 실행 (o)
        
        expect(underTest.state.value).to(equal(.pending))
        expect(emitCount).to(equal(2))
    }
    
//    func testCanDisplayTimeWhenSetTime() {
//        let underTest = CountdownTimer()
//        var result: String = ""
//        underTest.timeChanged
//            .subscribe(onNext: { time in //setTime하면 화면에 표시되어야 한다는 건 변화를 감지해야 한다는 의미..
//                result = time
//            })
//            .disposed(by: disposeBag)
//
//        underTest.setTime(hour: 0, minute: 0, second: 1)
//
//        expect(result).to(equal("0:0:1"))
//    }
    
    func testCanObserveChangeTimeWhenStarted() {
        let underTest = CountdownTimer()
        var emitCount: Int = 0
        
        underTest.timeChanged
            .subscribe(onNext: { _ in //setTime하면 화면에 표시되어야 한다는 건 변화를 감지해야 한다는 의미..
                emitCount = emitCount + 1
            })
            .disposed(by: disposeBag)
        
        underTest.setTime(hour: 0, minute: 0, second: 5)
        underTest.start()
        
        expect(emitCount).toEventually(equal(6), timeout: 6)
    }
}
