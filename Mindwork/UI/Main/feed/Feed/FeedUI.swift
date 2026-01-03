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
    @State private var selectedQuestionType: QuestionType?
    
    var body: some View {
        ZStack(alignment: .top) {
            Image("mainbackground").resizable().scaledToFill().zIndex(0.1).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

            ScrollView{
                // Subjects bölümü
//Memory
                SubjectsView(title: QuestionStringKeys.memory_title, description: QuestionStringKeys.memory_description).frame(maxWidth: .infinity,alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 16){
                        ForEach(viewModel.questionList){ question in
                            Button {
                                navigateGame(type: question.questionType)
                            } label: {
                                FeedRowUI(foregroundColor: question.foregroundColor, backgroundColor: question.backgroundColor, title: Text(question.title)).frame(width: Width.screenFourtyTwoWidth)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }.padding(.bottom)
                // Games bölümü
//Attention & Focus
                SubjectsView(title: QuestionStringKeys.attention_focus_title, description: QuestionStringKeys.attention_focus_description).frame(maxWidth: .infinity,alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 16){
                        ForEach(viewModel.gameList){ game in
                            Button {
                                navigateGame(type: game.questionType)
                            } label: {
                                FeedRowUI(foregroundColor: game.foregroundColor, backgroundColor: game.backgroundColor, title: Text(game.title)).frame(width: Width.screenFourtyTwoWidth)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
//Logic
                SubjectsView(title: QuestionStringKeys.logic_title, description: QuestionStringKeys.logic_description).frame(maxWidth: .infinity,alignment: .leading)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 16){
                        ForEach(viewModel.logicList){ game in
                            Button {
                                navigateGame(type: game.questionType)
                            } label: {
                                FeedRowUI(foregroundColor: game.foregroundColor, backgroundColor: game.backgroundColor, title: Text(game.title)).frame(width: Width.screenFourtyTwoWidth)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }.padding(.bottom,140)
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading,16).padding(.top)
                .background(
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial.opacity(0.85))
                            Color.blue.opacity(0.2)
                        }
                    )
                .clipShape(RoundedTopLeftShape(radius: 70)).padding(.top,190)
                .zIndex(1)
            /* Online
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
                })*/
        }.ignoresSafeArea().background(Color.feedBackground.opacity(0.2))
    }
    
    private func navigateGame(type: QuestionType?) {
        switch type {
        case .which_different:
            routerFeed.navigate(to: .which_different)
        case .colorful_words:
            routerFeed.navigate(to: .colorful_words)
        case .catch_pair:
            routerFeed.navigate(to: .catch_pair)
        case .firefly_title:
            routerFeed.navigate(to: .firefly_title)
        case .reflexGame:
            routerFeed.navigate(to: .reflex)
        case .wordCube:
            routerFeed.navigate(to: .word_cube)
        case .timing:
            routerFeed.navigate(to: .timing)
        case .reverse_word:
            routerFeed.navigate(to: .reverse_word)
        case .pattern_game:
            routerFeed.navigate(to: .pattern_game)
        case .missing_link:
            routerFeed.navigate(to: .missing_link)
        case .none:
            routerFeed.navigate(to: .colorful_words)
        }
    }
}

struct SubjectsView: View {
    var title: LocalizedStringKey
    var description: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading){
            tvSubtitleFont(text: title, color: .brown300)
            tvBodyline(text: description, color: Color.white).truncationMode(.head)
        }
    }
}

#Preview {
    FeedUI()
}

