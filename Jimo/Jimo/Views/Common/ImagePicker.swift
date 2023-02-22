//
//  ImagePicker.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/25/20.
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var select: (UIImage) -> Void

    var allowsEditing: Bool = true

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            DispatchQueue.main.async {
                if self.parent.allowsEditing {
                    if let uiImage = info[.editedImage] as? UIImage {
                        self.parent.select(uiImage)
                    }
                } else if let uiImage = info[.originalImage] as? UIImage {
                    self.parent.select(uiImage)
                }
                hideKeyboard()
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            hideKeyboard()
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ImagePicker>
    ) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = allowsEditing
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: UIViewControllerRepresentableContext<ImagePicker>
    ) {}
}

struct ImagePicker_Previews: PreviewProvider {
    @State static var image: UIImage?

    static var previews: some View {
        ImagePicker(select: {_ in})
    }
}
