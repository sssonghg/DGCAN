import Foundation
import UserNotifications

struct LocalNotificationManager {
    static let shared = LocalNotificationManager()

    func sendNotification(title: String, subtitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = .default

        // 10초 뒤에 발송 (테스트를 위해 바탕화면으로 나갈 시간을 벌어줍니다)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 발송 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 특정 카테고리의 최신 글을 확인하고 새 글이면 알림을 보냅니다.
    func checkNewNotice(category: String, topNotice: Notice) {
        let lastSeenKey = "lastSeen_\(category)"
        let lastSeenTitle = UserDefaults.standard.string(forKey: lastSeenKey)

        if let last = lastSeenTitle, last != topNotice.title {
            // 마지막으로 본 제목과 다르면 알림 발송
            sendNotification(title: "새로운 \(category)이 올라왔어요!", subtitle: topNotice.title)
        }

        // 최신 상태로 업데이트
        UserDefaults.standard.set(topNotice.title, forKey: lastSeenKey)
    }
}
