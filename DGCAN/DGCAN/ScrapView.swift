//
//  ScrapView.swift
//  DGCAN
//

import SwiftUI

/// 스크랩한 공지사항 목록 화면
struct ScrapView: View {
    @StateObject private var scrapManager = ScrapManager.shared
    @State private var selectedCategory: Notice.Category = .dept // 기본값을 '학부 공지'로 설정 (nil 제거)
    
    // 페이지네이션 관련 상태
    @State private var currentPage = 1
    private let itemsPerPage = 10

    // 현재 선택된 카테고리와 페이지에 맞는 데이터 필터링
    private var filteredAndPaginatedNotices: [Notice] {
        let filtered = scrapManager.scrappedNotices.filter { notice in
            notice.category == selectedCategory
        }
        
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filtered.count)
        
        if startIndex >= filtered.count { return [] }
        return Array(filtered[startIndex..<endIndex])
    }
    
    // 전체 페이지 수 계산
    private var totalPages: Int {
        let filteredCount = scrapManager.scrappedNotices.filter { notice in
            notice.category == selectedCategory
        }.count
        return filteredCount == 0 ? 1 : Int(ceil(Double(filteredCount) / Double(itemsPerPage)))
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
                if scrapManager.scrappedNotices.isEmpty {
                    emptyStateView
                } else {
                    // 상단 필터 칩
                    categoryFilterHeader
                    
                    List {
                        // 선택된 카테고리의 아이템들을 섹션으로 표시
                        Section(header: Text(selectedCategory.rawValue).font(.headline).foregroundColor(.accentColor)) {
                            let items = filteredAndPaginatedNotices
                            if items.isEmpty {
                                Text("\(selectedCategory.rawValue)에 스크랩한 내역이 없습니다.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 10)
                            } else {
                                ForEach(items) { notice in
                                    scrapRow(notice: notice)
                                }
                            }
                        }
                    }
                    
                    // 페이지네이션 컨트롤 (아이템이 있을 때만 표시)
                    if totalPages > 1 && !filteredAndPaginatedNotices.isEmpty {
                        paginationControl
                    }
                }
            }
            .navigationTitle("스크랩")
            .onChange(of: selectedCategory) { _ in
                currentPage = 1 // 카테고리 변경 시 1페이지로 리셋
            }
        }
    }

    // MARK: - Components

    private var paginationControl: some View {
        HStack(spacing: 15) {
            if (visiblePageNumbers.first ?? 1) > 1 {
                Button(action: { currentPage = (visiblePageNumbers.first ?? 1) - 1 }) {
                    Image(systemName: "chevron.left").foregroundColor(.accentColor)
                }
            }
            
            ForEach(visiblePageNumbers, id: \.self) { number in
                Button(action: { currentPage = number }) {
                    Text("\(number)")
                        .fontWeight(currentPage == number ? .bold : .regular)
                        .foregroundColor(currentPage == number ? .white : .accentColor)
                        .frame(width: 30, height: 30)
                        .background(currentPage == number ? Color.accentColor : Color.clear)
                        .cornerRadius(5)
                }
            }
            
            if (visiblePageNumbers.last ?? 1) < totalPages {
                Button(action: { currentPage = (visiblePageNumbers.last ?? 1) + 1 }) {
                    Image(systemName: "chevron.right").foregroundColor(.accentColor)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var categoryFilterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 나머지 카테고리 버튼들
                ForEach(Notice.Category.allCases.filter { $0 != .unknown }, id: \.self) { category in
                    filterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private func scrapRow(notice: Notice) -> some View {
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

    private var emptyStateView: some View {
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
    }
}

#Preview {
    ScrapView()
}
