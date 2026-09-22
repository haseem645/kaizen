import AVFoundation
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let trainingUploadNotificationBridge = TrainingUploadNotificationBridge()
  private let videoAudioSessionBridge = VideoAudioSessionBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    application.registerForRemoteNotifications()
    let didFinishLaunching =
      super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      trainingUploadNotificationBridge.register(with: controller.binaryMessenger)
      videoAudioSessionBridge.register(with: controller.binaryMessenger)
    }
    return didFinishLaunching
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    trainingUploadNotificationBridge.handleNotificationResponse(response)
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }
}

private final class VideoAudioSessionBridge {
  private let methodChannelName = "kaizenteams/video_audio_session"

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "prepareForPlayback":
        self.prepareForPlayback(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func prepareForPlayback(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()

    do {
      if session.category == .playAndRecord || session.category == .record {
        try session.setMode(.default)
        try session.overrideOutputAudioPort(.speaker)
        try session.setActive(true)
      }
      result(nil)
    } catch {
      // This bridge is best-effort only. Avoid surfacing route-prep failures into Flutter logs.
      result(nil)
    }
  }
}

private final class TrainingUploadNotificationBridge {
  private let methodChannelName = "kaizenteams/training_video_upload_notifications"
  private let notificationCategoryIdentifier = "training_upload_notification_category"
  private let cancelActionIdentifier = "training_upload_notification_cancel_action"
  private let pendingCancelledTaskIdsKey = "pending_cancelled_training_upload_task_ids"
  private let defaultChannelName = "Training uploads"
  private let defaultChannelDescription = "Shows progress for training video uploads."
  private let defaultCancelLabel = "Cancel"

  private var activeTaskIds = Set<Int>()

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "requestTrainingUploadNotificationPermission":
        requestPermissionIfNeeded()
        result(nil)
      case "syncTrainingUploadNotifications":
        let arguments = call.arguments as? [AnyHashable: Any] ?? [:]
        syncNotifications(arguments: arguments)
        result(nil)
      case "consumePendingCancelledTrainingUploadTaskIds":
        result(consumePendingCancelledTaskIds())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func handleNotificationResponse(_ response: UNNotificationResponse) {
    guard response.actionIdentifier == cancelActionIdentifier else {
      return
    }

    let userInfo = response.notification.request.content.userInfo
    let rawTaskId = userInfo["taskId"] as? NSNumber
    let taskId = rawTaskId?.intValue ?? (userInfo["taskId"] as? Int)
    guard let taskId else {
      return
    }

    enqueuePendingCancelledTaskId(taskId)
  }

  private func requestPermissionIfNeeded() {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      guard settings.authorizationStatus != .authorized,
        settings.authorizationStatus != .provisional
      else {
        return
      }

      center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
  }

  private func syncNotifications(arguments: [AnyHashable: Any]) {
    let channelName = arguments["channelName"] as? String ?? defaultChannelName
    let channelDescription =
      arguments["channelDescription"] as? String ?? defaultChannelDescription
    let cancelLabel = arguments["cancelLabel"] as? String ?? defaultCancelLabel
    let rawTasks = arguments["tasks"] as? [[AnyHashable: Any]] ?? []

    registerNotificationCategory(cancelLabel: cancelLabel)
    let _ = channelName
    let _ = channelDescription

    let incomingTaskIds = Set(rawTasks.compactMap { payload in
      (payload["taskId"] as? NSNumber)?.intValue ?? (payload["taskId"] as? Int)
    })
    let removedTaskIds = activeTaskIds.subtracting(incomingTaskIds)
    removedTaskIds.forEach(removeNotification)
    activeTaskIds = incomingTaskIds

    rawTasks.forEach { payload in
      guard let notificationPayload = TrainingUploadNotificationPayload(payload: payload) else {
        return
      }
      postNotification(for: notificationPayload)
    }
  }

  private func registerNotificationCategory(cancelLabel: String) {
    let action: UNNotificationAction
    if #available(iOS 15.0, *) {
      action = UNNotificationAction(
        identifier: cancelActionIdentifier,
        title: cancelLabel,
        options: [.destructive],
        icon: UNNotificationActionIcon(systemImageName: "xmark.circle")
      )
    } else {
      action = UNNotificationAction(
        identifier: cancelActionIdentifier,
        title: cancelLabel,
        options: [.destructive]
      )
    }
    let category = UNNotificationCategory(
      identifier: notificationCategoryIdentifier,
      actions: [action],
      intentIdentifiers: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])
  }

  private func postNotification(for payload: TrainingUploadNotificationPayload) {
    let content = UNMutableNotificationContent()
    content.title = payload.title
    content.body = payload.message
    content.userInfo = ["taskId": payload.taskId]
    content.threadIdentifier = "training-video-upload"
    if payload.canCancel {
      content.categoryIdentifier = notificationCategoryIdentifier
    }
    if payload.status == .completed || payload.status == .failed {
      content.sound = .default
    }

    let identifier = notificationIdentifier(for: payload.taskId)
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
    center.removeDeliveredNotifications(withIdentifiers: [identifier])

    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: nil
    )
    center.add(request)
  }

  private func removeNotification(taskId: Int) {
    let identifier = notificationIdentifier(for: taskId)
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
    center.removeDeliveredNotifications(withIdentifiers: [identifier])
  }

  private func notificationIdentifier(for taskId: Int) -> String {
    "training_upload_\(taskId)"
  }

  private func consumePendingCancelledTaskIds() -> [Int] {
    let defaults = UserDefaults.standard
    let values = defaults.array(forKey: pendingCancelledTaskIdsKey) as? [Int] ?? []
    defaults.removeObject(forKey: pendingCancelledTaskIdsKey)
    return values
  }

  private func enqueuePendingCancelledTaskId(_ taskId: Int) {
    let defaults = UserDefaults.standard
    var values = defaults.array(forKey: pendingCancelledTaskIdsKey) as? [Int] ?? []
    if !values.contains(taskId) {
      values.append(taskId)
      defaults.set(values, forKey: pendingCancelledTaskIdsKey)
    }
  }
}

private struct TrainingUploadNotificationPayload {
  enum Status: String {
    case idle
    case preparing
    case uploading
    case finalizing
    case completed
    case failed
  }

  let taskId: Int
  let status: Status
  let title: String
  let message: String
  let canCancel: Bool

  init?(payload: [AnyHashable: Any]) {
    if let taskNumber = payload["taskId"] as? NSNumber {
      taskId = taskNumber.intValue
    } else if let taskInteger = payload["taskId"] as? Int {
      taskId = taskInteger
    } else {
      return nil
    }

    guard let rawStatus = payload["status"] as? String,
      let status = Status(rawValue: rawStatus),
      let title = payload["title"] as? String,
      let message = payload["message"] as? String
    else {
      return nil
    }

    self.status = status
    self.title = title
    self.message = message
    canCancel = payload["canCancel"] as? Bool ?? false
  }
}
