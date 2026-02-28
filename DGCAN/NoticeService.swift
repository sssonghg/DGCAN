//
//  NoticeService.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import Foundation

/// 서버에서 내려주는 공지사항 응답 구조체
struct NoticeResponse: Decodable {
    let items: [Notice]
    let totalCount: Int
    let page: Int
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case items, page
        case hasNext = "has_next"
        case totalCount = "total_count"
    }
}

/// 서버에서 공지사항을 가져오는 서비스
final class NoticeService {
    /// 서버 기본 URL (맥북에서 서버 실행 시 본인 맥북의 로컬 IP로 변경 필요)
    /// 예: "http://192.168.0.100:5000" (시뮬레이터는 localhost 가능)
    #if targetEnvironment(simulator)
    private let baseURL = "http://localhost:5000"
    #else
    // 실기기에서는 맥북의 로컬 IP 주소로 변경 필요
    // 터미널에서 `ifconfig | grep "inet "` 실행해서 en0의 inet 주소 확인
    private let baseURL = "http://192.168.0.100:5000"  // 여기를 본인 맥북 IP로 변경!
    #endif

    /// 학부 공지 사항을 서버에서 페이지 단위로 가져오기
    func fetchNotices(page: Int = 1) async throws -> NoticeResponse {
        var components = URLComponents(string: "\(baseURL)/notices")
        components?.queryItems = [URLQueryItem(name: "page", value: "\(page)")]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(NoticeResponse.self, from: data)
        return result
    }
}
