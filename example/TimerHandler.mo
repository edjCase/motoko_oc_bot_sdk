import Timer "mo:base/Timer";
import Buffer "mo:base/Buffer";
module {

    public class TimerHandler(timerIds_ : [Timer.TimerId]) {
        var timerIds = Buffer.fromArray<Timer.TimerId>(timerIds_);

        public func addTimer<system>(duration : Timer.Duration, action : () -> async ()) : () {
            let timerId = Timer.setTimer<system>(duration, action);
            timerIds.add(timerId);
        };

        public func toStableData() : [Timer.TimerId] {
            return Buffer.toArray(timerIds);
        };
    };

};
