// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "vim-mac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "vim-mac",
            targets: ["vim-mac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "vim-mac",
            path: "vim-mac",
            exclude: [
                "Planning Doc - Vim Mac v0.0.1.pdf"
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("ApplicationServices")
            ]
        )
    ]
)
