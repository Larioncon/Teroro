import Combine
import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let storageKey = "app_language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            UserDefaults(suiteName: "group.com.OleksaChmil.Timora")?.set(currentLanguage.rawValue, forKey: storageKey)
            WidgetCenter.shared.reloadAllTimelines()
            UserDefaults.standard.synchronize()
        }
    }

    var locale: Locale {
        Locale(identifier: currentLanguage.rawValue)
    }

    private init() {
        if let savedCode = UserDefaults.standard.string(forKey: storageKey),
           let savedLang = AppLanguage(rawValue: savedCode) {
            self.currentLanguage = savedLang
        } else {
            let detected = AppLanguage.detectDefaultLanguage()
            self.currentLanguage = detected
            UserDefaults.standard.set(detected.rawValue, forKey: storageKey)
            UserDefaults.standard.set([detected.rawValue], forKey: "AppleLanguages")
        }
        if let sharedDefaults = UserDefaults(suiteName: "group.com.OleksaChmil.Timora"),
           sharedDefaults.string(forKey: storageKey) != currentLanguage.rawValue {
            sharedDefaults.set(currentLanguage.rawValue, forKey: storageKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
    }

    nonisolated static var storedLanguageCode: String {
        UserDefaults.standard.string(forKey: "app_language") ?? AppLanguage.detectDefaultLanguage().rawValue
    }

    nonisolated static func resolveString(
        forKey key: String,
        languageCode: String,
        defaultValue: String? = nil
    ) -> String {
        if let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            let value = bundle.localizedString(forKey: key, value: defaultValue, table: nil)
            if value != key { return value }
        }

        if languageCode != "en",
           let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let englishBundle = Bundle(path: englishPath) {
            let value = englishBundle.localizedString(forKey: key, value: defaultValue, table: nil)
            if value != key { return value }
        }

        return defaultValue ?? key
    }

    /*
    // MARK: - Legacy In-Memory Translations (Kept for fallback/revert)
    private let translations: [String: [AppLanguage: String]] = [
        // MARK: - Settings & Navigation
        "settings.title": [
            .english: "Settings",
            .ukrainian: "Налаштування",
            .german: "Einstellungen",
            .russian: "Настройки"
        ],
        "language.title": [
            .english: "Language",
            .ukrainian: "Мова",
            .german: "Sprache",
            .russian: "Язык"
        ],
        "settings.notifications": [
            .english: "Notifications",
            .ukrainian: "Сповіщення",
            .german: "Mitteilungen",
            .russian: "Уведомления"
        ],
        "settings.appearance": [
            .english: "Appearance",
            .ukrainian: "Вид",
            .german: "Erscheinungsbild",
            .russian: "Внешний вид"
        ],
        "settings.privacy.and.security": [
            .english: "Privacy and Security",
            .ukrainian: "Приватність та безпека",
            .german: "Datenschutz & Sicherheit",
            .russian: "Конфиденциальность и безопасность"
        ],
        "settings.feedback": [
            .english: "Send Feedback",
            .ukrainian: "Написати фідбек",
            .german: "Feedback senden",
            .russian: "Написать отзыв"
        ],
        "settings.share": [
            .english: "Share App",
            .ukrainian: "Поділитися застосунком",
            .german: "App teilen",
            .russian: "Поделиться приложением"
        ],
        "settings.terms.of.use": [
            .english: "Terms of Use",
            .ukrainian: "Умови використання",
            .german: "Nutzungsbedingungen",
            .russian: "Условия использования"
        ],
        "settings.privacy.policy": [
            .english: "Privacy Policy",
            .ukrainian: "Політика конфіденційності",
            .german: "Datenschutzrichtlinie",
            .russian: "Политика конфиденциальности"
        ],
        "settings.sign.out": [
            .english: "Log Out",
            .ukrainian: "Вийти",
            .german: "Abmelden",
            .russian: "Выйти"
        ],
        "profile.title": [
            .english: "Profile",
            .ukrainian: "Профіль",
            .german: "Profil",
            .russian: "Профиль"
        ],
        "common.edit": [
            .english: "Edit",
            .ukrainian: "Редагувати",
            .german: "Bearbeiten",
            .russian: "Редактировать"
        ],
        "settings.take.photo": [
            .english: "Take Photo",
            .ukrainian: "Сфотографувати",
            .german: "Foto aufnehmen",
            .russian: "Сфотографировать"
        ],
        "settings.choose.gallery": [
            .english: "Choose from Gallery",
            .ukrainian: "Вибрати в галереї",
            .german: "Aus Mediathek wählen",
            .russian: "Выбрать в галерее"
        ],
        "profile.name.label": [
            .english: "Name",
            .ukrainian: "Ім'я",
            .german: "Name",
            .russian: "Имя"
        ],

        // MARK: - LanguagesView
        "language.title": [
            .english: "Language",
            .ukrainian: "Мова",
            .german: "Sprache",
            .russian: "Язык"
        ],
        "language.section.interface": [
            .english: "INTERFACE LANGUAGE",
            .ukrainian: "МОВА ІНТЕРФЕЙСУ",
            .german: "OBERFLÄCHENSPRACHE",
            .russian: "ЯЗЫК ИНТЕРФЕЙСА"
        ],
        "language.header.description": [
            .english: "Choose your preferred interface language for the application.",
            .ukrainian: "Оберіть бажану мову інтерфейсу для застосунку.",
            .german: "Wählen Sie Ihre bevorzugte Oberflächensprache für die Anwendung.",
            .russian: "Выберите предпочитаемый язык интерфейса для приложения."
        ],

        // MARK: - Tab Bar
        "terms.title": [
            .english: "Terms",
            .ukrainian: "Терміни",
            .german: "Termine",
            .russian: "Сроки"
        ],
        "tab.map": [
            .english: "Map",
            .ukrainian: "Мапа",
            .german: "Karte",
            .russian: "Карта"
        ],
        "tab.timer": [
            .english: "Timer",
            .ukrainian: "Таймер",
            .german: "Timer",
            .russian: "Таймер"
        ],
        "profile.title": [
            .english: "Profile",
            .ukrainian: "Профіль",
            .german: "Profil",
            .russian: "Профиль"
        ],

        // MARK: - Common
        "common.error": [
            .english: "Error",
            .ukrainian: "Помилка",
            .german: "Fehler",
            .russian: "Ошибка"
        ],
        "common.ok": [
            .english: "OK",
            .ukrainian: "OK",
            .german: "OK",
            .russian: "OK"
        ],
        "common.cancel": [
            .english: "Cancel",
            .ukrainian: "Скасувати",
            .german: "Abbrechen",
            .russian: "Отмена"
        ],
        "common.save": [
            .english: "Save",
            .ukrainian: "Зберегти",
            .german: "Speichern",
            .russian: "Сохранить"
        ],
        "common.saving": [
            .english: "Saving...",
            .ukrainian: "Збереження...",
            .german: "Speichern...",
            .russian: "Сохранение..."
        ],
        "common.delete": [
            .english: "Delete",
            .ukrainian: "Видалити",
            .german: "Löschen",
            .russian: "Удалить"
        ],
        "common.edit": [
            .english: "Edit",
            .ukrainian: "Редагувати",
            .german: "Bearbeiten",
            .russian: "Редактировать"
        ],
        "common.add": [
            .english: "Add",
            .ukrainian: "Додати",
            .german: "Hinzufügen",
            .russian: "Добавить"
        ],
        "common.change": [
            .english: "Change",
            .ukrainian: "Змінити",
            .german: "Ändern",
            .russian: "Изменить"
        ],
        "common.confirm": [
            .english: "Confirm",
            .ukrainian: "Підтвердити",
            .german: "Bestätigen",
            .russian: "Подтвердить"
        ],
        "common.hide": [
            .english: "Hide",
            .ukrainian: "Сховати",
            .german: "Ausblenden",
            .russian: "Скрыть"
        ],
        "common.success": [
            .english: "Success",
            .ukrainian: "Успішно",
            .german: "Erfolg",
            .russian: "Успешно"
        ],
        "common.back": [
            .english: "Back",
            .ukrainian: "Назад",
            .german: "Zurück",
            .russian: "Назад"
        ],

        // MARK: - Home & Terms
        "terms.title": [
            .english: "Terms",
            .ukrainian: "Терміни",
            .german: "Termine",
            .russian: "Сроки"
        ],
        "home.past.terms": [
            .english: "Past Terms",
            .ukrainian: "Минулі терміни",
            .german: "Vergangene Termine",
            .russian: "Прошедшие сроки"
        ],
        "home.no.upcoming.terms": [
            .english: "No current terms",
            .ukrainian: "Немає актуальних термінів",
            .german: "Keine aktuellen Termine",
            .russian: "Нет актуальных сроков"
        ],
        "home.no.past.terms": [
            .english: "No past terms",
            .ukrainian: "Немає минулих термінів",
            .german: "Keine vergangenen Termine",
            .russian: "Нет прошедших сроков"
        ],
        "home.add.term": [
            .english: "Add Term",
            .ukrainian: "Додати термін",
            .german: "Termin hinzufügen",
            .russian: "Добавить срок"
        ],
        "home.current.terms.accessibility": [
            .english: "Current terms",
            .ukrainian: "Актуальні терміни",
            .german: "Aktuelle Termine",
            .russian: "Актуальные сроки"
        ],

        // MARK: - Term Form
        "term.form.new.title": [
            .english: "New Term",
            .ukrainian: "Новий термін",
            .german: "Neuer Termin",
            .russian: "Новый срок"
        ],
        "common.edit": [
            .english: "Edit",
            .ukrainian: "Редагувати",
            .german: "Bearbeiten",
            .russian: "Редактировать"
        ],
        "term.form.title.placeholder": [
            .english: "Title",
            .ukrainian: "Заголовок",
            .german: "Titel",
            .russian: "Заголовок"
        ],
        "term.form.details.placeholder": [
            .english: "Details",
            .ukrainian: "Деталі",
            .german: "Details",
            .russian: "Детали"
        ],
        "term.form.date.and.time": [
            .english: "Date and Time",
            .ukrainian: "Дата та час",
            .german: "Datum und Uhrzeit",
            .russian: "Дата и время"
        ],
        "term.form.date": [
            .english: "Date",
            .ukrainian: "Дата",
            .german: "Datum",
            .russian: "Дата"
        ],
        "term.form.time": [
            .english: "Time",
            .ukrainian: "Час",
            .german: "Uhrzeit",
            .russian: "Время"
        ],
        "term.form.reminder": [
            .english: "Reminder",
            .ukrainian: "Нагадування",
            .german: "Erinnerung",
            .russian: "Напоминание"
        ],
        "term.form.notify.about.term": [
            .english: "Notify about term",
            .ukrainian: "Повідомити про термін",
            .german: "Über Termin benachrichtigen",
            .russian: "Уведомить о сроке"
        ],
        "term.form.when": [
            .english: "When?",
            .ukrainian: "Коли?",
            .german: "Wann?",
            .russian: "Когда?"
        ],
        "term.form.location": [
            .english: "Location",
            .ukrainian: "Місце",
            .german: "Ort",
            .russian: "Место"
        ],
        "term.form.offline": [
            .english: "(offline)",
            .ukrainian: "(офлайн)",
            .german: "(offline)",
            .russian: "(офлайн)"
        ],
        "term.form.add.meeting.address": [
            .english: "Add an address for the meeting",
            .ukrainian: "Додайте адресу для зустрічі",
            .german: "Adresse für das Treffen hinzufügen",
            .russian: "Добавьте адрес для встречи"
        ],
        "term.form.location.unavailable.offline": [
            .english: "Location selection is unavailable without internet",
            .ukrainian: "Вибір локації недоступний без інтернету",
            .german: "Ortsauswahl ohne Internet nicht verfügbar",
            .russian: "Выбор локации недоступен без интернета"
        ],
        "term.form.location.selected": [
            .english: "Location selected",
            .ukrainian: "Локація обрана",
            .german: "Ort ausgewählt",
            .russian: "Локация выбрана"
        ],

        // MARK: - Map & Location Picker
        "map.search.title": [
            .english: "Search Location",
            .ukrainian: "Пошук місця",
            .german: "Ort suchen",
            .russian: "Поиск места"
        ],
        "map.search.placeholder": [
            .english: "City or address",
            .ukrainian: "Місто або адреса",
            .german: "Stadt oder Adresse",
            .russian: "Город или адрес"
        ],
        "map.nothing.found": [
            .english: "Nothing found",
            .ukrainian: "Нічого не знайдено",
            .german: "Nichts gefunden",
            .russian: "Ничего не найдено"
        ],
        "map.select.this.location": [
            .english: "Select this location",
            .ukrainian: "Обрати цю локацію",
            .german: "Diesen Ort auswählen",
            .russian: "Выбрать эту локацию"
        ],
        "map.determining.address": [
            .english: "Determining address...",
            .ukrainian: "Визначаємо адресу...",
            .german: "Adresse wird ermittelt...",
            .russian: "Определяем адрес..."
        ],
        "map.location.on.map": [
            .english: "Location on map",
            .ukrainian: "Локація на карті",
            .german: "Ort auf der Karte",
            .russian: "Локация на карте"
        ],
        "map.pin.on.map": [
            .english: "Pin on map",
            .ukrainian: "Позначка на карті",
            .german: "Kartenmarkierung",
            .russian: "Отметка на карте"
        ],
        "map.hint.location": [
            .english: "Where am I? Find yourself near your tasks with one tap.",
            .ukrainian: "Де я зараз? В один дотик знайдіть себе поруч зі своїми справами.",
            .german: "Wo bin ich? Finden Sie sich mit einem Fingertipp bei Ihren Aufgaben.",
            .russian: "Где я сейчас? В одно касание найдите себя рядом со своими делами."
        ],
        "map.hint.standard": [
            .english: "Standard view: clean map without visual clutter — just streets and addresses.",
            .ukrainian: "Стандартний вигляд: проста схема без візуального шуму — лише вулиці й адреси.",
            .german: "Standardansicht: einfache Karte ohne optische Ablenkung — nur Straßen und Adressen.",
            .russian: "Стандартный вид: простая схема без визуального шума — только улицы и адреса."
        ],
        "map.hint.hybrid": [
            .english: "Satellite layer: real view of buildings and landmarks.",
            .ukrainian: "Супутниковий шар: реальний вигляд будівель та орієнтирів.",
            .german: "Satellitenebene: reale Ansicht von Gebäuden und Orientierungspunkten.",
            .russian: "Спутниковый слой: реальный вид зданий и ориентиров."
        ],
        "map.loading.terms.title": [
            .english: "Loading terms",
            .ukrainian: "Завантаження термінів",
            .german: "Termine laden",
            .russian: "Загрузка сроков"
        ],
        "map.loading.terms.subtitle": [
            .english: "The map will update after syncing.",
            .ukrainian: "Мапа оновиться після синхронізації.",
            .german: "Die Karte wird nach der Synchronisierung aktualisiert.",
            .russian: "Карта обновится после синхронизации."
        ],
        "map.empty.terms.title": [
            .english: "No upcoming terms",
            .ukrainian: "Немає майбутніх термінів",
            .german: "Keine bevorstehenden Termine",
            .russian: "Нет предстоящих сроков"
        ],
        "map.empty.terms.subtitle": [
            .english: "Schedule a new term to see it on the map.",
            .ukrainian: "Заплануйте новий термін, щоб побачити його на мапі.",
            .german: "Planen Sie einen neuen Termin, um ihn auf der Karte zu sehen.",
            .russian: "Запланируйте новый срок, чтобы увидеть его на карте."
        ],
        "map.empty.locations.title": [
            .english: "No locations",
            .ukrainian: "Немає локацій",
            .german: "Keine Orte",
            .russian: "Нет локаций"
        ],
        "map.empty.locations.subtitle": [
            .english: "Upcoming terms without a place are not shown on the map.",
            .ukrainian: "Майбутні терміни без місця не відображаються на мапі.",
            .german: "Bevorstehende Termine ohne Ort werden nicht auf der Karte angezeigt.",
            .russian: "Предстоящие сроки без места не отображаются на карте."
        ],
        "map.terms.map.card.title": [
            .english: "Terms Map",
            .ukrainian: "Мапа термінів",
            .german: "Terminekarte",
            .russian: "Карта сроков"
        ],
        "map.terms.map.card.subtitle": [
            .english: "Shows only upcoming terms with a location.",
            .ukrainian: "Показує лише майбутні терміни з локацією.",
            .german: "Zeigt nur bevorstehende Termine mit einem Ort.",
            .russian: "Показывает только предстоящие сроки с локацией."
        ],

        // MARK: - Pomodoro / Timer
        "timer.hint.change.duration": [
            .english: "Tap to change period duration.",
            .ukrainian: "Натисніть, щоб змінити тривалість періоду.",
            .german: "Tippen Sie hier, um die Dauer des Zeitraums zu ändern.",
            .russian: "Нажмите чтоб изменить длительность периода."
        ],
        "timer.start": [
            .english: "START",
            .ukrainian: "СТАРТ",
            .german: "START",
            .russian: "СТАРТ"
        ],
        "timer.pause": [
            .english: "PAUSE",
            .ukrainian: "ПАУЗА",
            .german: "PAUSE",
            .russian: "ПАУЗА"
        ],
        "timer.stop": [
            .english: "STOP",
            .ukrainian: "СТОП",
            .german: "STOP",
            .russian: "СТОП"
        ],
        "timer.finish": [
            .english: "FINISH",
            .ukrainian: "ЗАВЕРШИТИ",
            .german: "BEENDEN",
            .russian: "ЗАВЕРШИТЬ"
        ],
        "timer.focus.time": [
            .english: "FOCUS TIME",
            .ukrainian: "ЧАС ФОКУСУ",
            .german: "FOKUSZEIT",
            .russian: "ВРЕМЯ ФОКУСА"
        ],
        "timer.relax": [
            .english: "RELAX",
            .ukrainian: "ВІДПОЧИНОК",
            .german: "PAUSE",
            .russian: "ОТДЫХ"
        ],
        "timer.duration": [
            .english: "Duration",
            .ukrainian: "Тривалість",
            .german: "Dauer",
            .russian: "Длительность"
        ],
        "common.done": [
            .english: "Done",
            .ukrainian: "Готово",
            .german: "Fertig",
            .russian: "Готово"
        ],
        "timer.notifications.disabled": [
            .english: "Notifications disabled",
            .ukrainian: "Сповіщення вимкнено",
            .german: "Mitteilungen deaktiviert",
            .russian: "Уведомления отключены"
        ],

        // MARK: - Paywall
        "paywall.unlock.pro": [
            .english: "Unlock Pro",
            .ukrainian: "Розблокуйте Pro",
            .german: "Pro freischalten",
            .russian: "Разблокируйте Pro"
        ],
        "paywall.subtitle": [
            .english: "Keep terms, reminders and focus tools fully available.",
            .ukrainian: "Зберігайте терміни, нагадування та інструменти фокусу повністю доступними.",
            .german: "Halten Sie Termine, Erinnerungen und Fokus-Tools voll verfügbar.",
            .russian: "Сохраняйте сроки, напоминания и инструменты фокуса полностью доступными."
        ],
        "paywall.processing": [
            .english: "Processing...",
            .ukrainian: "Обробка...",
            .german: "Wird verarbeitet...",
            .russian: "Обработка..."
        ],
        "paywall.continue": [
            .english: "Continue",
            .ukrainian: "Продовжити",
            .german: "Fortfahren",
            .russian: "Продолжить"
        ],
        "paywall.restore.button": [
            .english: "Restore",
            .ukrainian: "Відновити покупки",
            .german: "Wiederherstellen",
            .russian: "Восстановить покупки"
        ],
        "paywall.legal.terms": [
            .english: "Terms and conditions",
            .ukrainian: "Умови використання",
            .german: "Nutzungsbedingungen",
            .russian: "Условия использования"
        ],
        "paywall.legal.privacy.policy": [
            .english: "Privacy policy",
            .ukrainian: "Політика конфіденційності",
            .german: "Datenschutzrichtlinie",
            .russian: "Политика конфиденциальности"
        ],
        "paywall.get.free.trial": [
            .english: "Get 3 Days Free Trial",
            .ukrainian: "Отримайте 3 дні безкоштовно",
            .german: "3 Tage kostenlos testen",
            .russian: "Получите 3 дня бесплатно"
        ],
        "paywall.free.trial.enabled": [
            .english: "Free Trial Enabled",
            .ukrainian: "Пробний період увімкнено",
            .german: "Kostenlose Testversion aktiviert",
            .russian: "Пробный период включен"
        ],
        "paywall.free.trial.disabled": [
            .english: "Free Trial Disabled",
            .ukrainian: "Пробний період вимкнено",
            .german: "Kostenlose Testversion deaktiviert",
            .russian: "Пробный период отключен"
        ],
        "paywall.trial.includes.desc": [
            .english: "Plans include 3 days free trial.",
            .ukrainian: "Тарифи містять 3 дні безкоштовного пробного періоду.",
            .german: "Pläne enthalten eine 3-tägige kostenlose Testphase.",
            .russian: "Тарифы включают 3 дня бесплатного пробного периода."
        ],
        "paywall.trial.starts.without.desc": [
            .english: "Plans start without trial.",
            .ukrainian: "Тарифи починаються без пробного періоду.",
            .german: "Pläne beginnen ohne Testphase.",
            .russian: "Тарифы начинаются без пробного периода."
        ],
        "paywall.close": [
            .english: "Close",
            .ukrainian: "Закрити",
            .german: "Schließen",
            .russian: "Закрыть"
        ],
        "plan.period.week": [
            .english: "Week",
            .ukrainian: "Тиждень",
            .german: "Woche",
            .russian: "Неделя"
        ],
        "plan.period.month": [
            .english: "Month",
            .ukrainian: "Місяць",
            .german: "Monat",
            .russian: "Месяц"
        ],
        "plan.period.year": [
            .english: "Year",
            .ukrainian: "Рік",
            .german: "Jahr",
            .russian: "Год"
        ],
        "plan.get.weekly": [
            .english: "Get weekly plan",
            .ukrainian: "Отримати тижневий план",
            .german: "Wochenplan wählen",
            .russian: "Получить недельный план"
        ],
        "plan.get.monthly": [
            .english: "Get monthly plan",
            .ukrainian: "Отримати місячний план",
            .german: "Monatsplan wählen",
            .russian: "Получить месячный план"
        ],
        "plan.get.annual": [
            .english: "Get annual plan",
            .ukrainian: "Отримати річний план",
            .german: "Jahresplan wählen",
            .russian: "Получить годовой план"
        ],

        // MARK: - Privacy & Security
        "security.passcode": [
            .english: "Passcode",
            .ukrainian: "Код-пароль",
            .german: "Code",
            .russian: "Код-пароль"
        ],
        "security.enabled": [
            .english: "Enabled",
            .ukrainian: "Увімкнено",
            .german: "Aktiviert",
            .russian: "Включено"
        ],
        "security.disabled": [
            .english: "Disabled",
            .ukrainian: "Вимкнено",
            .german: "Deaktiviert",
            .russian: "Выключено"
        ],
        "security.change.password": [
            .english: "Change Password",
            .ukrainian: "Змінити пароль",
            .german: "Passwort ändern",
            .russian: "Изменить пароль"
        ],
        "security.change.email": [
            .english: "Change Email",
            .ukrainian: "Змінити email",
            .german: "E-Mail ändern",
            .russian: "Изменить email"
        ],
        "security.add.email": [
            .english: "Add Email",
            .ukrainian: "Додайте Email",
            .german: "E-Mail hinzufügen",
            .russian: "Добавьте Email"
        ],
        "security.signin.methods": [
            .english: "Sign-in Methods",
            .ukrainian: "Способи входу",
            .german: "Anmeldemethoden",
            .russian: "Способы входа"
        ],
        "security.connected": [
            .english: "Connected",
            .ukrainian: "Підключено",
            .german: "Verbunden",
            .russian: "Подключено"
        ],
        "security.connect": [
            .english: "Connect",
            .ukrainian: "Підключити",
            .german: "Verbinden",
            .russian: "Подключить"
        ],
        "security.delete.account": [
            .english: "Delete Account",
            .ukrainian: "Видалити акаунт",
            .german: "Account löschen",
            .russian: "Удалить аккаунт"
        ],
        "security.passcode.lock.title": [
            .english: "Passcode Lock",
            .ukrainian: "Блокування код-паролем",
            .german: "Codesperre",
            .russian: "Блокировка код-паролем"
        ],
        "security.turn.off.passcode": [
            .english: "Turn Passcode Off",
            .ukrainian: "Вимкнути код-пароль",
            .german: "Code ausschalten",
            .russian: "Отключить код-пароль"
        ],
        "security.turn.on.passcode": [
            .english: "Turn Passcode On",
            .ukrainian: "Увімкнути код-пароль",
            .german: "Code einschalten",
            .russian: "Включить код-пароль"
        ],
        "security.change.passcode": [
            .english: "Change Passcode",
            .ukrainian: "Змінити код-пароль",
            .german: "Code ändern",
            .russian: "Изменить код-пароль"
        ],
        "security.autolock.description": [
            .english: "When passcode is on, Timexo will require it upon launch or returning to the app according to Auto-Lock.",
            .ukrainian: "Коли код-пароль увімкнено, Timexo буде запитувати його при запуску або після повернення у застосунок згідно з Auto-Lock.",
            .german: "Wenn der Code aktiviert ist, fordert Timexo ihn beim Start oder bei der Rückkehr in die App gemäß Auto-Lock an.",
            .russian: "Когда код-пароль включен, Timexo будет запрашивать его при запуске или после возврата в приложение согласно Auto-Lock."
        ],
        "security.unlock.face.id": [
            .english: "Unlock with Face ID",
            .ukrainian: "Розблокування з Face ID",
            .german: "Mit Face ID entsperren",
            .russian: "Разблокировка с Face ID"
        ],
        "security.enter.passcode": [
            .english: "Enter Timexo passcode",
            .ukrainian: "Введіть код-пароль Timexo",
            .german: "Timexo-Code eingeben",
            .russian: "Введите код-пароль Timexo"
        ],
        "security.confirm.passcode": [
            .english: "Confirm Timexo passcode",
            .ukrainian: "Підтвердіть код-пароль Timexo",
            .german: "Timexo-Code bestätigen",
            .russian: "Подтвердите код-пароль Timexo"
        ],
        "security.passcodes.do.not.match": [
            .english: "Passcodes do not match",
            .ukrainian: "Коди-паролі не співпадають",
            .german: "Codes stimmen nicht überein",
            .russian: "Коды-пароли не совпадают"
        ],
        "security.app.lock.prompt": [
            .english: "Enter your Timexo Passcode",
            .ukrainian: "Введіть код-пароль Timexo",
            .german: "Geben Sie Ihren Timexo-Code ein",
            .russian: "Введите код-пароль Timexo"
        ],
        "security.autolock.always": [
            .english: "Immediately",
            .ukrainian: "Завжди",
            .german: "Sofort",
            .russian: "Сразу"
        ],
        "security.autolock.1min": [
            .english: "If away for 1 min",
            .ukrainian: "Якщо відсутній 1 хв",
            .german: "Nach 1 Min. Abwesenheit",
            .russian: "Если отсутствует 1 мин"
        ],
        "security.autolock.5min": [
            .english: "If away for 5 min",
            .ukrainian: "Якщо відсутній 5 хв",
            .german: "Nach 5 Min. Abwesenheit",
            .russian: "Если отсутствует 5 мин"
        ],
        "security.autolock.1hour": [
            .english: "If away for 1 hour",
            .ukrainian: "Якщо відсутній 1 год",
            .german: "Nach 1 Std. Abwesenheit",
            .russian: "Если отсутствует 1 час"
        ],
        "security.autolock.5hours": [
            .english: "If away for 5 hours",
            .ukrainian: "Якщо відсутній 5 год",
            .german: "Nach 5 Std. Abwesenheit",
            .russian: "Если отсутствует 5 часов"
        ],
        "security.change.pwd.title": [
            .english: "Change Password",
            .ukrainian: "Зміна паролю",
            .german: "Passwort ändern",
            .russian: "Смена пароля"
        ],
        "security.current.pwd": [
            .english: "Current Password",
            .ukrainian: "Поточний пароль",
            .german: "Aktuelles Passwort",
            .russian: "Текущий пароль"
        ],
        "security.new.pwd": [
            .english: "New Password",
            .ukrainian: "Новий пароль",
            .german: "Neues Passwort",
            .russian: "Новый пароль"
        ],
        "security.confirm.new.pwd": [
            .english: "Confirm New Password",
            .ukrainian: "Підтвердіть новий пароль",
            .german: "Neues Passwort bestätigen",
            .russian: "Подтвердите новый пароль"
        ],
        "security.pwd.rules": [
            .english: "Password must contain at least 8 characters, an uppercase letter, a lowercase letter, and a number.",
            .ukrainian: "Пароль повинен містити щонайменше 8 символів, велику та малу літери, а також цифру.",
            .german: "Das Passwort muss mindestens 8 Zeichen, einen Großbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten.",
            .russian: "Пароль должен содержать не менее 8 символов, заглавную и строчную буквы, а также цифру."
        ],
        "security.change.email.title": [
            .english: "Change Email",
            .ukrainian: "Зміна Email",
            .german: "E-Mail ändern",
            .russian: "Смена Email"
        ],
        "security.new.email.field": [
            .english: "New Email",
            .ukrainian: "Новий Email",
            .german: "Neue E-Mail",
            .russian: "Новый Email"
        ],
        "security.change.email.prompt.footer": [
            .english: "Current email: %@. After confirming password, a verification email will be sent to the new email.",
            .ukrainian: "Поточний email: %@. Після підтвердження паролю, надійде лист на новий email для верифікації.",
            .german: "Aktuelle E-Mail: %@. Nach der Bestätigung des Passworts wird eine Bestätigungs-E-Mail an die neue Adresse gesendet.",
            .russian: "Текущий email: %@. После подтверждения пароля на новый email будет отправлено письмо для подтверждения."
        ],
        "security.change.email.code.sent.footer": [
            .english: "Current email: %@. Enter the code from Firebase email sent to the new email. If it contains a link, use the oobCode parameter value.",
            .ukrainian: "Поточний email: %@. Введіть код з листа Firebase, який прийшов на новий email. Якщо лист містить посилання, використайте значення параметра oobCode.",
            .german: "Aktuelle E-Mail: %@. Geben Sie den Code aus der Firebase-E-Mail ein, die an die neue E-Mail gesendet wurde. Wenn die E-Mail einen Link enthält, verwenden Sie den Wert des Parameters oobCode.",
            .russian: "Текущий email: %@. Введите код из письма Firebase, которое пришло на новый email. Если письмо содержит ссылку, используйте значение параметра oobCode."
        ],
        "security.send": [
            .english: "Send",
            .ukrainian: "Надіслати",
            .german: "Senden",
            .russian: "Отправить"
        ],
        "security.confirmation.section": [
            .english: "Confirmation",
            .ukrainian: "Підтвердження",
            .german: "Bestätigung",
            .russian: "Подтверждение"
        ],
        "security.verification.code.field": [
            .english: "Verification code",
            .ukrainian: "Код підтвердження",
            .german: "Bestätigungscode",
            .russian: "Код подтверждения"
        ],
        "security.add.email.title": [
            .english: "Add Email",
            .ukrainian: "Додати email",
            .german: "E-Mail hinzufügen",
            .russian: "Добавить email"
        ],
        "security.password.placeholder": [
            .english: "Password",
            .ukrainian: "Пароль",
            .german: "Passwort",
            .russian: "Пароль"
        ],
        "security.confirm.pwd.placeholder": [
            .english: "Confirm password",
            .ukrainian: "Підтвердіть пароль",
            .german: "Passwort bestätigen",
            .russian: "Подтвердите пароль"
        ],
        "security.delete.account.title": [
            .english: "Delete Account",
            .ukrainian: "Видалення акаунту",
            .german: "Account löschen",
            .russian: "Удаление аккаунта"
        ],
        "security.delete.warning.title": [
            .english: "Warning! Action is irreversible",
            .ukrainian: "Увага! Дія незворотна",
            .german: "Achtung! Aktion ist unwiderruflich",
            .russian: "Внимание! Действие необратимо"
        ],
        "security.delete.warning.desc": [
            .english: "Deleting your account will permanently destroy all your data, including saved terms, profile, and settings.",
            .ukrainian: "Видалення акаунту призведе до повного та безповоротного знищення всіх ваших даних, включаючи збережені терміни, профіль та налаштування.",
            .german: "Das Löschen Ihres Accounts führt zur vollständigen und unwiderruflichen Löschung aller Ihrer Daten, einschließlich gespeicherter Termine, Profil und Einstellungen.",
            .russian: "Удаление аккаунта приведет к полному и безвозвратному уничтожению всех ваших данных, включая сохраненные сроки, профиль и настройки."
        ],
        "security.confirm.pwd.section": [
            .english: "Confirmation via Email / Password",
            .ukrainian: "Підтвердження через Email / Пароль",
            .german: "Bestätigung über E-Mail / Passwort",
            .russian: "Подтверждение через Email / Пароль"
        ],
        "security.enter.your.pwd": [
            .english: "Enter your password",
            .ukrainian: "Введіть ваш пароль",
            .german: "Geben Sie Ihr Passwort ein",
            .russian: "Введите ваш пароль"
        ],
        "security.confirm.and.delete.account": [
            .english: "Confirm and Delete Account",
            .ukrainian: "Підтвердити та видалити акаунт",
            .german: "Bestätigen und Account löschen",
            .russian: "Подтвердить и удалить аккаунт"
        ],
        "security.confirm.google.section": [
            .english: "Confirmation via Google",
            .ukrainian: "Підтвердження через Google",
            .german: "Bestätigung über Google",
            .russian: "Подтверждение через Google"
        ],
        "security.confirm.google.delete": [
            .english: "Confirm with Google and Delete",
            .ukrainian: "Підтвердити через Google та видалити",
            .german: "Mit Google bestätigen und löschen",
            .russian: "Подтвердить через Google и удалить"
        ],
        "security.confirm.apple.section": [
            .english: "Confirmation via Apple",
            .ukrainian: "Підтвердження через Apple",
            .german: "Bestätigung über Apple",
            .russian: "Подтверждение через Apple"
        ],
        "security.confirm.apple.delete": [
            .english: "Confirm with Apple and Delete",
            .ukrainian: "Підтвердити через Apple та видалити",
            .german: "Mit Apple bestätigen und löschen",
            .russian: "Подтвердить через Apple и удалить"
        ],
        "security.disable.passcode.toast.title": [
            .english: "Disable Passcode",
            .ukrainian: "Вимкніть код-пароль",
            .german: "Code deaktivieren",
            .russian: "Отключите код-пароль"
        ],
        "security.disable.passcode.toast.message": [
            .english: "To delete the account, you must first disable passcode and Face ID in security settings.",
            .ukrainian: "Для видалення акаунту спочатку необхідно вимкнути код-пароль та Face ID у налаштуваннях безпеки.",
            .german: "Um den Account zu löschen, müssen Sie zuerst den Code und Face ID in den Sicherheitseinstellungen deaktivieren.",
            .russian: "Для удаления аккаунта сначала необходимо отключить код-пароль и Face ID в настройках безопасности."
        ],

        // MARK: - SettingsVM Messages
        "settings.photo.read.error": [
            .english: "Failed to read the photo.",
            .ukrainian: "Не вдалося прочитати фото.",
            .german: "Foto konnte nicht gelesen werden.",
            .russian: "Не удалось прочитать фото."
        ],
        "settings.pwd.changed.success": [
            .english: "Password successfully changed.",
            .ukrainian: "Пароль успішно змінено.",
            .german: "Passwort erfolgreich geändert.",
            .russian: "Пароль успешно изменён."
        ],
        "settings.pwd.created.success": [
            .english: "Password successfully created.",
            .ukrainian: "Пароль успішно створено.",
            .german: "Passwort erfolgreich erstellt.",
            .russian: "Пароль успешно создан."
        ],
        "settings.email.pwd.linked.success": [
            .english: "Email and password successfully linked.",
            .ukrainian: "Email та пароль успішно підключено.",
            .german: "E-Mail und Passwort erfolgreich verknüpft.",
            .russian: "Email и пароль успешно подключены."
        ],
        "settings.email.code.sent.success": [
            .english: "Confirmation code sent to the new email.",
            .ukrainian: "Код підтвердження надіслано на новий email.",
            .german: "Bestätigungscode an die neue E-Mail gesendet.",
            .russian: "Код подтверждения отправлен на новый email."
        ],
        "settings.enter.confirm.code": [
            .english: "Enter the confirmation code.",
            .ukrainian: "Введіть код підтвердження.",
            .german: "Bestätigungscode eingeben.",
            .russian: "Введите код подтверждения."
        ],
        "settings.email.changed.success": [
            .english: "Email successfully changed.",
            .ukrainian: "Email успішно змінено.",
            .german: "E-Mail erfolgreich geändert.",
            .russian: "Email успешно изменён."
        ],
        "settings.apple.linked.success": [
            .english: "Apple Sign in connected.",
            .ukrainian: "Apple Sign in підключено.",
            .german: "Apple Sign-in verbunden.",
            .russian: "Apple Sign in подключён."
        ],
        "settings.google.linked.success": [
            .english: "Google Sign in connected.",
            .ukrainian: "Google Sign in підключено.",
            .german: "Google Sign-in verbunden.",
            .russian: "Google Sign in подключён."
        ],
        "settings.passcode.disabled": [
            .english: "Passcode disabled.",
            .ukrainian: "Код-пароль вимкнено.",
            .german: "Code deaktiviert.",
            .russian: "Код-пароль отключён."
        ],
        "settings.passcode.saved.success": [
            .english: "Passcode successfully saved.",
            .ukrainian: "Код-пароль успішно збережено.",
            .german: "Code erfolgreich gespeichert.",
            .russian: "Код-пароль успешно сохранён."
        ],
        "settings.enter.pwd.to.delete": [
            .english: "Enter your password to confirm deletion.",
            .ukrainian: "Введіть пароль для підтвердження видалення.",
            .german: "Geben Sie Ihr Passwort ein, um die Löschung zu bestätigen.",
            .russian: "Введите пароль для подтверждения удаления."
        ],

        // MARK: - Face ID
        "settings.faceid.reason.enable": [
            .english: "Enable Face ID to protect the app.",
            .ukrainian: "Увімкніть Face ID для захисту застосунку.",
            .german: "Aktivieren Sie Face ID zum Schutz der App.",
            .russian: "Включите Face ID для защиты приложения."
        ],
        "settings.faceid.reason.disable": [
            .english: "Disable Face ID for the app.",
            .ukrainian: "Вимкніть Face ID для застосунку.",
            .german: "Deaktivieren Sie Face ID für die App.",
            .russian: "Отключите Face ID для приложения."
        ],
        "settings.faceid.not.supported": [
            .english: "Biometric authentication is not available on this device.",
            .ukrainian: "Біометрична автентифікація недоступна на цьому пристрої.",
            .german: "Biometrische Authentifizierung ist auf diesem Gerät nicht verfügbar.",
            .russian: "Биометрическая аутентификация недоступна на этом устройстве."
        ]
    ]
    */

    func localizedString(forKey key: String) -> String {
        Self.resolveString(forKey: key, languageCode: currentLanguage.rawValue)
    }
}
