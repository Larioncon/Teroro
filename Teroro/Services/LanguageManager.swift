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
        "settings_title": [
            .english: "Settings",
            .ukrainian: "Налаштування",
            .german: "Einstellungen",
            .russian: "Настройки"
        ],
        "settings_language": [
            .english: "Language",
            .ukrainian: "Мова",
            .german: "Sprache",
            .russian: "Язык"
        ],
        "settings_notifications": [
            .english: "Notifications",
            .ukrainian: "Сповіщення",
            .german: "Mitteilungen",
            .russian: "Уведомления"
        ],
        "settings_appearance": [
            .english: "Appearance",
            .ukrainian: "Вид",
            .german: "Erscheinungsbild",
            .russian: "Внешний вид"
        ],
        "settings_privacy_and_security": [
            .english: "Privacy and Security",
            .ukrainian: "Приватність та безпека",
            .german: "Datenschutz & Sicherheit",
            .russian: "Конфиденциальность и безопасность"
        ],
        "settings_feedback": [
            .english: "Send Feedback",
            .ukrainian: "Написати фідбек",
            .german: "Feedback senden",
            .russian: "Написать отзыв"
        ],
        "settings_share": [
            .english: "Share App",
            .ukrainian: "Поділитися застосунком",
            .german: "App teilen",
            .russian: "Поделиться приложением"
        ],
        "settings_terms_of_use": [
            .english: "Terms of Use",
            .ukrainian: "Умови використання",
            .german: "Nutzungsbedingungen",
            .russian: "Условия использования"
        ],
        "settings_privacy_policy": [
            .english: "Privacy Policy",
            .ukrainian: "Політика конфіденційності",
            .german: "Datenschutzrichtlinie",
            .russian: "Политика конфиденциальности"
        ],
        "settings_sign_out": [
            .english: "Log Out",
            .ukrainian: "Вийти",
            .german: "Abmelden",
            .russian: "Выйти"
        ],
        "settings_profile": [
            .english: "Profile",
            .ukrainian: "Профіль",
            .german: "Profil",
            .russian: "Профиль"
        ],
        "settings_edit": [
            .english: "Edit",
            .ukrainian: "Редагувати",
            .german: "Bearbeiten",
            .russian: "Редактировать"
        ],
        "settings_take_photo": [
            .english: "Take Photo",
            .ukrainian: "Сфотографувати",
            .german: "Foto aufnehmen",
            .russian: "Сфотографировать"
        ],
        "settings_choose_gallery": [
            .english: "Choose from Gallery",
            .ukrainian: "Вибрати в галереї",
            .german: "Aus Mediathek wählen",
            .russian: "Выбрать в галерее"
        ],
        "settings_name_placeholder": [
            .english: "Name",
            .ukrainian: "Ім'я",
            .german: "Name",
            .russian: "Имя"
        ],

        // MARK: - LanguagesView
        "language_title": [
            .english: "Language",
            .ukrainian: "Мова",
            .german: "Sprache",
            .russian: "Язык"
        ],
        "language_section_interface": [
            .english: "INTERFACE LANGUAGE",
            .ukrainian: "МОВА ІНТЕРФЕЙСУ",
            .german: "OBERFLÄCHENSPRACHE",
            .russian: "ЯЗЫК ИНТЕРФЕЙСА"
        ],
        "language_header_description": [
            .english: "Choose your preferred interface language for the application.",
            .ukrainian: "Оберіть бажану мову інтерфейсу для застосунку.",
            .german: "Wählen Sie Ihre bevorzugte Oberflächensprache für die Anwendung.",
            .russian: "Выберите предпочитаемый язык интерфейса для приложения."
        ],

        // MARK: - Tab Bar
        "tab_terms": [
            .english: "Terms",
            .ukrainian: "Терміни",
            .german: "Termine",
            .russian: "Сроки"
        ],
        "tab_map": [
            .english: "Map",
            .ukrainian: "Мапа",
            .german: "Karte",
            .russian: "Карта"
        ],
        "tab_timer": [
            .english: "Timer",
            .ukrainian: "Таймер",
            .german: "Timer",
            .russian: "Таймер"
        ],
        "tab_profile": [
            .english: "Profile",
            .ukrainian: "Профіль",
            .german: "Profil",
            .russian: "Профиль"
        ],

        // MARK: - Common
        "common_error": [
            .english: "Error",
            .ukrainian: "Помилка",
            .german: "Fehler",
            .russian: "Ошибка"
        ],
        "common_ok": [
            .english: "OK",
            .ukrainian: "OK",
            .german: "OK",
            .russian: "OK"
        ],
        "common_cancel": [
            .english: "Cancel",
            .ukrainian: "Скасувати",
            .german: "Abbrechen",
            .russian: "Отмена"
        ],
        "common_save": [
            .english: "Save",
            .ukrainian: "Зберегти",
            .german: "Speichern",
            .russian: "Сохранить"
        ],
        "common_saving": [
            .english: "Saving...",
            .ukrainian: "Збереження...",
            .german: "Speichern...",
            .russian: "Сохранение..."
        ],
        "common_delete": [
            .english: "Delete",
            .ukrainian: "Видалити",
            .german: "Löschen",
            .russian: "Удалить"
        ],
        "common_edit": [
            .english: "Edit",
            .ukrainian: "Редагувати",
            .german: "Bearbeiten",
            .russian: "Редактировать"
        ],
        "common_add": [
            .english: "Add",
            .ukrainian: "Додати",
            .german: "Hinzufügen",
            .russian: "Добавить"
        ],
        "common_change": [
            .english: "Change",
            .ukrainian: "Змінити",
            .german: "Ändern",
            .russian: "Изменить"
        ],
        "common_confirm": [
            .english: "Confirm",
            .ukrainian: "Підтвердити",
            .german: "Bestätigen",
            .russian: "Подтвердить"
        ],
        "common_hide": [
            .english: "Hide",
            .ukrainian: "Сховати",
            .german: "Ausblenden",
            .russian: "Скрыть"
        ],
        "common_success": [
            .english: "Success",
            .ukrainian: "Успішно",
            .german: "Erfolg",
            .russian: "Успешно"
        ],
        "common_back": [
            .english: "Back",
            .ukrainian: "Назад",
            .german: "Zurück",
            .russian: "Назад"
        ],

        // MARK: - Home & Terms
        "home_terms": [
            .english: "Terms",
            .ukrainian: "Терміни",
            .german: "Termine",
            .russian: "Сроки"
        ],
        "home_past_terms": [
            .english: "Past Terms",
            .ukrainian: "Минулі терміни",
            .german: "Vergangene Termine",
            .russian: "Прошедшие сроки"
        ],
        "home_no_upcoming_terms": [
            .english: "No current terms",
            .ukrainian: "Немає актуальних термінів",
            .german: "Keine aktuellen Termine",
            .russian: "Нет актуальных сроков"
        ],
        "home_no_past_terms": [
            .english: "No past terms",
            .ukrainian: "Немає минулих термінів",
            .german: "Keine vergangenen Termine",
            .russian: "Нет прошедших сроков"
        ],
        "home_add_term": [
            .english: "Add Term",
            .ukrainian: "Додати термін",
            .german: "Termin hinzufügen",
            .russian: "Добавить срок"
        ],
        "home_current_terms_accessibility": [
            .english: "Current terms",
            .ukrainian: "Актуальні терміни",
            .german: "Aktuelle Termine",
            .russian: "Актуальные сроки"
        ],

        // MARK: - Term Form
        "term_form_new_title": [
            .english: "New Term",
            .ukrainian: "Новий термін",
            .german: "Neuer Termin",
            .russian: "Новый срок"
        ],
        "term_form_edit_title": [
            .english: "Edit",
            .ukrainian: "Редагувати",
            .german: "Bearbeiten",
            .russian: "Редактировать"
        ],
        "term_form_title_placeholder": [
            .english: "Title",
            .ukrainian: "Заголовок",
            .german: "Titel",
            .russian: "Заголовок"
        ],
        "term_form_details_placeholder": [
            .english: "Details",
            .ukrainian: "Деталі",
            .german: "Details",
            .russian: "Детали"
        ],
        "term_form_date_and_time": [
            .english: "Date and Time",
            .ukrainian: "Дата та час",
            .german: "Datum und Uhrzeit",
            .russian: "Дата и время"
        ],
        "term_form_date": [
            .english: "Date",
            .ukrainian: "Дата",
            .german: "Datum",
            .russian: "Дата"
        ],
        "term_form_time": [
            .english: "Time",
            .ukrainian: "Час",
            .german: "Uhrzeit",
            .russian: "Время"
        ],
        "term_form_reminder": [
            .english: "Reminder",
            .ukrainian: "Нагадування",
            .german: "Erinnerung",
            .russian: "Напоминание"
        ],
        "term_form_notify_about_term": [
            .english: "Notify about term",
            .ukrainian: "Повідомити про термін",
            .german: "Über Termin benachrichtigen",
            .russian: "Уведомить о сроке"
        ],
        "term_form_when": [
            .english: "When?",
            .ukrainian: "Коли?",
            .german: "Wann?",
            .russian: "Когда?"
        ],
        "term_form_location": [
            .english: "Location",
            .ukrainian: "Місце",
            .german: "Ort",
            .russian: "Место"
        ],
        "term_form_offline": [
            .english: "(offline)",
            .ukrainian: "(офлайн)",
            .german: "(offline)",
            .russian: "(офлайн)"
        ],
        "term_form_add_meeting_address": [
            .english: "Add an address for the meeting",
            .ukrainian: "Додайте адресу для зустрічі",
            .german: "Adresse für das Treffen hinzufügen",
            .russian: "Добавьте адрес для встречи"
        ],
        "term_form_location_unavailable_offline": [
            .english: "Location selection is unavailable without internet",
            .ukrainian: "Вибір локації недоступний без інтернету",
            .german: "Ortsauswahl ohne Internet nicht verfügbar",
            .russian: "Выбор локации недоступен без интернета"
        ],
        "term_form_location_selected": [
            .english: "Location selected",
            .ukrainian: "Локація обрана",
            .german: "Ort ausgewählt",
            .russian: "Локация выбрана"
        ],

        // MARK: - Map & Location Picker
        "map_search_title": [
            .english: "Search Location",
            .ukrainian: "Пошук місця",
            .german: "Ort suchen",
            .russian: "Поиск места"
        ],
        "map_search_placeholder": [
            .english: "City or address",
            .ukrainian: "Місто або адреса",
            .german: "Stadt oder Adresse",
            .russian: "Город или адрес"
        ],
        "map_nothing_found": [
            .english: "Nothing found",
            .ukrainian: "Нічого не знайдено",
            .german: "Nichts gefunden",
            .russian: "Ничего не найдено"
        ],
        "map_select_this_location": [
            .english: "Select this location",
            .ukrainian: "Обрати цю локацію",
            .german: "Diesen Ort auswählen",
            .russian: "Выбрать эту локацию"
        ],
        "map_determining_address": [
            .english: "Determining address...",
            .ukrainian: "Визначаємо адресу...",
            .german: "Adresse wird ermittelt...",
            .russian: "Определяем адрес..."
        ],
        "map_location_on_map": [
            .english: "Location on map",
            .ukrainian: "Локація на карті",
            .german: "Ort auf der Karte",
            .russian: "Локация на карте"
        ],
        "map_pin_on_map": [
            .english: "Pin on map",
            .ukrainian: "Позначка на карті",
            .german: "Kartenmarkierung",
            .russian: "Отметка на карте"
        ],
        "map_hint_location": [
            .english: "Where am I? Find yourself near your tasks with one tap.",
            .ukrainian: "Де я зараз? В один дотик знайдіть себе поруч зі своїми справами.",
            .german: "Wo bin ich? Finden Sie sich mit einem Fingertipp bei Ihren Aufgaben.",
            .russian: "Где я сейчас? В одно касание найдите себя рядом со своими делами."
        ],
        "map_hint_standard": [
            .english: "Standard view: clean map without visual clutter — just streets and addresses.",
            .ukrainian: "Стандартний вигляд: проста схема без візуального шуму — лише вулиці й адреси.",
            .german: "Standardansicht: einfache Karte ohne optische Ablenkung — nur Straßen und Adressen.",
            .russian: "Стандартный вид: простая схема без визуального шума — только улицы и адреса."
        ],
        "map_hint_hybrid": [
            .english: "Satellite layer: real view of buildings and landmarks.",
            .ukrainian: "Супутниковий шар: реальний вигляд будівель та орієнтирів.",
            .german: "Satellitenebene: reale Ansicht von Gebäuden und Orientierungspunkten.",
            .russian: "Спутниковый слой: реальный вид зданий и ориентиров."
        ],
        "map_loading_terms_title": [
            .english: "Loading terms",
            .ukrainian: "Завантаження термінів",
            .german: "Termine laden",
            .russian: "Загрузка сроков"
        ],
        "map_loading_terms_subtitle": [
            .english: "The map will update after syncing.",
            .ukrainian: "Мапа оновиться після синхронізації.",
            .german: "Die Karte wird nach der Synchronisierung aktualisiert.",
            .russian: "Карта обновится после синхронизации."
        ],
        "map_empty_terms_title": [
            .english: "No upcoming terms",
            .ukrainian: "Немає майбутніх термінів",
            .german: "Keine bevorstehenden Termine",
            .russian: "Нет предстоящих сроков"
        ],
        "map_empty_terms_subtitle": [
            .english: "Schedule a new term to see it on the map.",
            .ukrainian: "Заплануйте новий термін, щоб побачити його на мапі.",
            .german: "Planen Sie einen neuen Termin, um ihn auf der Karte zu sehen.",
            .russian: "Запланируйте новый срок, чтобы увидеть его на карте."
        ],
        "map_empty_locations_title": [
            .english: "No locations",
            .ukrainian: "Немає локацій",
            .german: "Keine Orte",
            .russian: "Нет локаций"
        ],
        "map_empty_locations_subtitle": [
            .english: "Upcoming terms without a place are not shown on the map.",
            .ukrainian: "Майбутні терміни без місця не відображаються на мапі.",
            .german: "Bevorstehende Termine ohne Ort werden nicht auf der Karte angezeigt.",
            .russian: "Предстоящие сроки без места не отображаются на карте."
        ],
        "map_terms_map_card_title": [
            .english: "Terms Map",
            .ukrainian: "Мапа термінів",
            .german: "Terminekarte",
            .russian: "Карта сроков"
        ],
        "map_terms_map_card_subtitle": [
            .english: "Shows only upcoming terms with a location.",
            .ukrainian: "Показує лише майбутні терміни з локацією.",
            .german: "Zeigt nur bevorstehende Termine mit einem Ort.",
            .russian: "Показывает только предстоящие сроки с локацией."
        ],

        // MARK: - Pomodoro / Timer
        "timer_hint_change_duration": [
            .english: "Tap to change period duration.",
            .ukrainian: "Натисніть, щоб змінити тривалість періоду.",
            .german: "Tippen Sie hier, um die Dauer des Zeitraums zu ändern.",
            .russian: "Нажмите чтоб изменить длительность периода."
        ],
        "timer_start": [
            .english: "START",
            .ukrainian: "СТАРТ",
            .german: "START",
            .russian: "СТАРТ"
        ],
        "timer_pause": [
            .english: "PAUSE",
            .ukrainian: "ПАУЗА",
            .german: "PAUSE",
            .russian: "ПАУЗА"
        ],
        "timer_stop": [
            .english: "STOP",
            .ukrainian: "СТОП",
            .german: "STOP",
            .russian: "СТОП"
        ],
        "timer_finish": [
            .english: "FINISH",
            .ukrainian: "ЗАВЕРШИТИ",
            .german: "BEENDEN",
            .russian: "ЗАВЕРШИТЬ"
        ],
        "timer_focus_time": [
            .english: "FOCUS TIME",
            .ukrainian: "ЧАС ФОКУСУ",
            .german: "FOKUSZEIT",
            .russian: "ВРЕМЯ ФОКУСА"
        ],
        "timer_relax": [
            .english: "RELAX",
            .ukrainian: "ВІДПОЧИНОК",
            .german: "PAUSE",
            .russian: "ОТДЫХ"
        ],
        "timer_duration": [
            .english: "Duration",
            .ukrainian: "Тривалість",
            .german: "Dauer",
            .russian: "Длительность"
        ],
        "timer_done": [
            .english: "Done",
            .ukrainian: "Готово",
            .german: "Fertig",
            .russian: "Готово"
        ],
        "timer_notifications_disabled": [
            .english: "Notifications disabled",
            .ukrainian: "Сповіщення вимкнено",
            .german: "Mitteilungen deaktiviert",
            .russian: "Уведомления отключены"
        ],

        // MARK: - Paywall
        "paywall_unlock_pro": [
            .english: "Unlock Pro",
            .ukrainian: "Розблокуйте Pro",
            .german: "Pro freischalten",
            .russian: "Разблокируйте Pro"
        ],
        "paywall_subtitle": [
            .english: "Keep terms, reminders and focus tools fully available.",
            .ukrainian: "Зберігайте терміни, нагадування та інструменти фокусу повністю доступними.",
            .german: "Halten Sie Termine, Erinnerungen und Fokus-Tools voll verfügbar.",
            .russian: "Сохраняйте сроки, напоминания и инструменты фокуса полностью доступными."
        ],
        "paywall_processing": [
            .english: "Processing...",
            .ukrainian: "Обробка...",
            .german: "Wird verarbeitet...",
            .russian: "Обработка..."
        ],
        "paywall_continue": [
            .english: "Continue",
            .ukrainian: "Продовжити",
            .german: "Fortfahren",
            .russian: "Продолжить"
        ],
        "Restore": [
            .english: "Restore",
            .ukrainian: "Відновити покупки",
            .german: "Wiederherstellen",
            .russian: "Восстановить покупки"
        ],
        "Terms and conditions": [
            .english: "Terms and conditions",
            .ukrainian: "Умови використання",
            .german: "Nutzungsbedingungen",
            .russian: "Условия использования"
        ],
        "Privacy policy": [
            .english: "Privacy policy",
            .ukrainian: "Політика конфіденційності",
            .german: "Datenschutzrichtlinie",
            .russian: "Политика конфиденциальности"
        ],
        "paywall_get_free_trial": [
            .english: "Get 3 Days Free Trial",
            .ukrainian: "Отримайте 3 дні безкоштовно",
            .german: "3 Tage kostenlos testen",
            .russian: "Получите 3 дня бесплатно"
        ],
        "paywall_free_trial_enabled": [
            .english: "Free Trial Enabled",
            .ukrainian: "Пробний період увімкнено",
            .german: "Kostenlose Testversion aktiviert",
            .russian: "Пробный период включен"
        ],
        "paywall_free_trial_disabled": [
            .english: "Free Trial Disabled",
            .ukrainian: "Пробний період вимкнено",
            .german: "Kostenlose Testversion deaktiviert",
            .russian: "Пробный период отключен"
        ],
        "paywall_trial_includes_desc": [
            .english: "Plans include 3 days free trial.",
            .ukrainian: "Тарифи містять 3 дні безкоштовного пробного періоду.",
            .german: "Pläne enthalten eine 3-tägige kostenlose Testphase.",
            .russian: "Тарифы включают 3 дня бесплатного пробного периода."
        ],
        "paywall_trial_starts_without_desc": [
            .english: "Plans start without trial.",
            .ukrainian: "Тарифи починаються без пробного періоду.",
            .german: "Pläne beginnen ohne Testphase.",
            .russian: "Тарифы начинаются без пробного периода."
        ],
        "paywall_close": [
            .english: "Close",
            .ukrainian: "Закрити",
            .german: "Schließen",
            .russian: "Закрыть"
        ],
        "plan_period_week": [
            .english: "Week",
            .ukrainian: "Тиждень",
            .german: "Woche",
            .russian: "Неделя"
        ],
        "plan_period_month": [
            .english: "Month",
            .ukrainian: "Місяць",
            .german: "Monat",
            .russian: "Месяц"
        ],
        "plan_period_year": [
            .english: "Year",
            .ukrainian: "Рік",
            .german: "Jahr",
            .russian: "Год"
        ],
        "plan_get_weekly": [
            .english: "Get weekly plan",
            .ukrainian: "Отримати тижневий план",
            .german: "Wochenplan wählen",
            .russian: "Получить недельный план"
        ],
        "plan_get_monthly": [
            .english: "Get monthly plan",
            .ukrainian: "Отримати місячний план",
            .german: "Monatsplan wählen",
            .russian: "Получить месячный план"
        ],
        "plan_get_annual": [
            .english: "Get annual plan",
            .ukrainian: "Отримати річний план",
            .german: "Jahresplan wählen",
            .russian: "Получить годовой план"
        ],

        // MARK: - Privacy & Security
        "security_passcode": [
            .english: "Passcode",
            .ukrainian: "Код-пароль",
            .german: "Code",
            .russian: "Код-пароль"
        ],
        "security_enabled": [
            .english: "Enabled",
            .ukrainian: "Увімкнено",
            .german: "Aktiviert",
            .russian: "Включено"
        ],
        "security_disabled": [
            .english: "Disabled",
            .ukrainian: "Вимкнено",
            .german: "Deaktiviert",
            .russian: "Выключено"
        ],
        "security_change_password": [
            .english: "Change Password",
            .ukrainian: "Змінити пароль",
            .german: "Passwort ändern",
            .russian: "Изменить пароль"
        ],
        "security_change_email": [
            .english: "Change Email",
            .ukrainian: "Змінити email",
            .german: "E-Mail ändern",
            .russian: "Изменить email"
        ],
        "security_add_email": [
            .english: "Add Email",
            .ukrainian: "Додайте Email",
            .german: "E-Mail hinzufügen",
            .russian: "Добавьте Email"
        ],
        "security_signin_methods": [
            .english: "Sign-in Methods",
            .ukrainian: "Способи входу",
            .german: "Anmeldemethoden",
            .russian: "Способы входа"
        ],
        "security_connected": [
            .english: "Connected",
            .ukrainian: "Підключено",
            .german: "Verbunden",
            .russian: "Подключено"
        ],
        "security_connect": [
            .english: "Connect",
            .ukrainian: "Підключити",
            .german: "Verbinden",
            .russian: "Подключить"
        ],
        "security_delete_account": [
            .english: "Delete Account",
            .ukrainian: "Видалити акаунт",
            .german: "Account löschen",
            .russian: "Удалить аккаунт"
        ],
        "security_passcode_lock_title": [
            .english: "Passcode Lock",
            .ukrainian: "Блокування код-паролем",
            .german: "Codesperre",
            .russian: "Блокировка код-паролем"
        ],
        "security_turn_off_passcode": [
            .english: "Turn Passcode Off",
            .ukrainian: "Вимкнути код-пароль",
            .german: "Code ausschalten",
            .russian: "Отключить код-пароль"
        ],
        "security_turn_on_passcode": [
            .english: "Turn Passcode On",
            .ukrainian: "Увімкнути код-пароль",
            .german: "Code einschalten",
            .russian: "Включить код-пароль"
        ],
        "security_change_passcode": [
            .english: "Change Passcode",
            .ukrainian: "Змінити код-пароль",
            .german: "Code ändern",
            .russian: "Изменить код-пароль"
        ],
        "security_auto_lock_desc": [
            .english: "When passcode is on, Timexo will require it upon launch or returning to the app according to Auto-Lock.",
            .ukrainian: "Коли код-пароль увімкнено, Timexo буде запитувати його при запуску або після повернення у застосунок згідно з Auto-Lock.",
            .german: "Wenn der Code aktiviert ist, fordert Timexo ihn beim Start oder bei der Rückkehr in die App gemäß Auto-Lock an.",
            .russian: "Когда код-пароль включен, Timexo будет запрашивать его при запуске или после возврата в приложение согласно Auto-Lock."
        ],
        "security_unlock_face_id": [
            .english: "Unlock with Face ID",
            .ukrainian: "Розблокування з Face ID",
            .german: "Mit Face ID entsperren",
            .russian: "Разблокировка с Face ID"
        ],
        "security_enter_passcode": [
            .english: "Enter Timexo passcode",
            .ukrainian: "Введіть код-пароль Timexo",
            .german: "Timexo-Code eingeben",
            .russian: "Введите код-пароль Timexo"
        ],
        "security_confirm_passcode": [
            .english: "Confirm Timexo passcode",
            .ukrainian: "Підтвердіть код-пароль Timexo",
            .german: "Timexo-Code bestätigen",
            .russian: "Подтвердите код-пароль Timexo"
        ],
        "security_passcodes_do_not_match": [
            .english: "Passcodes do not match",
            .ukrainian: "Коди-паролі не співпадають",
            .german: "Codes stimmen nicht überein",
            .russian: "Коды-пароли не совпадают"
        ],
        "security_app_lock_prompt": [
            .english: "Enter your Timexo Passcode",
            .ukrainian: "Введіть код-пароль Timexo",
            .german: "Geben Sie Ihren Timexo-Code ein",
            .russian: "Введите код-пароль Timexo"
        ],
        "security_autolock_always": [
            .english: "Immediately",
            .ukrainian: "Завжди",
            .german: "Sofort",
            .russian: "Сразу"
        ],
        "security_autolock_1min": [
            .english: "If away for 1 min",
            .ukrainian: "Якщо відсутній 1 хв",
            .german: "Nach 1 Min. Abwesenheit",
            .russian: "Если отсутствует 1 мин"
        ],
        "security_autolock_5min": [
            .english: "If away for 5 min",
            .ukrainian: "Якщо відсутній 5 хв",
            .german: "Nach 5 Min. Abwesenheit",
            .russian: "Если отсутствует 5 мин"
        ],
        "security_autolock_1hour": [
            .english: "If away for 1 hour",
            .ukrainian: "Якщо відсутній 1 год",
            .german: "Nach 1 Std. Abwesenheit",
            .russian: "Если отсутствует 1 час"
        ],
        "security_autolock_5hours": [
            .english: "If away for 5 hours",
            .ukrainian: "Якщо відсутній 5 год",
            .german: "Nach 5 Std. Abwesenheit",
            .russian: "Если отсутствует 5 часов"
        ],
        "security_change_pwd_title": [
            .english: "Change Password",
            .ukrainian: "Зміна паролю",
            .german: "Passwort ändern",
            .russian: "Смена пароля"
        ],
        "security_current_pwd": [
            .english: "Current Password",
            .ukrainian: "Поточний пароль",
            .german: "Aktuelles Passwort",
            .russian: "Текущий пароль"
        ],
        "security_new_pwd": [
            .english: "New Password",
            .ukrainian: "Новий пароль",
            .german: "Neues Passwort",
            .russian: "Новый пароль"
        ],
        "security_confirm_new_pwd": [
            .english: "Confirm New Password",
            .ukrainian: "Підтвердіть новий пароль",
            .german: "Neues Passwort bestätigen",
            .russian: "Подтвердите новый пароль"
        ],
        "security_pwd_rules": [
            .english: "Password must contain at least 8 characters, an uppercase letter, a lowercase letter, and a number.",
            .ukrainian: "Пароль повинен містити щонайменше 8 символів, велику та малу літери, а також цифру.",
            .german: "Das Passwort muss mindestens 8 Zeichen, einen Großbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten.",
            .russian: "Пароль должен содержать не менее 8 символов, заглавную и строчную буквы, а также цифру."
        ],
        "security_change_email_title": [
            .english: "Change Email",
            .ukrainian: "Зміна Email",
            .german: "E-Mail ändern",
            .russian: "Смена Email"
        ],
        "security_new_email_field": [
            .english: "New Email",
            .ukrainian: "Новий Email",
            .german: "Neue E-Mail",
            .russian: "Новый Email"
        ],
        "security_change_email_prompt_footer": [
            .english: "Current email: %@. After confirming password, a verification email will be sent to the new email.",
            .ukrainian: "Поточний email: %@. Після підтвердження паролю, надійде лист на новий email для верифікації.",
            .german: "Aktuelle E-Mail: %@. Nach der Bestätigung des Passworts wird eine Bestätigungs-E-Mail an die neue Adresse gesendet.",
            .russian: "Текущий email: %@. После подтверждения пароля на новый email будет отправлено письмо для подтверждения."
        ],
        "security_change_email_code_sent_footer": [
            .english: "Current email: %@. Enter the code from Firebase email sent to the new email. If it contains a link, use the oobCode parameter value.",
            .ukrainian: "Поточний email: %@. Введіть код з листа Firebase, який прийшов на новий email. Якщо лист містить посилання, використайте значення параметра oobCode.",
            .german: "Aktuelle E-Mail: %@. Geben Sie den Code aus der Firebase-E-Mail ein, die an die neue E-Mail gesendet wurde. Wenn die E-Mail einen Link enthält, verwenden Sie den Wert des Parameters oobCode.",
            .russian: "Текущий email: %@. Введите код из письма Firebase, которое пришло на новый email. Если письмо содержит ссылку, используйте значение параметра oobCode."
        ],
        "security_send": [
            .english: "Send",
            .ukrainian: "Надіслати",
            .german: "Senden",
            .russian: "Отправить"
        ],
        "security_confirmation_section": [
            .english: "Confirmation",
            .ukrainian: "Підтвердження",
            .german: "Bestätigung",
            .russian: "Подтверждение"
        ],
        "security_verification_code_field": [
            .english: "Verification code",
            .ukrainian: "Код підтвердження",
            .german: "Bestätigungscode",
            .russian: "Код подтверждения"
        ],
        "security_add_email_title": [
            .english: "Add Email",
            .ukrainian: "Додати email",
            .german: "E-Mail hinzufügen",
            .russian: "Добавить email"
        ],
        "security_password_placeholder": [
            .english: "Password",
            .ukrainian: "Пароль",
            .german: "Passwort",
            .russian: "Пароль"
        ],
        "security_confirm_pwd_placeholder": [
            .english: "Confirm password",
            .ukrainian: "Підтвердіть пароль",
            .german: "Passwort bestätigen",
            .russian: "Подтвердите пароль"
        ],
        "security_delete_account_title": [
            .english: "Delete Account",
            .ukrainian: "Видалення акаунту",
            .german: "Account löschen",
            .russian: "Удаление аккаунта"
        ],
        "security_delete_warning_title": [
            .english: "Warning! Action is irreversible",
            .ukrainian: "Увага! Дія незворотна",
            .german: "Achtung! Aktion ist unwiderruflich",
            .russian: "Внимание! Действие необратимо"
        ],
        "security_delete_warning_desc": [
            .english: "Deleting your account will permanently destroy all your data, including saved terms, profile, and settings.",
            .ukrainian: "Видалення акаунту призведе до повного та безповоротного знищення всіх ваших даних, включаючи збережені терміни, профіль та налаштування.",
            .german: "Das Löschen Ihres Accounts führt zur vollständigen und unwiderruflichen Löschung aller Ihrer Daten, einschließlich gespeicherter Termine, Profil und Einstellungen.",
            .russian: "Удаление аккаунта приведет к полному и безвозвратному уничтожению всех ваших данных, включая сохраненные сроки, профиль и настройки."
        ],
        "security_confirm_pwd_section": [
            .english: "Confirmation via Email / Password",
            .ukrainian: "Підтвердження через Email / Пароль",
            .german: "Bestätigung über E-Mail / Passwort",
            .russian: "Подтверждение через Email / Пароль"
        ],
        "security_enter_your_pwd": [
            .english: "Enter your password",
            .ukrainian: "Введіть ваш пароль",
            .german: "Geben Sie Ihr Passwort ein",
            .russian: "Введите ваш пароль"
        ],
        "security_confirm_and_delete_account": [
            .english: "Confirm and Delete Account",
            .ukrainian: "Підтвердити та видалити акаунт",
            .german: "Bestätigen und Account löschen",
            .russian: "Подтвердить и удалить аккаунт"
        ],
        "security_confirm_google_section": [
            .english: "Confirmation via Google",
            .ukrainian: "Підтвердження через Google",
            .german: "Bestätigung über Google",
            .russian: "Подтверждение через Google"
        ],
        "security_confirm_google_delete": [
            .english: "Confirm with Google and Delete",
            .ukrainian: "Підтвердити через Google та видалити",
            .german: "Mit Google bestätigen und löschen",
            .russian: "Подтвердить через Google и удалить"
        ],
        "security_confirm_apple_section": [
            .english: "Confirmation via Apple",
            .ukrainian: "Підтвердження через Apple",
            .german: "Bestätigung über Apple",
            .russian: "Подтверждение через Apple"
        ],
        "security_confirm_apple_delete": [
            .english: "Confirm with Apple and Delete",
            .ukrainian: "Підтвердити через Apple та видалити",
            .german: "Mit Apple bestätigen und löschen",
            .russian: "Подтвердить через Apple и удалить"
        ],
        "security_disable_passcode_toast_title": [
            .english: "Disable Passcode",
            .ukrainian: "Вимкніть код-пароль",
            .german: "Code deaktivieren",
            .russian: "Отключите код-пароль"
        ],
        "security_disable_passcode_toast_message": [
            .english: "To delete the account, you must first disable passcode and Face ID in security settings.",
            .ukrainian: "Для видалення акаунту спочатку необхідно вимкнути код-пароль та Face ID у налаштуваннях безпеки.",
            .german: "Um den Account zu löschen, müssen Sie zuerst den Code und Face ID in den Sicherheitseinstellungen deaktivieren.",
            .russian: "Для удаления аккаунта сначала необходимо отключить код-пароль и Face ID в настройках безопасности."
        ],

        // MARK: - SettingsVM Messages
        "settings_photo_read_error": [
            .english: "Failed to read the photo.",
            .ukrainian: "Не вдалося прочитати фото.",
            .german: "Foto konnte nicht gelesen werden.",
            .russian: "Не удалось прочитать фото."
        ],
        "settings_pwd_changed_success": [
            .english: "Password successfully changed.",
            .ukrainian: "Пароль успішно змінено.",
            .german: "Passwort erfolgreich geändert.",
            .russian: "Пароль успешно изменён."
        ],
        "settings_pwd_created_success": [
            .english: "Password successfully created.",
            .ukrainian: "Пароль успішно створено.",
            .german: "Passwort erfolgreich erstellt.",
            .russian: "Пароль успешно создан."
        ],
        "settings_email_pwd_linked_success": [
            .english: "Email and password successfully linked.",
            .ukrainian: "Email та пароль успішно підключено.",
            .german: "E-Mail und Passwort erfolgreich verknüpft.",
            .russian: "Email и пароль успешно подключены."
        ],
        "settings_email_code_sent_success": [
            .english: "Confirmation code sent to the new email.",
            .ukrainian: "Код підтвердження надіслано на новий email.",
            .german: "Bestätigungscode an die neue E-Mail gesendet.",
            .russian: "Код подтверждения отправлен на новый email."
        ],
        "settings_enter_confirm_code": [
            .english: "Enter the confirmation code.",
            .ukrainian: "Введіть код підтвердження.",
            .german: "Bestätigungscode eingeben.",
            .russian: "Введите код подтверждения."
        ],
        "settings_email_changed_success": [
            .english: "Email successfully changed.",
            .ukrainian: "Email успішно змінено.",
            .german: "E-Mail erfolgreich geändert.",
            .russian: "Email успешно изменён."
        ],
        "settings_apple_linked_success": [
            .english: "Apple Sign in connected.",
            .ukrainian: "Apple Sign in підключено.",
            .german: "Apple Sign-in verbunden.",
            .russian: "Apple Sign in подключён."
        ],
        "settings_google_linked_success": [
            .english: "Google Sign in connected.",
            .ukrainian: "Google Sign in підключено.",
            .german: "Google Sign-in verbunden.",
            .russian: "Google Sign in подключён."
        ],
        "settings_passcode_disabled": [
            .english: "Passcode disabled.",
            .ukrainian: "Код-пароль вимкнено.",
            .german: "Code deaktiviert.",
            .russian: "Код-пароль отключён."
        ],
        "settings_passcode_saved_success": [
            .english: "Passcode successfully saved.",
            .ukrainian: "Код-пароль успішно збережено.",
            .german: "Code erfolgreich gespeichert.",
            .russian: "Код-пароль успешно сохранён."
        ],
        "settings_enter_pwd_to_delete": [
            .english: "Enter your password to confirm deletion.",
            .ukrainian: "Введіть пароль для підтвердження видалення.",
            .german: "Geben Sie Ihr Passwort ein, um die Löschung zu bestätigen.",
            .russian: "Введите пароль для подтверждения удаления."
        ],

        // MARK: - Face ID
        "settings.faceid.reason_enable": [
            .english: "Enable Face ID to protect the app.",
            .ukrainian: "Увімкніть Face ID для захисту застосунку.",
            .german: "Aktivieren Sie Face ID zum Schutz der App.",
            .russian: "Включите Face ID для защиты приложения."
        ],
        "settings.faceid.reason_disable": [
            .english: "Disable Face ID for the app.",
            .ukrainian: "Вимкніть Face ID для застосунку.",
            .german: "Deaktivieren Sie Face ID für die App.",
            .russian: "Отключите Face ID для приложения."
        ],
        "settings.faceid.not_supported": [
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
