//
//  FollowContacts.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import SwiftUI
import Combine
import Contacts
import PhoneNumberKit

class ContactStore: ObservableObject {
    static let phoneNumberKit = PhoneNumberKit()
    
    @Published var contacts: [PublicUser]? = nil
    var formattedNumbers: [String] = []
    @Published var loading = false
    @Published var selected: [PublicUser] = []
    @Published var error: Error? = nil
    @Published var following = false
    
    private var getUsersCancellable: Cancellable? = nil
    
    func getExistingUsers(appState: AppState) {
        self.loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.getUsersCancellable = self.fetchContacts()
                .catch({ [weak self] error -> AnyPublisher<[String], APIError> in
                    DispatchQueue.main.async {
                        self?.error = error
                        self?.loading = false
                    }
                    return Empty().eraseToAnyPublisher()
                })
                .flatMap({ numbers -> AnyPublisher<[PublicUser], APIError> in
                    return appState.getUsersInContacts(phoneNumbers: numbers)
                })
                .sink(receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Error when getting matching users", error)
                        self?.error = error
                        self?.loading = false
                    }
                }, receiveValue: { [weak self] users in
                    self?.contacts = users
                    self?.selected = users
                    self?.loading = false
                })
        }
    }
    
    private func fetchContacts() -> AnyPublisher<[String], Error> {
        Future<[String], Error> { promise in
            ContactStore.fetchContactsCallback({ phoneNumbers, error in
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
                           let parsed = try? ContactStore.phoneNumberKit.parse(number) {
                            formattedArray.append(ContactStore.phoneNumberKit.format(parsed, toType: .e164))
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
        following = true
        // let _toFollow = selected.compactMap({ $0.username })
        // TODO follow users
        self.following = false
        appState.setUserOnboarded()
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
        selected = contacts ?? []
    }
}


struct SuggestedUserView: View {
    @ObservedObject var contactStore: ContactStore
    let contact: PublicUser
    
    var profilePicture: URLImage {
        return URLImage(url: contact.profilePictureUrl,
                        loading: Image(systemName: "person.crop.circle").resizable(),
                        failure: Image(systemName: "person.crop.circle").resizable())
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                profilePicture
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(40)
                
                if contactStore.selected.contains(contact) {
                    Image("selectedContact")
                        .resizable()
                        .frame(width: 26, height: 26)
                        .shadow(radius: 5)
                }
            }
            
            Text(contact.firstName + " " + contact.lastName)
                .font(Font.custom(Poppins.regular, size: 12))
        }
        .frame(minHeight: 120)
        .onTapGesture {
            contactStore.toggleSelected(for: contact)
        }
    }
}


struct FollowContacts: View {
    @EnvironmentObject var appState: AppState
    @StateObject var contactStore = ContactStore()
    @State private var selectedContacts: [CNContact] = []
    
    private var columns: [GridItem] = [
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10)
    ]
    
    @Environment(\.backgroundColor) var backgroundColor
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Text("Skip")
                    .foregroundColor(.gray)
                    .onTapGesture {
                        appState.setUserOnboarded()
                    }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 30)
            
            Text("Friends Already Here")
                .font(Font.custom(Poppins.medium, size: 24))
            
            Spacer()
            
            if contactStore.loading {
                ProgressView()
            } else if let contacts = contactStore.contacts {
                if contacts.count > 0 {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(contacts) { (contact: PublicUser) in
                                SuggestedUserView(contactStore: contactStore, contact: contact)
                            }
                        }
                        .padding(.bottom, 50)
                    }
                    
                    VStack {
                        Button(action: {
                            contactStore.follow(appState: appState)
                        }) {
                            if contactStore.following {
                                LargeButton {
                                    ProgressView()
                                }
                            } else {
                                LargeButton("Follow")
                            }
                        }
                        .disabled(contactStore.following)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 5)
                        
                        Text("Clear selection")
                            .font(Font.custom(Poppins.regular, size: 16))
                            .foregroundColor(.gray)
                            .onTapGesture {
                                contactStore.clearAll()
                            }
                        
                        Text("Select all")
                            .font(Font.custom(Poppins.regular, size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                            .onTapGesture {
                                contactStore.selectAll()
                            }
                    }
                    .padding(.top, 30)
                } else {
                    VStack {
                        Text("No contacts found on jimo. Tap next to continue.")
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 15)
                        
                        Button(action: {
                            appState.setUserOnboarded()
                        }) {
                            LargeButton("Next")
                        }
                    }
                    .padding(.horizontal, 40)
                }
            } else if let error = contactStore.error {
                if error as? APIError != nil {
                    VStack {
                        Button(action: {
                            contactStore.getExistingUsers(appState: appState)
                        }) {
                            Text("Failed to load friends, tap to try again.")
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 40)
                } else {
                    VStack {
                        Button(action: {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }) {
                            Text("Enable access to your contacts to find friends already on jimo.")
                                .multilineTextAlignment(.center)
                        }
                        Text("We value and respect your privacy. We do not store your contacts on our servers or share them with anyone else.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                            .font(.caption)
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
        .padding(.bottom, 100)
        .onAppear {
            contactStore.getExistingUsers(appState: appState)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

struct FollowContacts_Previews: PreviewProvider {
    static var previews: some View {
        FollowContacts()
    }
}
