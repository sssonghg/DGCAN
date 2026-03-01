//
//  ScrapView.swift
//  DGCAN
//

import SwiftUI

/// 스크랩한 공지사항 목록 화면
struct ScrapView: View {
    @StateObject private var scrapManager = ScrapManager.shared

    var body: some View {
        NavigationStack {
            if scrapManager.scrappedNotices.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("스크랩한 공지사항이 없습니다.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("공지 상세 화면의 책갈피 아이콘을 눌러\n공지사항을 저장해보세요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("스크랩")
            } else {
                List {
                    ForEach(Notice.Category.allCases.filter { $0 != .unknown }, id: \.self) { category in
                        let filteredNotices = scrapManager.scrappedNotices.filter { $0.category == category }
                        
                        if !filteredNotices.isEmpty {
                            Section(header: Text(category.rawValue).font(.headline).foregroundColor(.accentColor)) {
                                ForEach(filteredNotices) { notice in
                                    NavigationLink {
                                        NoticeWebView(notice: notice)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(notice.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)

                                            HStack {
                                                Text(notice.date)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Image(systemName: "bookmark.fill")
                                                    .foregroundColor(.orange)
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("스크랩")
            }
        }
    }
}

#Preview {
    ScrapView()
}
