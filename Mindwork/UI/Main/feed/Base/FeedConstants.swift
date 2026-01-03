//
//  FeedConstants.swift
//  Tendria
//
//  Created by Yakup Kavak on 1.08.2025.
//

import SwiftUI

let gamesTitles: [QuestionLocalModel] = [
    QuestionLocalModel(
        questionType: .which_different,
        title: QuestionStringKeys.which_different,
        foregroundColor: Color(hex: "#F2AEAE"),
        backgroundColor: Color(hex: "#D95FA2")
    ),
    QuestionLocalModel(
        questionType: .colorful_words,
        title: QuestionStringKeys.colorful_words,
        foregroundColor: Color(hex: "#BF8A49"),
        backgroundColor: Color(hex: "#252617")
    ),
    QuestionLocalModel(
        questionType: .reflexGame,
        title: QuestionStringKeys.reflex_title,
        foregroundColor: Color(hex: "#252617"),
        backgroundColor: Color(hex: "#BF8A49")
    ),
    QuestionLocalModel(
        questionType: .timing,
        title: QuestionStringKeys.timing_title,
        foregroundColor: Color(hex: "#2B4C7E"),
        backgroundColor: Color(hex: "#BFD7ED")
    )
]

let questionTitles: [QuestionLocalModel] = [
    QuestionLocalModel(
        questionType: .firefly_title,
        title: QuestionStringKeys.firefly_title,
        foregroundColor: Color(hex: "#F2AEAE"),
        backgroundColor: Color(hex: "#D95FA2")
    ),
    QuestionLocalModel(
        questionType: .missing_link, // Enum'a eklediğini varsayıyorum
        title: QuestionStringKeys.missing_link_title,
        foregroundColor: Color(hex: "#46A094"),
        backgroundColor: Color(hex: "#C4E8C2") // İndigo/Mor tonu
    ),
    QuestionLocalModel(
        questionType: .catch_pair,
        title: QuestionStringKeys.catch_pair,
        foregroundColor: Color(hex: "#607EA6"),
        backgroundColor: Color(hex: "#253759")
    ),
    QuestionLocalModel(
        questionType: .wordCube,
        title: QuestionStringKeys.word_cube_title,
        foregroundColor: Color(hex: "#D95FA2"),
        backgroundColor: Color(hex: "#F2AEAE")
    )
]
let logicQuestionTitles: [QuestionLocalModel] = [
    QuestionLocalModel(
        questionType: .pattern_game, //
        title: QuestionStringKeys.pattern_game_title,
        foregroundColor: Color(hex: "#3B7197"),
        backgroundColor: Color(hex: "#A1E1FA") // Turuncu tonu
    ),
    QuestionLocalModel(
        questionType: .reverse_word,
        title: QuestionStringKeys.reverse_word_title,
        foregroundColor: Color(hex: "#FFA44D"),
        backgroundColor: Color(hex: "#F6C28B")
     )
    
]
