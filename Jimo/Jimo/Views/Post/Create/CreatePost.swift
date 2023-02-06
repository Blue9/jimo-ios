//
//  CreatePost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import MapKit
import Combine

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

    var buttonColor: Color {
        if let category = createPostVM.category {
            return Color(category)
        } else {
            return Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 0.9921568627))
        }
    }

    func createPost() {
        hideKeyboard()
        createPostVM.createPost(appState: appState)
    }

    var body: some View {
        Navigator {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(createPostVM.createOrEdit.title)
                            .font(.system(size: 28))
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)

                        Divider().padding(.leading, 10)

                        Group {
                            Button(action: { createPostVM.activeSheet = .placeSearch }) {
                                FormInputButton(
                                    name: "Enter location",
                                    content: createPostVM.name,
                                    clearAction: createPostVM.resetPlace)
                            }
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 10)

                        Divider().padding(.leading, 10)

                        HStack {
                            ImageSelectionView(createPostVM: createPostVM, buttonColor: buttonColor)

                            FormInputText(name: "Write a note (recommended)", text: $createPostVM.content)
                        }
                        .padding(10)
                        .ignoresSafeArea(.keyboard, edges: .bottom)

                        Divider().padding(.leading, 10)

                        CreatePostCategoryPicker(category: $createPostVM.category)
                            .padding(.vertical, 10)
                            .ignoresSafeArea(.keyboard, edges: .bottom)

//                        if let region = createPostVM.previewRegion {
//                            Group {
//                                VStack(alignment: .leading, spacing: 0) {
//                                    Text("Preview")
//                                        .font(.system(size: 15))
//                                        .bold()
//                                        .padding(10)
//
//                                    MapPreview(category: createPostVM.category, region: region)
//                                        .frame(maxWidth: .infinity)
//                                        .frame(height: 200)
//                                        .cornerRadius(2)
//                                        .padding(.horizontal, 10)
//                                }
//                            }
//                            .id(createPostVM.previewRegion)
//                        }

                        CreatePostStarPicker(stars: $createPostVM.stars)

                        Spacer()
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .foregroundColor(Color("foreground"))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .background(Color("background").edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .toolbar {
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
                            Text("Post").bold()
                        }
                    }.disabled(createPostVM.postingStatus == .loading)
                }
            }
            .popup(isPresented: $createPostVM.showError, type: .toast, autohideIn: 2) {
                Toast(text: createPostVM.errorMessage, type: .error)
                    .opacity(createPostVM.showError ? 1 : 0)
            }
            .sheet(item: $createPostVM.activeSheet) { (activeSheet: CreatePostActiveSheet) in
                Group {
                    switch activeSheet {
                    case .placeSearch:
                        PlaceSearch(selectPlace: createPostVM.selectPlace)
                            .trackSheet(.enterLocationView, screenAfterDismiss: { .createPostSheet })
                    case .imagePicker:
                        ImagePicker(image: createPostVM.uiImageBinding, allowsEditing: true)
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
                        if createPostVM.createOrEdit == .create {
                            deepLinkManager.presentableEntity = .loadedPost(post)
                        }
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
