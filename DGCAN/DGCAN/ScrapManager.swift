//
//  ScrapManager.swift
//  DGCAN
//

import Foundation
import SwiftUI
import Combine

/// 스크랩 정보를 로컬(UserDefaults)에 저장하고 관리하는 매니저
@MainActor
final class ScrapManager: ObservableObject {
    static let shared = ScrapManager()
    private let storageKey = "scrapped_notices"
    
    @Published var scrappedNotices: [Notice] = []
    
    private init() {
        loadScraps()
    }
    
    /// 로컬 저장소에서 스크랩 목록 불러오기
    func loadScraps() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoder = JSONDecoder()
            scrappedNotices = try decoder.decode([Notice].self, from: data)
        } catch {
            print("Failed to load scraps: \(error)")
        }
    }
    
    /// 스크랩 목록 저장하기
    private func saveScraps() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(scrappedNotices)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save scraps: \(error)")
        }
    }
    
    /// 해당 공지가 스크랩되어 있는지 확인
    func isScrapped(_ notice: Notice) -> Bool {
        scrappedNotices.contains(where: { $0.url == notice.url })
    }
    
    /// 스크랩 추가/해제 토글
    func toggleScrap(_ notice: Notice) {
        if let index = scrappedNotices.firstIndex(where: { $0.url == notice.url }) {
            scrappedNotices.remove(at: index)
        } else {
            scrappedNotices.append(notice)
        }
        saveScraps()
    }
}
