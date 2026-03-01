//
//  ContestView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

/// 공모전 정보 목록 화면
struct ContestView: View {
    /// 파이썬/서버에서 받은 공모전 공지 배열
    let notices: [Notice]

    init(notices: [Notice] = Notice.contestSampleData) {
        self.notices = notices
    }

    var body: some View {
        NavigationStack {
            List(notices.map { 
                var n = $0
                n.category = .contest
                return n
            }) { notice in
                NavigationLink {
                    NoticeWebView(notice: notice)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(notice.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(notice.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("공모전 정보")
        }
    }
}

#Preview {
    ContestView()
}

