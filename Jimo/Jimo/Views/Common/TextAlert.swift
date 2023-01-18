//
//  TextAlert.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/19/21.
//

import SwiftUI

struct TextAlert: UIViewControllerRepresentable {
    @State private var text = ""
    @Binding var isPresented: Bool
    var title: String
    var message: String
    var action: (String) -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<TextAlert>) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: UIViewControllerRepresentableContext<TextAlert>) {
        guard context.coordinator.alert == nil else { return }
        if isPresented {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            context.coordinator.alert = alert
            alert.addTextField { textField in
                textField.placeholder = "Details"
                textField.autocapitalizationType = .sentences
                textField.delegate = context.coordinator
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
            alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
                action(text)
                text = ""
            })
            DispatchQueue.main.async {
                viewController.present(alert, animated: true, completion: {
                    self.isPresented = false
                    context.coordinator.alert = nil
                })
            }
        }
    }

    func makeCoordinator() -> TextAlert.Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var alert: UIAlertController?
        var parent: TextAlert
        init(_ parent: TextAlert) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let text = textField.text as NSString? {
                self.parent.text = text.replacingCharacters(in: range, with: string)
            } else {
                self.parent.text = ""
            }
            return true
        }
    }
}

extension View {
    func textAlert(isPresented: Binding<Bool>, title: String, message: String, action: @escaping (String) -> Void) -> some View {
        ZStack {
            TextAlert(isPresented: isPresented, title: title, message: message, action: action)
            self
        }
    }
}
