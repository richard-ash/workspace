import ProjectDescription

let projectSettings = Settings.settings(
    debug: Configuration.debug(
        name: .debug,
        xcconfig: Path("config/MovieInfoProject.xcconfig")
    ).settings,
    release: Configuration.release(
        name: .release,
        xcconfig: Path("config/MovieInfoProject.xcconfig")
    ).settings,
    defaultSettings: .recommended
)

let targetSettings = Settings.settings(
    debug: Configuration.debug(
        name: .debug,
        xcconfig: Path("config/MovieInfoTarget.xcconfig")
    ).settings,
    release: Configuration.release(
        name: .release,
        xcconfig: Path("config/MovieInfoTarget.xcconfig")
    ).settings,
    defaultSettings: .recommended
)

let project = Project(
  name: "MovieInfo",
  organizationName: "<YOUR_ORG_NAME_HERE>",
  packages: [
    // 2
    Package.remote(
      // 3
      url: "https://github.com/kean/FetchImage.git",
      requirement: .upToNextMajor(
        from: Version(0, 4, 0)))
  ],
  settings: projectSettings,
  targets: [
    // 1
    Target(
      name: "MovieInfo",
      platform: .iOS,
      product: .app,
      bundleId: "com.richardash.tuistexample",
      infoPlist: "MovieInfo/Info.plist",
      sources: ["MovieInfo/Source/**"],
      resources: ["MovieInfo/Resources/**"],
      dependencies: [
        .project(target: "NetworkKit", path: .relativeToManifest("NetworkKit")),
        .package(product: "FetchImage")
      ],
      settings: targetSettings
    ),
    Target(
      name: "MovieInfoTests",
      platform: .iOS,
      product: .unitTests,
      bundleId: "com.richardash.tuistexample",
      infoPlist: "MovieInfoTests/Resources/Info.plist",
      sources: ["MovieInfoTests/Source/**"],
      dependencies: [
        .target(name: "MovieInfo")
      ]
    )
  ]
)

