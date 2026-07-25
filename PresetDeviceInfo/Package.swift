// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "PresetDeviceInfo",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "PresetDeviceInfo", targets: ["PresetDeviceInfo"]),
    ],
    targets: [
        .target(
            name: "PresetDeviceInfo",
            linkerSettings: [
                .linkedFramework("AdSupport"),
                .linkedFramework("AppTrackingTransparency"),
            ]
        ),
    ]
)
