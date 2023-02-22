//
//  CreatePost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import MapKit
import Combine
import PopupView

struct CreatePost: View {
    @StateObject var createPostVM = CreatePostVM()
    @Binding var presented: Bool

    var body: some View {
        CreatePostWithModel(createPostVM: createPostVM, presented: $presented)
    }
}

struct CreatePostWithModel: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @ObservedObject var createPostVM: CreatePostVM

    @Binding var presented: Bool

    func createPost() {
        hideKeyboard()
        createPostVM.createPost(appState: appState)
    }

    var body: some View {
        Navigator {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(createPostVM.createOrEdit.title)
                            .font(.system(size: 28))
                            .fontWeight(.bold)

                        Divider()

                        Button { createPostVM.activeSheet = .placeSearch } label: {
                            FormInputButton(
                                name: "Enter location",
                                content: createPostVM.name,
                                clearAction: createPostVM.resetPlace)
                        }

                        Divider()

                        CreatePostCategoryPicker(category: $createPostVM.category)
                            .ignoresSafeArea(.keyboard, edges: .bottom)

                        Group {
                            Divider()
                            Text("Add photos (max 3)")
                                .font(.system(size: 15))
                                .bold()
                            ImageSelectionView(createPostVM: createPostVM)
                        }

                        Group {
                            Divider()
                            FormInputText(
                                name: "How was it? Tag a friend using @username",
                                text: $createPostVM.content
                            ).ignoresSafeArea(.keyboard, edges: .bottom)
                        }

                        Group {
                            Divider()
                            Text("Award stars (Optional)")
                                .font(.system(size: 15))
                                .bold()
                            CreatePostStarPicker(stars: $createPostVM.stars)
                                .padding(.trailing, 10)
                        }

                        Spacer()
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .padding(.leading, 10)
            .foregroundColor(Color("foreground"))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .background(Color("background").edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .principal) {
                    Image("logo")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color("foreground"))
                        .scaledToFit()
                        .frame(width: 50)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.presented = false
                    } label: {
                        Image(systemName: "xmark").foregroundColor(Color("foreground"))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.createPost()
                    } label: {
                        if createPostVM.postingStatus == .loading {
                            ProgressView()
                        } else {
                            Text("Add").bold()
                        }
                    }.disabled(createPostVM.postingStatus == .loading)
                }
            }
            .popup(isPresented: $createPostVM.showError) {
                Toast(text: createPostVM.errorMessage, type: .error)
                    .opacity(createPostVM.showError ? 1 : 0)
            } customize: {
                $0.type(.toast).autohideIn(2)
            }
            .sheet(item: $createPostVM.activeSheet) { (activeSheet: CreatePostActiveSheet) in
                Group {
                    switch activeSheet {
                    case .placeSearch:
                        PlaceSearch(selectPlace: createPostVM.selectPlace)
                            .trackSheet(.enterLocationView, screenAfterDismiss: { .createPostSheet })
                    case .imagePicker:
                        ImagePicker { image in
                            createPostVM.uiImages.append(image)
                        }
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onChange(of: createPostVM.activeSheet) { _ in
                // Bug where if the keyboard is up and the sheet changes from image picker back to create post, tapping
                // a category is offset
                hideKeyboard()
            }
            .onChange(of: createPostVM.postingStatus) { status in
                if case let .success(post) = status {
                    self.presented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        globalViewState.setSuccess("Success!")
                    }
                }
            }
        }
    }
}

private struct FormInputButton: View {
    var name: String
    var content: String?
    var destination: AnyView?
    var clearAction: () -> Void

    @ViewBuilder var clearInputView: some View {
        Button(action: clearAction) {
            Image(systemName: "xmark.circle")
                .foregroundColor(.gray)
                .padding(.trailing)
        }
    }

    @ViewBuilder var rightArrow: some View {
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
            .padding(.trailing)
    }

    var body: some View {
        HStack {
            Group {
                if let content = content {
                    Text(name + ": ").font(.system(size: 15)).bold()
                    + Text(content).font(.system(size: 15))
                } else {
                    Text(name).font(.system(size: 15)).bold()
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            if content == nil {
                rightArrow
            } else {
                clearInputView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(Color("foreground"))
        .multilineTextAlignment(.leading)
    }
}

private struct CreatePostDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray)
            .padding(.horizontal, 15)
    }
}

private struct MapPreview: View {
    @EnvironmentObject var appState: AppState

    var category: String?
    var region: MKCoordinateRegion

    let width = UIScreen.main.bounds.width - 20
    let height: CGFloat = 200

    @State private var snapshotImage: UIImage?

    var currentUserProfilePicture: String? {
        if case let .user(user) = appState.currentUser {
            return user.profilePictureUrl
        }
        return nil
    }

    func generateSnapshot(width: CGFloat, height: CGFloat) {
        // Map options.
        let mapOptions = MKMapSnapshotter.Options()
        mapOptions.region = region
        mapOptions.size = CGSize(width: width, height: height)
        mapOptions.showsBuildings = false

        // Create the snapshotter and run it.
        let snapshotter = MKMapSnapshotter(options: mapOptions)
        snapshotter.start { (snapshotOrNil, errorOrNil) in
            if let error = errorOrNil {
                print(error)
                return
            }
            if let snapshot = snapshotOrNil {
                self.snapshotImage = snapshot.image
            }
        }
    }

    var body: some View {
        ZStack {
            Group {
                if let image = snapshotImage {
                    Image(uiImage: image)
                } else {
                    Color.init(red: 250 / 255, green: 245 / 255, blue: 241 / 255)
                }
            }

            Circle()
                .fill()
                .frame(width: 40, height: 40)
                .foregroundColor(category != nil ? Color(category!) : .gray)

            URLImage(
                url: currentUserProfilePicture,
                loading: Image(systemName: "person.crop.circle"),
                thumbnail: true
            )
            .foregroundColor(.gray)
            .frame(width: 35, height: 35)
            .background(Color.white)
            .cornerRadius(17.5)
        }
        .onAppear {
            generateSnapshot(width: width, height: height)
        }
    }
}
