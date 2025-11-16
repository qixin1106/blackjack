//
//  ContentView.swift
//  blackjack
//
//  Created by Michael Nguyen on 2021/02/13.
//

import SwiftUI

struct ContentView: View {
    
    //Todo - Initialsise in a repository to manage state
    @State var message: String = "Press deal to start."
    @State var deck = loadJson(withFilename: "deck_of_cards")
    @State var player = Status()
    @State var dealer = Status()
    @State var gameState = GameState.reset
    
    var body: some View {
        VStack {
            
            //Score displays at top
            Spacer()
                .frame(height: CGFloat(20))
            
            ScoreDisplay(player: $player, dealer: $dealer, gameState: $gameState)
            
            Spacer()
                .frame(height: CGFloat(20))
            
            //3D Scene View
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                BlackjackSceneView(
                    playerHand: $player.hand,
                    dealerHand: $dealer.hand,
                    gameState: $gameState
                )
                .frame(height: 500)
                .cornerRadius(10)
                .padding()
                
                // Message overlay
                MessageDisplay(message: $message)
            }
            
            Spacer()
                .frame(height: CGFloat(20))
            
            //Buttons display at bottom
            OptionButtons(gameState: $gameState, message: $message, deck: $deck, player: $player, dealer: $dealer)
            
            Spacer()
                .frame(height: CGFloat(20))
            
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}



