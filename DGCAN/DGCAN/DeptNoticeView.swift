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
    
    // 페이지네이션 관련 상태
    @State private var currentPage = 1
    private let itemsPerPage = 10
    
    // 현재 페이지에 해당하는 데이터만 필터링
    private var paginatedNotices: [Notice] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, notices.count)
        if startIndex >= notices.count { return [] }
        return Array(notices[startIndex..<endIndex])
    }
    
    // 전체 페이지 수 계산
    private var totalPages: Int {
        let count = notices.count
        return count == 0 ? 1 : Int(ceil(Double(count) / Double(itemsPerPage)))
    }
    
    // 현재 표시할 페이지 번호들 (최대 5개씩)
    private var visiblePageNumbers: [Int] {
        let startPage = ((currentPage - 1) / 5) * 5 + 1
        let endPage = min(startPage + 4, totalPages)
        return Array(startPage...endPage)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                        List(paginatedNotices) { notice in
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
                
                // 페이지네이션 컨트롤
                if !notices.isEmpty {
                    paginationControl
                }
            }
            .navigationTitle("학부 공지")
            .task {
                await loadNoticesAsync()
            }
        }
    }
    
    // 페이지네이션 UI 컴포넌트
    private var paginationControl: some View {
        HStack(spacing: 15) {
            // 이전 그룹 버튼 (< 6 에서 1-5로 갈 때 사용)
            if visiblePageNumbers.first ?? 1 > 1 {
                Button(action: {
                    currentPage = (visiblePageNumbers.first ?? 1) - 1
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                }
            }
            
            // 페이지 번호들
            ForEach(visiblePageNumbers, id: \.self) { number in
                Button(action: {
                    currentPage = number
                }) {
                    Text("\(number)")
                        .fontWeight(currentPage == number ? .bold : .regular)
                        .foregroundColor(currentPage == number ? .white : .accentColor)
                        .frame(width: 30, height: 30)
                        .background(currentPage == number ? Color.accentColor : Color.clear)
                        .cornerRadius(5)
                }
            }
            
            // 다음 그룹 버튼 (5에서 6으로 갈 때 사용)
            if visiblePageNumbers.last ?? 1 < totalPages {
                Button(action: {
                    currentPage = (visiblePageNumbers.last ?? 1) + 1
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
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

