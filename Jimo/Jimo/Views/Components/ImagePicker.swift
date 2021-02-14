//
//  ImagePicker.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/25/20.
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    var allowsEditing: Bool = false

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if parent.allowsEditing {
                if let uiImage = info[.editedImage] as? UIImage {
                    parent.image = uiImage
                }
            } else if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            hideKeyboard()
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            hideKeyboard()
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = allowsEditing
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
}


struct ImagePicker_Previews: PreviewProvider {
    @State static var image: UIImage? = nil
    
    static var previews: some View {
        ImagePicker(image: $image)
    }
}
