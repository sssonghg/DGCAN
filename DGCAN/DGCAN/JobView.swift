//
//  JobView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

/// 채용 정보 목록 화면
struct JobView: View {
    /// 파이썬/서버에서 받은 채용 공지 배열
    let notices: [Notice]

    init(notices: [Notice] = Notice.jobSampleData) {
        self.notices = notices
    }

    var body: some View {
        NavigationStack {
            List(notices) { notice in
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
            .navigationTitle("채용 정보")
        }
    }
}

#Preview {
    JobView()
}

