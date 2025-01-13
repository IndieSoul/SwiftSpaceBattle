//
//  ContentView.swift
//  SwiftSpaceBattle
//
//  Created by Luis Enrique Rosas Espinoza on 12/01/25.
//

import SwiftUI
import SpriteKit

enum GameState {
    case game, menu
}

struct ContentView: View {
    private let gameOver = NotificationCenter.default.publisher(for: .gameOver)
    @State private var state = GameState.menu
    @State private var lastScore: Int = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch state {
            case .game:
                SpriteView(scene: GameScene.newGame())
            case .menu:
                menu
            }
        }
        .onReceive(gameOver) { notification in
            if let userInfo = notification.userInfo, let finalScore = userInfo["score"] as? Int {
                lastScore = finalScore
            }
            
            Task {
                try await Task.sleep(for: .seconds(2))
            }
            
            state = .menu
        }
        .animation(.default, value: state)
        .statusBarHidden()
    }
    
    var menu: some View {
        ZStack {
            Image(.bkgd0)
                .resizable()
                .scaledToFill()
            VStack {
                Spacer()
                Text("Swift Space Battle")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                if lastScore > 0 {
                    Text("Last Score: \(lastScore)")
                        .font(.title)
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    state = .game
                } label: {
                    Text("START")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
