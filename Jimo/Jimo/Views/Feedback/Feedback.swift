//
//  Feedback.swift
//  Jimo
//
//  Created by Jeff Rohlman on 2/21/21.
//

import SwiftUI
import Combine

struct Feedback: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @StateObject var viewModel = ViewModel()

    private let buttonColor: Color = Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 0.9921568627))

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Group {
                    FormInputText(
                        name: "Submit your questions, comments, feedback, bugs, or anything else " +
                            "you would like to share with the Jimo team. You can also reach us on Instagram @jimoapp " +
                            "or email us at hello@jimoapp.com.",
                        height: 300,
                        text: $viewModel.content
                    ).padding(.horizontal, 10)

                    Divider()
                        .padding(.all, 10)

                    Checkbox(
                        label: "Would you like us to follow up with you? " +
                            "Someone on our team will text you using the phone number associated with your account.",
                        boxSize: 32,
                        selected: $viewModel.followUp
                    )

                    RoundedButton(
                        text: Text("Submit Feedback").font(.system(size: 24)),
                        action: { viewModel.submitFeedback(appState: appState, viewState: viewState) },
                        backgroundColor: buttonColor
                    )
                    .frame(height: 60, alignment: .center)
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 20)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    hideKeyboard()
                }
                .foregroundColor(.blue)
            }
        }
        .background(Color("background").edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .navigationTitle(Text("Submit Feedback"))
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

extension Feedback {
    class ViewModel: ObservableObject {
        @Published var content: String = ""
        @Published var followUp: Bool = true

        private var cancelBag: Set<AnyCancellable> = .init()

        func submitFeedback(appState: AppState, viewState: GlobalViewState) {
            hideKeyboard()

            if content.count < 1 {
                viewState.setError("Feedback must include content!")
                return
            } else if content.count > 2500 {
                viewState.setError("Feedback is too long!")
                return
            }
            appState.submitFeedback(
                FeedbackRequest(contents: content, followUp: followUp))
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    viewState.setError("Failed to submit feedback.")
                }
            }, receiveValue: { [weak self] response in
                if !response.success {
                    viewState.setError("Failed to submit feedback.")
                }
                self?.content = ""
                viewState.setSuccess("Submitted feedback!")
            })
            .store(in: &cancelBag)
        }
    }
}
