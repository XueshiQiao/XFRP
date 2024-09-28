import Foundation

enum L10n {
    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }

    enum Common {
        static let ok = tr("common.ok")
        static let cancel = tr("common.cancel")
    }

    enum Actions {
        static let start = tr("actions.start")
        static let stop = tr("actions.stop")
        static let verify = tr("actions.verify")
        static let reload = tr("actions.reload")
        static let forceStop = tr("actions.forceStop")
        static let clearLogs = tr("actions.clearLogs")
    }

    enum Settings {
        static let title = tr("settings.title")
        static let configFile = tr("settings.configFile")
        static let executableFile = tr("settings.executableFile")
        static let choose = tr("settings.choose")
        static let startOnLogin = tr("settings.startOnLogin")
        static let autoStartOnLaunch = tr("settings.autoStartOnLaunch")
        static let language = tr("settings.language")
        static let chooseLanguage = tr("settings.chooseLanguage")
        static let startupSettings = tr("settings.startupSettings")
    }

    enum MainView {
        static let actions = tr("mainView.actions")
        static let settings = tr("mainView.settings")
        static let dockerImage = tr("mainView.dockerImage")
        static let dockerImageTag = tr("mainView.dockerImageTag")
        static let selectOption = tr("mainView.selectOption")
    }
}
