//
//  JobView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

struct JobView: View {
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
                        ProgressView("채용 정보를 불러오는 중...")
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
                                Task { await loadJobsAsync() }
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
                            await loadJobsAsync()
                        }
                    }
                }
                
                // 페이지네이션 컨트롤
                if !notices.isEmpty {
                    paginationControl
                }
            }
            .navigationTitle("채용 정보")
            .task {
                await loadJobsAsync()
            }
        }
    }
    
    // 페이지네이션 UI 컴포넌트
    private var paginationControl: some View {
        HStack(spacing: 15) {
            // 이전 그룹 버튼
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
            
            // 다음 그룹 버튼
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

    private func loadJobsAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchJobs()
            await MainActor.run {
                self.notices = response.items.map {
                    var notice = $0
                    notice.category = .job
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
                    self.notices = Notice.jobSampleData
                }
            }
        }
    }
}

#Preview {
    JobView()
}

