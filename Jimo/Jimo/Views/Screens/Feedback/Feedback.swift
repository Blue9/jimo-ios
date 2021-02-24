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
    @Environment(\.backgroundColor) var backgroundColor
    
    @Binding var presented: Bool
    @State private var content: String = ""
    @State private var followUp: Bool = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    @State private var submitFeedbackCancellable: Cancellable? = nil
    
    private let buttonColor: Color = Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 0.9921568627))
    
    private func submitFeedback() {
        hideKeyboard()
        
        if content.count < 1 {
            errorMessage = "Feedback must include content!"
            showError = true
            return
        } else if content.count > 2500 {
            errorMessage = "Feedback is too long!"
            showError = true
            return
        }
        submitFeedbackCancellable = appState.submitFeedback(
            FeedbackRequest(contents: content, followUp: followUp))
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    errorMessage = "Failed to submit feedback."
                    showError = true
                }
            }, receiveValue: { response in
                if !response.success {
                    errorMessage = "Failed to submit feedback."
                    showError = true
                }
                content = ""
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presented = false
                }
            })
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        Group {
                            FormInputText(name: "Submit your questions, comments, feedback, bugs, or anything else you would like to share with the jimo team. ", height: 300, text: $content)
                            
                            Divider()
                                .padding(.all, 10)
                            
                            Checkbox(label: "Would you like us to follow up with you through the phone number associated with your account?", textColor: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)), boxSize: 32, selected: $followUp)
                            
                            RoundedButton(text: Text("Submit Feedback")
                                                    .font(Font.custom(Poppins.semiBold, size: 24)),
                                          action: self.submitFeedback,
                                          backgroundColor: buttonColor
                            )
                            .frame(height: 60, alignment: .center)
                            .padding(.horizontal)
                            .padding(.top, 15)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(backgroundColor))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Submit Feedback")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.presented.toggle()
                    }
                }
            })
            .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
                Toast(text: errorMessage, type: .error)
            }
            .popup(isPresented: $showSuccess, type: .toast, autohideIn: 2) {
                Toast(text: "Success!", type: .success)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
