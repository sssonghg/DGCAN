//
//  ContentView.swift
//  DGCAN
//
//  Created by 송하경 on 2/26/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DeptNoticeView()
                .tabItem {
                    Label("학부 공지", systemImage: "doc.text")
                }

            ScholarshipView()
                .tabItem {
                    Label("장학 정보", systemImage: "graduationcap")
                }

            ContestView()
                .tabItem {
                    Label("공모전 정보", systemImage: "trophy")
                }

            JobView()
                .tabItem {
                    Label("채용 정보", systemImage: "briefcase")
                }
        }
    }
}

#Preview {
    ContentView()
}
