//
//  ScholarshipView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

/// 장학 정보 목록 화면
/// 파이썬으로 https://cs.dongguk.edu/article/collegedata/list 에서 긁어온
/// JSON( title, date, url ) 배열을 Notice 배열로 디코딩해서 넘겨준다고 가정.
struct ScholarshipView: View {
    let notices: [Notice]

    init(notices: [Notice] = Notice.scholarshipSampleData) {
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
            .navigationTitle("장학 정보")
        }
    }
}

#Preview {
    ScholarshipView()
}

