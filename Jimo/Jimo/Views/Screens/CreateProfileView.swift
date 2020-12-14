//
//  CreateProfileView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/12/20.
//

import SwiftUI

struct CreateProfileView: View {
    @EnvironmentObject var model: AppModel

    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var privateAccount = false
    
    func createProfile() {
        model.signOut()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Almost there!")
            
            TextField("First name", text: $firstName)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 4))
                                .foregroundColor(.blue))
            TextField("Last name", text: $lastName)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 4))
                                .foregroundColor(.blue))
            Toggle(isOn: $privateAccount) {
                Text("Private account")
            }
            
            Button(action: createProfile) {
                Text("Create my profile (sign out)")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .green]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(25)
            }
        }
        .padding(.horizontal, 48)
        .navigationBarTitle(Text("Create profile"), displayMode: .inline)
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView().environmentObject(AppModel())
    }
}
