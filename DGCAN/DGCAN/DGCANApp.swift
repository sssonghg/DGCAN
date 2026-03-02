//
//  DGCANApp.swift
//  DGCAN
//
//  Created by 송하경 on 2/26/26.
//

import SwiftUI
import UserNotifications

@main
struct DGCANApp: App {
    init() {
        requestNotificationPermission()
        // 앱이 켜져 있을 때도 알림을 보여주기 위한 델리게이트 설정
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else if let error = error {
                print("알림 권한 에러: \(error.localizedDescription)")
            }
        }
    }
}

// 포그라운드(앱 사용 중)일 때도 알림을 띄우기 위한 대리자 클래스
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱 사용 중에도 배너와 소리가 나오도록 설정
        completionHandler([.banner, .list, .sound])
    }
}
