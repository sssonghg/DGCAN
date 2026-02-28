//
//  DeptNoticeView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

/// 파이썬에서 내려주는 JSON 배열:
/// [{ "title": "...", "date": "YYYY-MM-DD", "url": "https://..." }, ...]
struct Notice: Identifiable, Decodable {
    let id = UUID()
    let title: String
    let date: String
    let url: String

    private enum CodingKeys: String, CodingKey {
        case title, date, url
    }
}

extension Notice {
    /// 학부 공지 샘플 데이터
    static let deptSampleData: [Notice] = [
        Notice(
            title: "2026-1학기 SW연계전공 <튜터> 지원 공고(~3/9(월)오전10시까지)",
            date: "2026-02-25",
            url: "https://cs.dongguk.edu/article/notice/detail/226"
        ),
        Notice(
            title: "2026학년도 1학기 종합설계1(CSC4018) 05분반 추가 개설 및 수강 정원 증원",
            date: "2026-02-25",
            url: "https://cs.dongguk.edu/article/notice/detail/225"
        )
    ]

    /// 장학 정보 샘플 데이터 (https://cs.dongguk.edu/article/collegedata/list 기준)
    static let scholarshipSampleData: [Notice] = [
        Notice(
            title: "SW산학연지협력장학 인턴십 장학생 선발 공고",
            date: "2025-11-21",
            url: "https://cs.dongguk.edu/article/collegedata/detail/8"
        ),
        Notice(
            title: "2025학년도 컴퓨터공학과 동창회 장학생 선발 공고",
            date: "2025-11-20",
            url: "https://cs.dongguk.edu/article/collegedata/detail/7"
        )
    ]

    /// 공모전 정보 샘플 데이터 (https://cs.dongguk.edu/article/etc/list 기준, 예시)
    static let contestSampleData: [Notice] = [
        Notice(
            title: "2024 퀀텀 챌린지(해커톤) 안내",
            date: "2024-10-15",
            url: "https://cs.dongguk.edu/article/etc/detail/2"
        ),
        Notice(
            title: "제4회 나의 세상을 바꾼 인생교양강좌 수강 수기 공모전 시행 안내",
            date: "2024-10-31",
            url: "https://cs.dongguk.edu/article/etc/detail/3"
        )
    ]

    /// 채용 정보 샘플 데이터 (https://cs.dongguk.edu/article/job/list 기준, 예시)
    static let jobSampleData: [Notice] = [
        Notice(
            title: "2026년 1분기 소프트웨어 엔지니어 신입 채용",
            date: "2026-02-20",
            url: "https://cs.dongguk.edu/article/job/detail/10"
        ),
        Notice(
            title: "AI 연구 인턴십 채용 안내",
            date: "2026-02-10",
            url: "https://cs.dongguk.edu/article/job/detail/9"
        )
    ]
}

struct DeptNoticeView: View {
    private let service = NoticeService()
    @State private var notices: [Notice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 페이징 관련 상태
    @State private var currentPage = 1
    @State private var totalCount = 0
    private let perPage = 10

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
                            loadPage(currentPage)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(notices) { notice in
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
                        
                        // 리스트 맨 아래에 페이지네이션 컨트롤 삽입
                        if totalCount > perPage {
                            Section {
                                paginationControl
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets())
                            }
                        }
                    }
                    .refreshable {
                        await fetchNotices(page: currentPage)
                    }
                }
            }
            .navigationTitle("학부 공지")
            .task {
                if notices.isEmpty {
                    await fetchNotices(page: 1)
                }
            }
        }
    }

    // 페이지 번호 버튼들이 있는 뷰 (원래 스타일 유지하며 리스트 내부에 배치)
    private var paginationControl: some View {
        let totalPages = max(1, Int(ceil(Double(totalCount) / Double(perPage))))
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Spacer(minLength: 10)
                ForEach(1...totalPages, id: \.self) { page in
                    Button {
                        loadPage(page)
                    } label: {
                        Text("\(page)")
                            .font(.headline)
                            .foregroundColor(currentPage == page ? .white : .accentColor)
                            .frame(width: 40, height: 40)
                            .background(currentPage == page ? Color.accentColor : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.accentColor, lineWidth: 1)
                            )
                    }
                }
                Spacer(minLength: 10)
            }
            .padding(.vertical, 20)
        }
    }

    private func loadPage(_ page: Int) {
        Task {
            await fetchNotices(page: page)
        }
    }

    private func fetchNotices(page: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchNotices(page: page)
            await MainActor.run {
                self.notices = response.items
                self.totalCount = response.totalCount
                self.currentPage = page
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "서버 연결 실패\n\n맥북에서 서버가 실행 중인지 확인하세요:\npython3 server.py\n\n에러: \(error.localizedDescription)"
                self.isLoading = false
                // 서버 연결 실패 시 샘플 데이터로 폴백
                if self.notices.isEmpty {
                    self.notices = Notice.deptSampleData
                    self.totalCount = Notice.deptSampleData.count
                }
            }
        }
    }
}

#Preview {
    DeptNoticeView()
}

