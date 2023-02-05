import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
  name: "Lunar",
  product: .app,
  packages: [
    Package.Firebase,
    Package.KeychainAccess,
    Package.Realm,
    Package.Scope,
    Package.SnapKit
  ],
  dependencies: [
    .SPM.FirebaseAnalytics,
    .SPM.FirebaseCrashlytics,
    .SPM.KeychainAccess,
    .SPM.Realm,
    .SPM.Scope,
    .SPM.SnapKit
  ]
)
