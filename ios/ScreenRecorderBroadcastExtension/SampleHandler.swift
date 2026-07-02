import AVFoundation
import ReplayKit

final class SampleHandler: RPBroadcastSampleHandler {
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

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var outputURL: URL?
    private var includeMicrophoneAudio = false
    private var didFinishWriting = false

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        didFinishWriting = false
        includeMicrophoneAudio = sharedDefaults()?.bool(forKey: SharedKeys.shouldIncludeAudio) ?? false

        guard prepareOutputURL() else {
            finishWithFailure(message: "Unable to prepare the shared recording file.")
            return
        }

        setStatus(.recording)
    }

    override func broadcastPaused() {}

    override func broadcastResumed() {}

    override func broadcastFinished() {
        finishWritingIfNeeded(status: .finished, errorMessage: nil)
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            return
        }

        if currentStatus() == .finishing {
            completeBroadcastFromHostStop()
            return
        }

        switch sampleBufferType {
        case .video:
            appendVideoSample(sampleBuffer)
        case .audioMic:
            if includeMicrophoneAudio {
                appendAudioSample(sampleBuffer)
            }
        case .audioApp:
            break
        @unknown default:
            break
        }
    }

    private func completeBroadcastFromHostStop() {
        finishWritingIfNeeded(status: .finished, errorMessage: nil)
        finishBroadcastWithError(
            NSError(
                domain: "ScreenRecorderBroadcastExtension",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Screen recording stopped"]
            )
        )
    }

    private func appendVideoSample(_ sampleBuffer: CMSampleBuffer) {
        do {
            try ensureWriterStarted(with: sampleBuffer)
        } catch {
            finishWithFailure(message: error.localizedDescription)
            return
        }

        guard let writer, let videoInput else {
            return
        }

        if writer.status == .writing, videoInput.isReadyForMoreMediaData {
            videoInput.append(sampleBuffer)
        }
    }

    private func appendAudioSample(_ sampleBuffer: CMSampleBuffer) {
        guard let writer, let audioInput, writer.status == .writing, audioInput.isReadyForMoreMediaData else {
            return
        }

        audioInput.append(sampleBuffer)
    }

    private func ensureWriterStarted(with sampleBuffer: CMSampleBuffer) throws {
        if writer == nil {
            try buildWriter(from: sampleBuffer)
        }

        guard let writer else {
            throw NSError(domain: "ScreenRecorderBroadcastExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "The broadcast writer could not be created."])
        }

        if writer.status == .unknown {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer.startWriting()
            writer.startSession(atSourceTime: presentationTime)
        }

        if writer.status == .failed {
            throw writer.error ?? NSError(domain: "ScreenRecorderBroadcastExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "The broadcast writer failed to start."])
        }
    }

    private func buildWriter(from sampleBuffer: CMSampleBuffer) throws {
        guard let outputURL,
              let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            throw NSError(domain: "ScreenRecorderBroadcastExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing video format information."])
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let compressionSettings: [String: Any] = [
            AVVideoAverageBitRateKey: max(Int(dimensions.width) * Int(dimensions.height) * 6, 2_000_000),
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        ]

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height),
            AVVideoCompressionPropertiesKey: compressionSettings,
        ]

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true

        if writer.canAdd(videoInput) {
            writer.add(videoInput)
        }

        var audioInput: AVAssetWriterInput?
        if includeMicrophoneAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128_000,
            ]
            let candidate = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            candidate.expectsMediaDataInRealTime = true
            if writer.canAdd(candidate) {
                writer.add(candidate)
                audioInput = candidate
            }
        }

        self.writer = writer
        self.videoInput = videoInput
        self.audioInput = audioInput
    }

    private func prepareOutputURL() -> Bool {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier()) else {
            return false
        }

        let recordingsDirectory = containerURL.appendingPathComponent("ScreenRecordings", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: recordingsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            return false
        }

        let requestedName = sharedDefaults()?.string(forKey: SharedKeys.requestedFileName)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = (requestedName?.isEmpty == false ? requestedName! : "screen_recording_\(Int(Date().timeIntervalSince1970))")
            .replacingOccurrences(of: "/", with: "_")
        let targetURL = recordingsDirectory.appendingPathComponent("\(safeName).mp4")

        if FileManager.default.fileExists(atPath: targetURL.path) {
            try? FileManager.default.removeItem(at: targetURL)
        }

        outputURL = targetURL
        sharedDefaults()?.removeObject(forKey: SharedKeys.outputPath)
        sharedDefaults()?.removeObject(forKey: SharedKeys.errorMessage)
        sharedDefaults()?.synchronize()
        return true
    }

    private func finishWritingIfNeeded(status: RecordingStatus, errorMessage: String?) {
        guard !didFinishWriting else {
            return
        }
        didFinishWriting = true

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        guard let writer else {
            if status == .finished, let outputURL {
                persistCompletionState(status: .finished, outputPath: outputURL.path, errorMessage: nil)
            } else {
                persistCompletionState(status: .failed, outputPath: nil, errorMessage: errorMessage)
            }
            return
        }

        writer.finishWriting { [weak self] in
            guard let self else {
                return
            }

            let finalStatus: RecordingStatus
            let finalMessage: String?
            if writer.status == .completed || writer.status == .writing {
                finalStatus = status
                finalMessage = errorMessage
            } else {
                finalStatus = .failed
                finalMessage = writer.error?.localizedDescription ?? errorMessage ?? "Unable to finalize the screen recording."
            }

            let finalPath = finalStatus == .finished ? self.outputURL?.path : nil
            self.persistCompletionState(status: finalStatus, outputPath: finalPath, errorMessage: finalMessage)
            self.writer = nil
            self.videoInput = nil
            self.audioInput = nil
        }
    }

    private func finishWithFailure(message: String) {
        finishWritingIfNeeded(status: .failed, errorMessage: message)
        finishBroadcastWithError(NSError(domain: "ScreenRecorderBroadcastExtension", code: -4, userInfo: [NSLocalizedDescriptionKey: message]))
    }

    private func persistCompletionState(status: RecordingStatus, outputPath: String?, errorMessage: String?) {
        guard let userDefaults = sharedDefaults() else {
            return
        }

        userDefaults.set(status.rawValue, forKey: SharedKeys.status)
        if let outputPath {
            userDefaults.set(outputPath, forKey: SharedKeys.outputPath)
        } else {
            userDefaults.removeObject(forKey: SharedKeys.outputPath)
        }

        if let errorMessage {
            userDefaults.set(errorMessage, forKey: SharedKeys.errorMessage)
        } else {
            userDefaults.removeObject(forKey: SharedKeys.errorMessage)
        }
        userDefaults.synchronize()
    }

    private func setStatus(_ status: RecordingStatus) {
        sharedDefaults()?.set(status.rawValue, forKey: SharedKeys.status)
        sharedDefaults()?.synchronize()
    }

    private func currentStatus() -> RecordingStatus {
        guard let rawValue = sharedDefaults()?.string(forKey: SharedKeys.status),
              let status = RecordingStatus(rawValue: rawValue) else {
            return .idle
        }
        return status
    }

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier())
    }

    private func appGroupIdentifier() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.kaizenteam.broadcast"
        let appBundleIdentifier = bundleIdentifier.replacingOccurrences(of: ".broadcast", with: "")
        return "group.\(appBundleIdentifier).screenrecord"
    }
}
