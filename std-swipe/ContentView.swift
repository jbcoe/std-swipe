
//
//  ContentView.swift
//  std-swipe
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = PaperStore()

    var body: some View {
        SwipeView(store: store)
    }
}

#Preview {
    ContentView()
}
