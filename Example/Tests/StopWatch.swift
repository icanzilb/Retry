//
//  Created by Marin Todorov
//  Copyright (c) 2016-present Underplot ltd. All rights reserved.
//
//  This source code is covered by the MIT license. Consult the LICENSE file.
//

import Foundation

class StopWatch {
    static func time(worker: () throws ->Void) rethrows -> Double {
        let t1 = mach_absolute_time()
        try worker()
        let t2 = mach_absolute_time()

        let elapsed = t2 - t1
        var timeBaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timeBaseInfo)
        let elapsedNano = elapsed * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom)

        return Double(elapsedNano) / 1000000000
    }

    static func deltaSince(t1: UInt64) -> Double {
        let t2 = mach_absolute_time()

        let elapsed = t2 - t1
        var timeBaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timeBaseInfo)
        let elapsedNano = elapsed * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom)

        return Double(elapsedNano) / 1000000000
    }
}
