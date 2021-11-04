
import UIKit
import GBMChallengeKit
import GBMChallengeiOS

class IPCFeedUIComposer {
    static func composeIPCViewController(repository: IPCRepositoryType, counter: Counter, rangeOptions: [RangeOption]) -> IPCFeedViewController {
        let viewModel = IPCFeedViewModel(repository: repository, countdownCounter: counter, rangeOptions: rangeOptions)
        return IPCFeedViewController(viewModel: viewModel)
    }
}
