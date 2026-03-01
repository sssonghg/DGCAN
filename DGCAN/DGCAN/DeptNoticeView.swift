//
//  DeptNoticeView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

/// 파이썬에서 내려주는 JSON 배열:
/// [{ "title": "...", "date": "YYYY-MM-DD", "url": "https://..." }, ...]
struct Notice: Identifiable, Codable, Equatable {
    enum Category: String, Codable, CaseIterable {
        case dept = "학부 공지"
        case scholarship = "장학 정보"
        case contest = "공모전 정보"
        case job = "채용 정보"
        case unknown = "기타"
    }

    let id: UUID
    let title: String
    let date: String
    let url: String
    var category: Category

    init(id: UUID = UUID(), title: String, date: String, url: String, category: Category = .unknown) {
        self.id = id
        self.title = title
        self.date = date
        self.url = url
        self.category = category
    }

    private enum CodingKeys: String, CodingKey {
        case title, date, url, category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(String.self, forKey: .date)
        self.url = try container.decode(String.self, forKey: .url)
        self.category = try container.decodeIfPresent(Category.self, forKey: .category) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(url, forKey: .url)
        try container.encode(category, forKey: .category)
    }
}

extension Notice {
    /// 학부 공지 샘플 데이터
    static let deptSampleData: [Notice] = [
        Notice(
            title: "2026-1학기 SW연계전공 <튜터> 지원 공고(~3/9(월)오전10시까지)",
            date: "2026-02-25",
            url: "https://cs.dongguk.edu/article/notice/detail/226",
            category: .dept
        ),
        Notice(
            title: "2026학년도 1학기 종합설계1(CSC4018) 05분반 추가 개설 및 수강 정원 증원",
            date: "2026-02-25",
            url: "https://cs.dongguk.edu/article/notice/detail/225",
            category: .dept
        )
    ]

    /// 장학 정보 샘플 데이터 (https://cs.dongguk.edu/article/collegedata/list 기준)
    static let scholarshipSampleData: [Notice] = [
        Notice(
            title: "SW산학연지협력장학 인턴십 장학생 선발 공고",
            date: "2025-11-21",
            url: "https://cs.dongguk.edu/article/collegedata/detail/8",
            category: .scholarship
        ),
        Notice(
            title: "2025학년도 컴퓨터공학과 동창회 장학생 선발 공고",
            date: "2025-11-20",
            url: "https://cs.dongguk.edu/article/collegedata/detail/7",
            category: .scholarship
        )
    ]

    /// 공모전 정보 샘플 데이터 (https://cs.dongguk.edu/article/etc/list 기준, 예시)
    static let contestSampleData: [Notice] = [
        Notice(
            title: "2024 퀀텀 챌린지(해커톤) 안내",
            date: "2024-10-15",
            url: "https://cs.dongguk.edu/article/etc/detail/2",
            category: .contest
        ),
        Notice(
            title: "제4회 나의 세상을 바꾼 인생교양강좌 수강 수기 공모전 시행 안내",
            date: "2024-10-31",
            url: "https://cs.dongguk.edu/article/etc/detail/3",
            category: .contest
        )
    ]

    /// 채용 정보 샘플 데이터 (https://cs.dongguk.edu/article/job/list 기준, 예시)
    static let jobSampleData: [Notice] = [
        Notice(
            title: "2026년 1분기 소프트웨어 엔지니어 신입 채용",
            date: "2026-02-20",
            url: "https://cs.dongguk.edu/article/job/detail/10",
            category: .job
        ),
        Notice(
            title: "AI 연구 인턴십 채용 안내",
            date: "2026-02-10",
            url: "https://cs.dongguk.edu/article/job/detail/9",
            category: .job
        )
    ]
}

struct DeptNoticeView: View {
    private let service = NoticeService()
    @State private var notices: [Notice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("공지사항 불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("오류 발생")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("다시 시도") {
                            loadNotices()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                    .refreshable {
                        await loadNoticesAsync()
                    }
                }
            }
            .navigationTitle("학부 공지")
            .task {
                // 앱 켤 때마다 자동으로 공지사항 로드
                await loadNoticesAsync()
            }
        }
    }

    private func loadNotices() {
        Task {
            await loadNoticesAsync()
        }
    }

    private func loadNoticesAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchNotices(page: 1)
            await MainActor.run {
                self.notices = response.items.map {
                    var notice = $0
                    notice.category = .dept
                    return notice
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "서버 연결 실패\n\n맥북에서 서버가 실행 중인지 확인하세요:\npython3 server.py\n\n에러: \(error.localizedDescription)"
                self.isLoading = false
                // 서버 연결 실패 시 샘플 데이터로 폴백
                if self.notices.isEmpty {
                    self.notices = Notice.deptSampleData
                }
            }
        }
    }
}

#Preview {
    DeptNoticeView()
}

