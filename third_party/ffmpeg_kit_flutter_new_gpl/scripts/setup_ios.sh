#!/bin/bash

# Download and unzip iOS framework
# IOS_URL="https://github.com/hellohejinyu/ffmpeg_kit_flutter_full_gpl/releases/download/v5.1.LTS/ffmpeg-kit-full-gpl-5.1.LTS-ios-framework.zip"
IOS_URL="https://github.com/ganlong-2016/ffmpeg_kit_flutter_full_gpl/releases/download/v6.0.LTS_xc/ffmpeg-kit-full-gpl-6.0.LTS-ios-framework.zip"
mkdir -p Frameworks
curl -L $IOS_URL -o frameworks.zip
unzip -o frameworks.zip -d Frameworks
rm frameworks.zip

# Delete bitcode from all frameworks
xcrun bitcode_strip -r Frameworks/ffmpegkit.xcframework/ios-arm64_arm64e/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpegkit.xcframework/ios-arm64_arm64e/ffmpegkit.framework/ffmpegkit
xcrun bitcode_strip -r Frameworks/libavcodec.xcframework/ios-arm64_arm64e/libavcodec.framework/libavcodec -o Frameworks/libavcodec.xcframework/ios-arm64_arm64e/libavcodec.framework/libavcodec
xcrun bitcode_strip -r Frameworks/libavdevice.xcframework/ios-arm64_arm64e/libavdevice.framework/libavdevice -o Frameworks/libavdevice.xcframework/ios-arm64_arm64e/libavdevice.framework/libavdevice
xcrun bitcode_strip -r Frameworks/libavfilter.xcframework/ios-arm64_arm64e/libavfilter.framework/libavfilter -o Frameworks/libavfilter.xcframework/ios-arm64_arm64e/libavfilter.framework/libavfilter
xcrun bitcode_strip -r Frameworks/libavformat.xcframework/ios-arm64_arm64e/libavformat.framework/libavformat -o Frameworks/libavformat.xcframework/ios-arm64_arm64e/libavformat.framework/libavformat
xcrun bitcode_strip -r Frameworks/libavutil.xcframework/ios-arm64_arm64e/libavutil.framework/libavutil -o Frameworks/libavutil.xcframework/ios-arm64_arm64e/libavutil.framework/libavutil
xcrun bitcode_strip -r Frameworks/libswresample.xcframework/ios-arm64_arm64e/libswresample.framework/libswresample -o Frameworks/libswresample.xcframework/ios-arm64_arm64e/libswresample.framework/libswresample
xcrun bitcode_strip -r Frameworks/libswscale.xcframework/ios-arm64_arm64e/libswscale.framework/libswscale -o Frameworks/libswscale.xcframework/ios-arm64_arm64e/libswscale.framework/libswscale

xcrun bitcode_strip -r Frameworks/ffmpegkit.xcframework/ios-arm64_x86_64-simulator/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpegkit.xcframework/ios-arm64_x86_64-simulator/ffmpegkit.framework/ffmpegkit
xcrun bitcode_strip -r Frameworks/libavcodec.xcframework/ios-arm64_x86_64-simulator/libavcodec.framework/libavcodec -o Frameworks/libavcodec.xcframework/ios-arm64_x86_64-simulator/libavcodec.framework/libavcodec
xcrun bitcode_strip -r Frameworks/libavdevice.xcframework/ios-arm64_x86_64-simulator/libavdevice.framework/libavdevice -o Frameworks/libavdevice.xcframework/ios-arm64_x86_64-simulator/libavdevice.framework/libavdevice
xcrun bitcode_strip -r Frameworks/libavfilter.xcframework/ios-arm64_x86_64-simulator/libavfilter.framework/libavfilter -o Frameworks/libavfilter.xcframework/ios-arm64_x86_64-simulator/libavfilter.framework/libavfilter
xcrun bitcode_strip -r Frameworks/libavformat.xcframework/ios-arm64_x86_64-simulator/libavformat.framework/libavformat -o Frameworks/libavformat.xcframework/ios-arm64_x86_64-simulator/libavformat.framework/libavformat
xcrun bitcode_strip -r Frameworks/libavutil.xcframework/ios-arm64_x86_64-simulator/libavutil.framework/libavutil -o Frameworks/libavutil.xcframework/ios-arm64_x86_64-simulator/libavutil.framework/libavutil
xcrun bitcode_strip -r Frameworks/libswresample.xcframework/ios-arm64_x86_64-simulator/libswresample.framework/libswresample -o Frameworks/libswresample.xcframework/ios-arm64_x86_64-simulator/libswresample.framework/libswresample
xcrun bitcode_strip -r Frameworks/libswscale.xcframework/ios-arm64_x86_64-simulator/libswscale.framework/libswscale -o Frameworks/libswscale.xcframework/ios-arm64_x86_64-simulator/libswscale.framework/libswscale