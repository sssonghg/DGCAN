//
//  JobView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI

struct JobView: View {
    @State private var notices: [Notice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 페이지네이션 관련 상태
    @State private var currentPage = 1
    @State private var totalItems = 0
    private let itemsPerPage = 10
    private let pagesPerBlock = 5
    
    private let service = NoticeService()
    
    // 현재 블록의 시작 페이지 계산
    private var startPageOfBlock: Int {
        ((currentPage - 1) / pagesPerBlock) * pagesPerBlock + 1
    }
    
    // 전체 페이지 수 계산
    private var totalPages: Int {
        max(1, (totalItems + itemsPerPage - 1) / itemsPerPage)
    }
    
    // 현재 블록의 마지막 페이지 계산
    private var endPageOfBlock: Int {
        min(startPageOfBlock + pagesPerBlock - 1, totalPages)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading && notices.isEmpty {
                    Spacer()
                    ProgressView("채용 정보를 불러오는 중...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("다시 시도") {
                            loadJobs(page: currentPage)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        // 공지사항 목록
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
                    }
                    .listStyle(.plain)
                    .refreshable {
                        loadJobs(page: 1)
                    }
                    
                    // 블록 기반 페이지네이션 하단 바
                    paginationFooter
                }
            }
            .navigationTitle("채용 정보")
            .onAppear {
                if notices.isEmpty {
                    loadJobs(page: 1)
                }
            }
        }
    }
    
    // 페이지네이션 UI
    private var paginationFooter: some View {
        HStack(spacing: 15) {
            // 이전 블록 이동 (<)
            Button(action: {
                let prevBlockPage = startPageOfBlock - 1
                loadJobs(page: prevBlockPage)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(startPageOfBlock > 1 ? .blue : .gray)
                    .frame(width: 30, height: 30)
            }
            .disabled(startPageOfBlock <= 1)
            
            // 숫자 페이지 버튼들
            ForEach(startPageOfBlock...endPageOfBlock, id: \.self) { page in
                Button(action: {
                    loadJobs(page: page)
                }) {
                    Text("\(page)")
                        .fontWeight(currentPage == page ? .bold : .regular)
                        .foregroundColor(currentPage == page ? .white : .blue)
                        .frame(width: 30, height: 30)
                        .background(currentPage == page ? Color.blue : Color.clear)
                        .cornerRadius(15)
                }
            }
            
            // 다음 블록 이동 (>)
            Button(action: {
                let nextBlockPage = endPageOfBlock + 1
                loadJobs(page: nextBlockPage)
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(endPageOfBlock < totalPages ? .blue : .gray)
                    .frame(width: 30, height: 30)
            }
            .disabled(endPageOfBlock >= totalPages)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.95))
    }

    private func loadJobs(page: Int) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await service.fetchJobs(page: page)
                await MainActor.run {
                    self.notices = response.items
                    self.totalItems = response.totalCount
                    self.currentPage = page
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "데이터를 가져오지 못했습니다.\n\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    JobView()
}

