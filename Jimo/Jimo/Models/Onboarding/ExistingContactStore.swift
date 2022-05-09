//
//  ExistingContactStore.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import SwiftUI
import Combine
import Contacts
import PhoneNumberKit

class ExistingContactStore: SuggestedUserStore {
    static let phoneNumberKit = PhoneNumberKit()

    @Published var allUsers: [PublicUser] = []
    @Published var selectedUsernames: Set<String> = []

    @Published var loadingExistingUsers = true
    @Published var loadingExistingUsersError: Error?

    @Published var followingLoading = false
    @Published var followManyFailed = false

    private var getUsersCancellable: Cancellable?
    private var followUsersCancellable: Cancellable?

    func getExistingUsers(appState: AppState) {
        withAnimation {
            self.loadingExistingUsers = true
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.getUsersCancellable = self.fetchContacts()
                .catch({ [weak self] error -> AnyPublisher<[String], APIError> in
                    DispatchQueue.main.async {
                        withAnimation {
                            self?.loadingExistingUsersError = error
                            self?.loadingExistingUsers = false
                        }
                    }
                    return Empty().eraseToAnyPublisher()
                })
                .flatMap({ numbers -> AnyPublisher<[PublicUser], APIError> in
                    let maxContacts = min(numbers.count, 5000)
                    return appState.getUsersInContacts(phoneNumbers: Array(numbers[0..<maxContacts]))
                })
                .sink(receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Error when getting matching users", error)
                        withAnimation {
                            self?.loadingExistingUsersError = error
                            self?.loadingExistingUsers = false
                        }
                    }
                }, receiveValue: { [weak self] users in
                    withAnimation {
                        self?.allUsers = users
                        self?.selectAll()
                        self?.loadingExistingUsersError = nil
                        self?.loadingExistingUsers = false
                    }
                })
        }
    }

    private func fetchContacts() -> AnyPublisher<[String], Error> {
        Future<[String], Error> { promise in
            ExistingContactStore.fetchContactsCallback({ phoneNumbers, error in
                if let error = error {
                    promise(.failure(error))
                } else if let phoneNumbers = phoneNumbers {
                    promise(.success(phoneNumbers))
                }
            })
        }.eraseToAnyPublisher()
    }

    private static func fetchContactsCallback(_ handler: @escaping ([String]?, Error?) -> Void) {
        PermissionManager.shared.requestContacts { granted, error in
            if let error = error {
                handler(nil, error)
                return
            }
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey, CNContactPhoneNumbersKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                request.sortOrder = .givenName
                do {
                    var formattedArray: [String] = []
                    try PermissionManager.shared.contactStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                        if let number = contact.phoneNumbers.first?.value.stringValue,
                           let parsed = try? ExistingContactStore.phoneNumberKit.parse(number) {
                            formattedArray.append(ExistingContactStore.phoneNumberKit.format(parsed, toType: .e164))
                        }
                    })
                    handler(formattedArray, nil)
                } catch {
                    handler(nil, error)
                }
            } else {
                print("Error when getting contacts, defaulting to empty list")
                handler([], nil)
            }
        }
    }

    func follow(appState: AppState) {
        followingLoading = true
        followUsersCancellable = appState.followMany(usernames: Array(selectedUsernames))
            .sink { [weak self] completion in
                self?.followingLoading = false
                if case let .failure(error) = completion {
                    print("Error when following many", error)
                    self?.followManyFailed = true
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    appState.onboardingModel.step()
                } else {
                    self?.followManyFailed = true
                }
            }
    }

    func toggleSelected(for username: String) {
        if selectedUsernames.contains(username) {
            selectedUsernames.remove(username)
        } else {
            selectedUsernames.insert(username)
        }
    }

    func clearAll() {
        selectedUsernames.removeAll()
    }

    func selectAll() {
        selectedUsernames = Set(allUsers.map { $0.username })
    }
}
