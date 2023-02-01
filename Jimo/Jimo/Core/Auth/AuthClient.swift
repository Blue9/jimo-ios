//
//  AuthClient.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/11/21.
//

import SwiftUI
import Foundation
import Firebase
import Combine

typealias Token = String

class AuthClient: ObservableObject {
    /// The currently signed in Firebase user
    var currentUser: FirebaseAuth.User?
    var cancelBag: Set<AnyCancellable> = .init()

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.currentUser = user
        }
    }

    private func deleteAnonymousAccount() {
        if let anonUser = Auth.auth().currentUser, anonUser.isAnonymous {
            anonUser.delete()
        }
    }

    func signUp(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        deleteAnonymousAccount()
        return Future<AuthDataResult, Error> { promise in
            Auth.auth().createUser(withEmail: email, password: password) { auth, error in
                if let error = error {
                    promise(.failure(error))
                } else if let auth = auth {
                    promise(.success(auth))
                }
            }
        }.eraseToAnyPublisher()
    }

    func signIn(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        deleteAnonymousAccount()
        return Future<AuthDataResult, Error> { promise in
            Auth.auth().signIn(withEmail: email, password: password) { auth, error in
                if let error = error {
                    promise(.failure(error))
                } else if let auth = auth {
                    promise(.success(auth))
                }
            }
        }.eraseToAnyPublisher()
    }

    func signInAnonymously() -> AnyPublisher<AuthDataResult, Error> {
        Future<AuthDataResult, Error> { promise in
            Auth.auth().signInAnonymously { auth, error in
                if let error = error {
                    promise(.failure(error))
                } else if let auth = auth {
                    promise(.success(auth))
                }
            }
        }.eraseToAnyPublisher()
    }

    func verifyPhoneNumber(phoneNumber: String) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    promise(.failure(error))
                } else if let verificationID = verificationID {
                    promise(.success(verificationID))
                }
            }
        }.eraseToAnyPublisher()
    }

    func signInPhone(
        verificationID: String,
        verificationCode: String,
        onLinkCredential: @escaping () -> Void
    ) -> AnyPublisher<AuthDataResult, Error> {
        // Linking credentials updates currentUser but doesn't call any auth state listeners
        // so it's handled manually
        // https://github.com/firebase/firebase-android-sdk/issues/2160
        // https://stackoverflow.com/questions/65866463/using-swiftui-combine-and-firebase-how-do-i-verify-that-a-user-is-signed-in-a
        Future<AuthDataResult, Error> { promise in
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: verificationCode)
            if let anonUser = Auth.auth().currentUser, anonUser.isAnonymous {
                anonUser.link(with: credential, completion: { auth, error in
                    if let error = error {
                        if (error as NSError).code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                            anonUser.delete()
                            if let updatedCredential = (error as NSError).userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? PhoneAuthCredential {
                                Auth.auth().signIn(with: updatedCredential) { auth, error in
                                    if let error = error {
                                        promise(.failure(error))
                                    } else if let auth = auth {
                                        promise(.success(auth))
                                    }
                                }
                            } else {
                                promise(.failure(error))
                            }
                        } else {
                            promise(.failure(error))
                        }
                    } else if let auth = auth {
                        promise(.success(auth))
                        onLinkCredential()
                    }
                })
            } else {
                Auth.auth().signIn(with: credential, completion: { auth, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let auth = auth {
                        promise(.success(auth))
                    }
                })
            }
        }.eraseToAnyPublisher()
    }

    func forgotPassword(email: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    func getAuthJWT() -> AnyPublisher<Token, Error> {
        guard let currentUser = self.currentUser else {
            print("Not logged in")
            return Fail(error: APIError.authError)
                .eraseToAnyPublisher()
        }
        return Future<Token, Error> { promise in
            return currentUser.getIDToken { token, error in
                if let error = error {
                    promise(.failure(error))
                } else if let token = token {
                    promise(.success(token))
                }
            }
        }.eraseToAnyPublisher()
    }
}
