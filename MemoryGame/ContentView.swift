//
//  ContentView.swift
//  MemoryGame
//
//  Created by Ludlyne Alysha Janvier on 4/4/26.
//

import SwiftUI
 
// MARK: - Card Model
 
struct Card: Identifiable {
    let id: Int
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}
 
// MARK: - Content View
 
struct ContentView: View {
 
    // Emoji pool to use as card faces
    let emojiPool = ["🐶","🐱","🦊","🐸","🐼","🦋","🌸","⭐️","🍕","🎸"]
 
    @State private var cards: [Card] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var numberOfPairs: Int = 4
    @State private var score: Int = 0
    @State private var isProcessing: Bool = false  // prevents tapping during flip-back delay
 
    // Grid columns — adaptive so it scrolls nicely with more pairs
    let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]
 
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
 
                // MARK: Pair Picker
                VStack(spacing: 6) {
                    Text("Number of Pairs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Pairs", selection: $numberOfPairs) {
                        Text("2 Pairs").tag(2)
                        Text("4 Pairs").tag(4)
                        Text("6 Pairs").tag(6)
                        Text("8 Pairs").tag(8)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: numberOfPairs) {
                        resetGame()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
 
                // MARK: Score bar
                HStack {
                    Label("Score: \(score)", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Spacer()
                    Button(action: resetGame) {
                        Label("New Game", systemImage: "arrow.clockwise")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
 
                // MARK: Card Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(cards) { card in
                            CardView(card: card)
                                .aspectRatio(2/3, contentMode: .fit)
                                .onTapGesture {
                                    handleTap(on: card)
                                }
                        }
                    }
                    .padding()
                }
 
                // MARK: Win message
                if isGameWon {
                    VStack(spacing: 8) {
                        Text("🎉 You matched all pairs!")
                            .font(.title2.bold())
                        Text("Final score: \(score)")
                            .foregroundStyle(.secondary)
                        Button("Play Again", action: resetGame)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                }
            }
            .navigationTitle("Memory Game")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                resetGame()
            }
        }
    }
 
    // MARK: - Computed Properties
 
    var isGameWon: Bool {
        !cards.isEmpty && cards.allSatisfy { $0.isMatched }
    }
 
    // MARK: - Game Logic
 
    func resetGame() {
        let selected = Array(emojiPool.prefix(numberOfPairs))
        let paired = (selected + selected)          // two of each emoji
            .shuffled()
            .enumerated()
            .map { Card(id: $0.offset, content: $0.element) }
        cards = paired
        firstSelectedIndex = nil
        score = 0
        isProcessing = false
    }
 
    func handleTap(on card: Card) {
        // Ignore taps while flipping back, on already face-up/matched cards
        guard !isProcessing else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        guard !cards[index].isFaceUp, !cards[index].isMatched else { return }
 
        // Flip the tapped card face-up
        cards[index].isFaceUp = true
 
        if let first = firstSelectedIndex {
            // Second card tapped — check for match
            isProcessing = true
 
            if cards[first].content == cards[index].content {
                // Match! Hide both cards
                cards[first].isMatched = true
                cards[index].isMatched = true
                score += 2
                firstSelectedIndex = nil
                isProcessing = false
            } else {
                // No match — flip both back after a short delay
                let firstCopy = first
                let secondCopy = index
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    cards[firstCopy].isFaceUp = false
                    cards[secondCopy].isFaceUp = false
                    firstSelectedIndex = nil
                    isProcessing = false
                }
            }
        } else {
            // First card tapped — store its index
            firstSelectedIndex = index
        }
    }
}
 
// MARK: - Card View
 
struct CardView: View {
    let card: Card
 
    var body: some View {
        ZStack {
            if card.isMatched {
                // Matched cards are invisible (keep layout space)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
 
            } else if card.isFaceUp {
                // Card face
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.indigo.opacity(0.4), lineWidth: 2)
                Text(card.content)
                    .font(.system(size: 40))
 
            } else {
                // Card back
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                // Decorative pattern on back
                Image(systemName: "questionmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        // Flip animation
        .rotation3DEffect(
            .degrees(card.isFaceUp ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.spring(duration: 0.4), value: card.isFaceUp)
        .opacity(card.isMatched ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: card.isMatched)
    }
}
 
// MARK: - Preview
 
#Preview {
    ContentView()
}
