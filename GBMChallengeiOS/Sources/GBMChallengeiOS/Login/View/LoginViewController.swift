
import UIKit
import GBMChallengeKit
import Combine
import CombineHelpers

public protocol LoginViewControllerDelegate: AnyObject {
    func loginViewControllerDidLoginUser(_ viewController: LoginViewController)
    func loginViewController(_ viewController: LoginViewController, didReceiveLoginError error: Error)
}

public class LoginViewController: UIViewController {
    
    private(set) public var titleLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = NSTextAlignment.center
        lbl.numberOfLines = 2
        lbl.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        lbl.textColor = Colors.primaryText
        lbl.text = "GBM CHALLENGE"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private(set) public var descriptionLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = NSTextAlignment.center
        lbl.numberOfLines = 2
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        lbl.textColor = Colors.secondaryText
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private(set) public var biometryImg: UIImageView! = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    private(set) public var loginBtn: UIButton! = {
        let btn = UIButton()
        btn.setTitle("Iniciar sesión", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.backgroundColor = UIColor.systemBlue
        btn.layer.cornerRadius = 8
        btn.layer.shadowRadius = 8
        btn.layer.shadowOpacity = 0.25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let viewModel: LoginViewModel
    
    public weak var delegate: LoginViewControllerDelegate?
    
    private var cancellables: [AnyCancellable] = []
    
    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupLayout()
        bind(viewModel: viewModel)
        loginBtn.addTarget(self, action: #selector(loginBtnHandler), for: .touchUpInside)
    }
    
    private func bind(viewModel: LoginViewModel) {
        viewModel.authMessagePublisher
            .weakAssign(to: \.text, on: descriptionLbl)
            .store(in: &cancellables)
        
        viewModel.authImagePublisher
            .weakAssign(to: \.image, on: biometryImg)
            .store(in: &cancellables)
    }
    
    private func setupLayout() {
        
        let stack = UIStackView(arrangedSubviews: [titleLbl, descriptionLbl, biometryImg, loginBtn])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.setCustomSpacing(40, after: titleLbl)
        stack.setCustomSpacing(80, after: descriptionLbl)
        stack.setCustomSpacing(130, after: biometryImg)
        
        biometryImg.constraintSizeTo(CGSize(width: 100, height: 100))
        
        loginBtn.constraintHeightTo(constant: 50)
        loginBtn.constraintWidthTo(stack)
        
        view.addSubview(stack)
        stack.constraintTo(view.safeAreaLayoutGuide, attributes: [.left, .right, .centerY], insets: UIEdgeInsets(30, 0))
        
    }
    
    private func loginUser() {
        viewModel.loginUser()
            .sink {[unowned self] completion in
                switch completion {
                case .finished:
                    delegate?.loginViewControllerDidLoginUser(self)
                case .failure(let error):
                    delegate?.loginViewController(self, didReceiveLoginError: error)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    @objc private func loginBtnHandler() {
        loginUser()
    }
}

import SwiftUI

struct LoginProvider: PreviewProvider {
    
    static var previews: some View {
        Group {
            VCContainer(biometry: .faceid)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    struct VCContainer: UIViewControllerRepresentable {
        typealias UIViewControllerType = LoginViewController
        
        let auth: AuthMock
        
        init(biometry: BiometryType) {
            self.auth = AuthMock(biometry: biometry)
        }
        
        func makeUIViewController(context: Context) -> LoginViewController {
            let viewModel = LoginViewModel(auth: auth)
            let vc = LoginViewController(viewModel: viewModel)
            return vc
        }
        
        func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
            
        }
    }
    
    class AuthMock: BiometryAuthType {
        
        let supportedBiometry: BiometryType
        
        init(biometry: BiometryType) {
            self.supportedBiometry = biometry
        }
        
        private var subjects: [PassthroughSubject<Void, Error>] = []
        
        func authenticateUser() -> AnyPublisher<Void, Error> {
            let subject = PassthroughSubject<Void, Error>()
            subjects.append(subject)
            return subject.eraseToAnyPublisher()
        }
        
        func complete(with error: Error?, at index: Int = 0) {
            if let error = error {
                subjects[index].send(completion: .failure(error))
            } else {
                subjects[index].send(())
                subjects[index].send(completion: .finished)
            }
        }
    }
}
