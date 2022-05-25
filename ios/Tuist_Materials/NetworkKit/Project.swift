import ProjectDescription

let projectSettings = Settings.settings(
    configurations: [
        Configuration.debug(
            name: .debug,
            xcconfig: Path("config/NetworkKitProject.xcconfig")
        ),
        Configuration.release(
            name: .release,
            xcconfig: Path("config/NetworkKitProject.xcconfig")
        )
    ],
    defaultSettings: .recommended
)

let targetSettings = Settings.settings(
    configurations: [
        Configuration.debug(
            name: .debug,
            xcconfig: Path("config/NetworkKitTarget.xcconfig")
        ),
        Configuration.release(
            name: .release,
            xcconfig: Path("config/NetworkKitTarget.xcconfig")
        )
    ],
    defaultSettings: .recommended
)

let project = Project(
  name: "NetworkKit",
  organizationName: "Ray Wenderlich",
  settings: projectSettings,
  targets: [
    Target(
      name: "NetworkKit",
      platform: .iOS,
      product: .framework,
      bundleId: "com.richardash.tuistexample-networkkit",
      infoPlist: "NetworkKit/Info.plist",
      sources: ["NetworkKit/Source/**"],
      settings: targetSettings)
  ]
)
