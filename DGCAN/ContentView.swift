//
//  ContentView.swift
//  DGCAN
//
//  Created by 송하경 on 2/26/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Text("안녕!")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    ContentView()
}
