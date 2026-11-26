import Foundation

/// ローカライズ文字列の取得。文字列リソースは SPM のリソースバンドル
/// （Pinocator_Pinocator.bundle）に入るので、Bundle.main ではなく
/// そのバンドルを探して使う。.app 内では Contents/Resources、
/// `swift run` 等では実行ファイルの隣にある。
enum L10n {
    static let bundle: Bundle = {
        let bundleName = "Pinocator_Pinocator.bundle"
        var candidates: [URL] = []
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL)
        }
        candidates.append(Bundle.main.bundleURL)
        candidates.append(
            URL(fileURLWithPath: CommandLine.arguments[0])
                .deletingLastPathComponent())
        for base in candidates {
            if let bundle = Bundle(url: base.appendingPathComponent(bundleName)) {
                return bundle
            }
        }
        return .main
    }()

    static func t(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }
}
