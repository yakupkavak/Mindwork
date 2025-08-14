//
//  FeedUI.swift
//  Tendria
//
//  Created by Yakup Kavak on 23.01.2025.
//

import SwiftUI

struct FeedUI: View {
    @EnvironmentObject var routerFeed: RouterFeed
    @StateObject var viewModel = FeedViewModel()
    @State private var showAlert = false
    @State private var selectedQuestionType: QuestionType?
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView{
                // Subjects bölümü
                SubjectsView(title: QuestionStringKeys.memory_title, description: QuestionStringKeys.memory_description).frame(maxWidth: .infinity,alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 16){
                        ForEach(viewModel.questionList){ question in
                            Button {
                                showAlert = true
                                selectedQuestionType = question.questionType
                            } label: {
                                FeedRowUI(foregroundColor: question.foregroundColor, backgroundColor: question.backgroundColor, title: Text(question.title)).frame(width: Width.screenFourtyTwoWidth)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }.padding(.bottom)
                // Games bölümü
                SubjectsView(title: QuestionStringKeys.focus_title, description: QuestionStringKeys.focus_description).frame(maxWidth: .infinity,alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 16){
                        ForEach(viewModel.gameList){ game in
                            FeedRowUI(foregroundColor: game.foregroundColor, backgroundColor: game.backgroundColor, title: Text(game.title)).frame(width: Width.screenFourtyTwoWidth)
                        }
                    }
                }
                
                SubjectsView(title: QuestionStringKeys.place_time_title, description: QuestionStringKeys.place_time_description).frame(maxWidth: .infinity,alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 16){
                        ForEach(viewModel.gameList){ game in
                            FeedRowUI(foregroundColor: game.foregroundColor, backgroundColor: game.backgroundColor, title: Text(game.title)).frame(width: Width.screenFourtyTwoWidth)
                        }
                    }
                }
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading,16).padding(.top)
                .background(Color.white).clipShape(RoundedTopLeftShape(radius: 70)).padding(.top,190)
                .customAlert(titleKey: QuestionStringKeys.question_select_title,
                             descriptionKey: QuestionStringKeys.question_select_description,
                             isPresented: $showAlert,
                             acceptText: QuestionStringKeys.question_select_online,
                             deniedText: QuestionStringKeys.question_select_offline,
                             acceptFunc: {
                    if let type = selectedQuestionType {
                        routerFeed.navigate(to: .colorful_words)
                    }
                },
                             deniedFunc: {
                    if let type = selectedQuestionType {
                        switch selectedQuestionType {
                        case .was_it_there:
                            routerFeed.navigate(to: .colorful_words)
                        case .which_different:
                            routerFeed.navigate(to: .colorful_words)
                        case .colorful_words:
                            routerFeed.navigate(to: .colorful_words)
                        case .catch_pair:
                            routerFeed.navigate(to: .colorful_words)
                        case .firefly_title:
                            routerFeed.navigate(to: .colorful_words)
                        case nil:
                            routerFeed.navigate(to: .colorful_words)
                        }
                    }
                })
            
        }.ignoresSafeArea().background(Color.feedBackground)
    }
}

struct SubjectsView: View {
    var title: LocalizedStringKey
    var description: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading){
            tvSubtitleFont(text: title, color: .blue)
            tvBodyline(text: description, color: .gray).truncationMode(.head)
        }
    }
}

#Preview {
    FeedUI()
}

