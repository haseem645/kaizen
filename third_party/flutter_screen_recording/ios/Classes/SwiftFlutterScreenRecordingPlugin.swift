import Flutter
import ReplayKit
import UIKit

public class SwiftFlutterScreenRecordingPlugin: NSObject, FlutterPlugin {
    private enum SharedKeys {
        static let requestedFileName = "screen_recording_requested_file_name"
        static let shouldIncludeAudio = "screen_recording_should_include_audio"
        static let status = "screen_recording_status"
        static let outputPath = "screen_recording_output_path"
        static let errorMessage = "screen_recording_error_message"
    }

    private enum RecordingStatus: String {
        case idle
        case starting
        case recording
        case finishing
        case finished
        case failed
    }

    private let pollInterval: TimeInterval = 0.35
    private let stopTimeout: TimeInterval = 60

    private var isRecording = false
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_screen_recording", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterScreenRecordingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecordScreen":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String,
                  let includeAudio = args["audio"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                return
            }
            startRecording(videoName: name, recordAudio: includeAudio, result: result)
        case "stopRecordScreen":
            stopRecording(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startRecording(videoName: String, recordAudio: Bool, result: @escaping FlutterResult) {
        guard #available(iOS 12.0, *) else {
            result(FlutterError(code: "IOS_VERSION_ERROR", message: "Broadcast recording requires iOS 12 or later", details: nil))
            return
        }

        guard !isRecording else {
            result(FlutterError(code: "ALREADY_RECORDING", message: "Recording is already in progress", details: nil))
            return
        }

        guard let userDefaults = sharedDefaults() else {
            result(FlutterError(code: "APP_GROUP_ERROR", message: "Unable to access shared recording storage", details: nil))
            return
        }

        userDefaults.set(videoName, forKey: SharedKeys.requestedFileName)
        userDefaults.set(recordAudio, forKey: SharedKeys.shouldIncludeAudio)
        userDefaults.set(RecordingStatus.starting.rawValue, forKey: SharedKeys.status)
        userDefaults.removeObject(forKey: SharedKeys.outputPath)
        userDefaults.removeObject(forKey: SharedKeys.errorMessage)
        userDefaults.synchronize()

        DispatchQueue.main.async {
            guard self.toggleSystemBroadcastPicker() else {
                userDefaults.set(RecordingStatus.failed.rawValue, forKey: SharedKeys.status)
                userDefaults.set("Unable to present the iOS broadcast picker.", forKey: SharedKeys.errorMessage)
                userDefaults.synchronize()
                result(FlutterError(code: "BROADCAST_PICKER_ERROR", message: "Unable to present the iOS broadcast picker", details: nil))
                return
            }

            self.isRecording = true
            result(true)
        }
    }

    private func stopRecording(result: @escaping FlutterResult) {
        guard let userDefaults = sharedDefaults() else {
            result(FlutterError(code: "APP_GROUP_ERROR", message: "Unable to access shared recording storage", details: nil))
            return
        }

        if let resolvedPath = resolveFinishedRecordingPath(using: userDefaults) {
            isRecording = false
            result(resolvedPath)
            return
        }

        guard isRecording || storedStatus(in: userDefaults) == .recording || storedStatus(in: userDefaults) == .starting else {
            result(FlutterError(code: "NOT_RECORDING", message: "No recording in progress", details: nil))
            return
        }

        userDefaults.set(RecordingStatus.finishing.rawValue, forKey: SharedKeys.status)
        userDefaults.removeObject(forKey: SharedKeys.errorMessage)
        userDefaults.synchronize()

        waitForRecordingToFinish(startTime: Date(), userDefaults: userDefaults, result: result)
    }

    private func waitForRecordingToFinish(
        startTime: Date,
        userDefaults: UserDefaults,
        result: @escaping FlutterResult
    ) {
        if let resolvedPath = resolveFinishedRecordingPath(using: userDefaults) {
            isRecording = false
            result(resolvedPath)
            return
        }

        if storedStatus(in: userDefaults) == .failed {
            isRecording = false
            let message = userDefaults.string(forKey: SharedKeys.errorMessage) ?? "Screen recording failed"
            result(FlutterError(code: "STOP_ERROR", message: message, details: nil))
            return
        }

        if Date().timeIntervalSince(startTime) >= stopTimeout {
            isRecording = false
            result(FlutterError(code: "STOP_TIMEOUT", message: "Timed out while waiting for the recording file", details: nil))
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) {
            self.waitForRecordingToFinish(startTime: startTime, userDefaults: userDefaults, result: result)
        }
    }

    private func resolveFinishedRecordingPath(using userDefaults: UserDefaults) -> String? {
        guard storedStatus(in: userDefaults) == .finished,
              let outputPath = userDefaults.string(forKey: SharedKeys.outputPath),
              !outputPath.isEmpty else {
            return nil
        }

        let sourceURL = URL(fileURLWithPath: outputPath)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return nil
        }

        let targetDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let targetURL = targetDirectory?.appendingPathComponent(sourceURL.lastPathComponent)

        guard let finalURL = targetURL else {
            return sourceURL.path
        }

        do {
            if FileManager.default.fileExists(atPath: finalURL.path) {
                try FileManager.default.removeItem(at: finalURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: finalURL)
            return finalURL.path
        } catch {
            return sourceURL.path
        }
    }

    private func storedStatus(in userDefaults: UserDefaults) -> RecordingStatus {
        guard let rawValue = userDefaults.string(forKey: SharedKeys.status),
              let status = RecordingStatus(rawValue: rawValue) else {
            return .idle
        }
        return status
    }

    @available(iOS 12.0, *)
    private func toggleSystemBroadcastPicker() -> Bool {
        guard let viewController = topViewController(),
              let hostView = viewController.view else {
            return false
        }

        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        picker.preferredExtension = broadcastExtensionBundleIdentifier()
        picker.showsMicrophoneButton = false
        picker.alpha = 0.01
        picker.isUserInteractionEnabled = true
        hostView.addSubview(picker)

        guard let button = picker.subviews.compactMap({ $0 as? UIButton }).first else {
            picker.removeFromSuperview()
            return false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            button.sendActions(for: .touchUpInside)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak picker] in
            picker?.removeFromSuperview()
        }

        return true
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let rootController: UIViewController?
        if let base = base {
            rootController = base
        } else if #available(iOS 13.0, *) {
            let activeScene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive })
            rootController = activeScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        } else {
            rootController = UIApplication.shared.keyWindow?.rootViewController
        }

        if let navigationController = rootController as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }

        if let tabController = rootController as? UITabBarController {
            return topViewController(base: tabController.selectedViewController)
        }

        if let presented = rootController?.presentedViewController {
            return topViewController(base: presented)
        }

        return rootController
    }

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier())
    }

    private func appGroupIdentifier() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.kaizenteam"
        return "group.\(bundleIdentifier).screenrecord"
    }

    private func broadcastExtensionBundleIdentifier() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.kaizenteam"
        return "\(bundleIdentifier).broadcast"
    }
}
