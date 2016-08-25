//
//  Created by Marin Todorov
//  Copyright (c) 2016-present Underplot ltd. All rights reserved.
//
//  This source code is covered by the MIT license. Consult the LICENSE file.
//

import UIKit
import Retry

class API {
    enum WebError: Error {
        case couldnLoadData
    }

    var count = 0
    func loadWebData() throws {
        count += 1
        if count < 4 {
            throw WebError.couldnLoadData
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet var info: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // NB: this is quite elaborate example
        // for simpler or more advanced code samples
        // check the GitHub repo README file

        var currentTry = 0
        var currentDelay = 0.0
        let api = API()

        retryAsync (max: 5, retryStrategy: .custom(closure: {count, lastDelay in
            currentDelay = (lastDelay ?? 0) + 1.0
            return  currentDelay})) {

                currentTry += 1
                self.info.text = "Try #\(currentTry) after waiting \(currentDelay)s"
                try api.loadWebData()
        }
        .finalCatch {error in
            self.info.text = "Failed after \(currentTry) retries with error: \(error.localizedDescription)"
        }
        .finalDefer {
            self.info.text = "Succeeded after \(currentTry) retries."
        }
    }

}
