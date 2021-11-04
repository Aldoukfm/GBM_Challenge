
import UIKit
import GBMChallengeKit
import GBMChallengeiOS

class LoginUIComposer {
    static func composeLoginViewController(auth: BiometryAuthType) -> LoginViewController {
        let viewModel = LoginViewModel(auth: auth)
        return LoginViewController(viewModel: viewModel)
    }
}
