//
//  ExistingContactStore.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import Foundation
import Combine
import Contacts
import PhoneNumberKit


class ExistingContactStore: SuggestedUserStore {
    static let phoneNumberKit = PhoneNumberKit()
    
    @Published var allUsers: [PublicUser] = []
    @Published var selected: [PublicUser] = []
    
    @Published var loadingExistingUsers = false
    @Published var loadingExistingUsersError: Error? = nil
    
    @Published var followingLoading = false
    @Published var followManyFailed = false
    
    private var getUsersCancellable: Cancellable? = nil
    private var followUsersCancellable: Cancellable? = nil
    
    func getExistingUsers(appState: AppState) {
        self.loadingExistingUsers = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.getUsersCancellable = self.fetchContacts()
                .catch({ [weak self] error -> AnyPublisher<[String], APIError> in
                    DispatchQueue.main.async {
                        self?.loadingExistingUsersError = error
                        self?.loadingExistingUsers = false
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
                        self?.loadingExistingUsersError = error
                        self?.loadingExistingUsers = false
                    }
                }, receiveValue: { [weak self] users in
                    self?.allUsers = users
                    self?.selected = users
                    self?.loadingExistingUsersError = nil
                    self?.loadingExistingUsers = false
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
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
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
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        if let number = contact.phoneNumbers.first?.value.stringValue,
                           let parsed = try? ExistingContactStore.phoneNumberKit.parse(number) {
                            formattedArray.append(ExistingContactStore.phoneNumberKit.format(parsed, toType: .e164))
                        }
                    })
                    handler(formattedArray, nil)
                } catch let error {
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
        let toFollow = selected.compactMap({ $0.username })
        followUsersCancellable = appState.followMany(usernames: toFollow)
            .sink { [weak self] completion in
                self?.followingLoading = false
                if case let .failure(error) = completion {
                    print("Error when following many", error)
                    self?.followManyFailed = true
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    appState.onboardingModel.setContactsOnboarded()
                } else {
                    self?.followManyFailed = true
                }
            }
    }
    
    func toggleSelected(for contact: PublicUser) {
        if selected.contains(contact) {
            selected.removeAll { contact == $0 }
        } else {
            selected.append(contact)
        }
    }
    
    func clearAll() {
        selected.removeAll()
    }
    
    func selectAll() {
        selected = allUsers
    }
}
