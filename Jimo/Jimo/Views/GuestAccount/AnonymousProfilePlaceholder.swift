//
//  AnonymousProfilePlaceholder.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI

struct AnonymousProfilePlaceholder: View {
    private let columns: [GridItem] = [
        GridItem(.flexible(minimum: 50), spacing: 2),
        GridItem(.flexible(minimum: 50), spacing: 2),
        GridItem(.flexible(minimum: 50), spacing: 2)
    ]

    @State private var colors = [
        "food", "food", "activity",
        "nightlife", "shopping", "attraction",
        "lodging", "nightlife", "activity"
    ]

    var profileGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                AnonymousProfileHeaderView().padding(.bottom, 10)
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(colors.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 0) {
                            GeometryReader { geometry in
                                Rectangle()
                                    .foregroundColor(Color(colors[i]).opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(2)
                            .padding(.bottom, 5)

                            Text("Place name")
                                .font(.system(size: 12))
                                .bold()
                                .lineLimit(1)

                            Text("New York City")
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .padding(.bottom, 10)
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            colors.shuffle()
        }
        .font(.system(size: 15))
    }

    var body: some View {
        profileGrid
    }
}

private struct AnonymousProfileHeaderView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Circle()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80, alignment: .center)
                    .font(Font.title.weight(.light))
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .cornerRadius(40)
                    .padding(.trailing)
                AnonymousProfileStatsView()
            }.padding(.leading, 20)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("username")
                        .font(.system(size: 15))
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("My Display Name")
                        .font(.system(size: 15))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(Color("foreground"))
                .frame(width: 120, alignment: .topLeading)
                .frame(minHeight: 40)

                Spacer()

                Text("Follow")
                    .padding(10)
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(2)
                    .foregroundColor(.gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .frame(height: 30)

                // Cannot share blocked user profile
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .offset(y: -2)
                    .padding(.horizontal)
            }.padding(.leading, 20)

            currentUserHeader.padding(.top)
        }
        .background(Color("background"))
    }

    @ViewBuilder
    fileprivate func headerButtonText(
        _ dest: Profile.Destination,
        _ text: String,
        _ buttonImage: String? = nil
    ) -> some View {
        HStack(spacing: 3) {
            if let buttonImage = buttonImage {
                Image(systemName: buttonImage)
                    .font(.system(size: 12))
            }
            Text(text)
                .font(.caption)
                .bold()
        }
        .padding(.leading)
        .padding(.trailing)
        .padding(.vertical, 8)
        .background(Color("foreground").opacity(0.15))
        .cornerRadius(2)
    }

    @ViewBuilder
    var currentUserHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                headerButtonText(.editProfile, "Edit profile", "square.and.pencil")
                headerButtonText(.submitFeedback, "Submit feedback", nil)
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct AnonymousProfileStatsView: View {
    var body: some View {
        HStack {
            Text("**22**\nPosts")
                .padding(.leading, 15)
                .padding(.trailing, 10)
            Spacer()
            Text("**65**\nFollowers")
                .padding(.trailing, 10)
            Spacer()
            Text("**84**\nFollowing")
            Spacer()
        }
        .font(.system(size: 15))
        .foregroundColor(Color("foreground"))
    }
}
