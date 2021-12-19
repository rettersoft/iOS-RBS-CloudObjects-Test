//
//  ViewController.swift
//  RBS-CloudObjects-Test
//
//  Created by Baran Baygan on 19.12.2021.
//

import UIKit
import RBS

struct ValidationErrors: Decodable {
    let issues: [ValidationIssue]
}

struct ValidationIssue: Decodable {
    let code: String
    let expected: String
    let received: String
    let message: String
    let path: [String]
}

class BaseError: Decodable {
    var validationErrors: ValidationErrors? = nil
}

class SignInErrorResponse: BaseError {
    var error: String? = nil
}

struct SignInResponse: Decodable {
    let customToken: String
}

struct UserInfo: Decodable {
    var username: String
}

class ViewController: UIViewController {
    
    @IBOutlet weak var btnGetProfile: UIButton!
    @IBOutlet weak var btnSignIn: UIButton!
    
    let rbs = RBS.init(config: RBSConfig(projectId: "2c771eb22f6d4c2d8e70e0f0e8c0bc10",
                                         region: .euWest1Beta))
    
    var userObject: RBSCloudObject?
    var authStatus: RBSClientAuthStatus = .signedOut {
        didSet {
            switch authStatus {
            case .signedIn(let user):
                self.btnGetProfile.isHidden = false
                self.btnSignIn.setTitle("Sign Out", for: .normal)
                
                self.rbs.getCloudObject(with: RBSCloudObjectOptions(classID: "User", instanceID: user.uid)) { cloudObject in
                    
                    self.userObject = cloudObject
                    
                } onError: { error in
                    
                }
            
            default:
                self.btnGetProfile.isHidden = true
                self.btnSignIn.setTitle("Sign In", for: .normal)
            }
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.rbs.delegate = self
    }
    
    @IBAction func btnSignInTapped(_ sender: Any) {
        
        if case .signedIn(_) = self.authStatus {
            self.rbs.signOut()
            return
        }
        
        self.rbs.getCloudObject(with: RBSCloudObjectOptions(classID: "User",
                                                            keyValue: (key: "username", value: "loodos") )) { object in
                        
            object.call(with: RBSCloudObjectOptions(method:"signin", body: ["password": "123123"]),
                                   onSuccess: { response in
                
                if let body = response.body {
                    // response is type of RBSCloudObjectResponse
                    // you can parse its body to your model like below:
                    let signInResponse = try! JSONDecoder().decode(SignInResponse.self, from: body)
                    self.rbs.authenticateWithCustomToken(signInResponse.customToken)
                }
                
            }, onError: { error in
                // error is type of RBSCloudObjectError
                // you can also parse error response body to your error model like below:
                if let response = error.response, let body = response.body {
                    let signInErrorResponse: SignInErrorResponse = try! JSONDecoder().decode(SignInErrorResponse.self, from: body)
                    print(signInErrorResponse)
                }
            })
            
            
        } onError: { error in
            
        }
        
        
    }
    
    @IBAction func btnGetProfileTapped(_ sender: Any) {
        
        self.userObject?.call(with: RBSCloudObjectOptions(method: "getProfile"),
                              onSuccess: { response in
            
            if let body = response.body {
                let userInfo = try! JSONDecoder().decode(UserInfo.self, from: body)
                
                let alert = UIAlertController(title: "Profile", message: "\(userInfo.username)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        }, onError: { error in
            
        })
        
    }
}

extension ViewController : RBSClientDelegate {
    func rbsClient(client: RBS, authStatusChanged toStatus: RBSClientAuthStatus) {
        self.authStatus = toStatus
    }
}

