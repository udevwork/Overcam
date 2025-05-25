//import FirebaseRemoteConfig
//
//class RemoteConfigManager {
//    static let shared = RemoteConfigManager()
//    
//    private(set) var isConfigured: Bool = false
//    
//    private var remoteConfig: RemoteConfig
//    
//    subscript(index: String) -> RemoteConfigValue {
//        get {
//            remoteConfig[index]
//        }
//    }
//    
//    private init() {
//        // Инициализация Remote Config
//        self.remoteConfig = RemoteConfig.remoteConfig()
//        
//        // Настройка интервала обновления для тестирования
//        let settings = RemoteConfigSettings()
//        settings.minimumFetchInterval = 36000
//        remoteConfig.configSettings = settings
//        
//    }
//    
//    // Метод для загрузки параметров с сервера
//    func fetchRemoteConfig(completion: @escaping (Bool) -> Void) {
//        remoteConfig.fetch { status, error in
//            if status == .success {
//                self.remoteConfig.activate { _, _ in
//                    print("Remote Config активирован")
//                    self.isConfigured = true
//                    completion(true)
//                }
//            } else {
//                print("Ошибка получения Remote Config: \(error?.localizedDescription ?? "Нет информации об ошибке")")
//                self.isConfigured = false
//                completion(false)
//            }
//        }
//    }
//    
//    
//    func fetchRemoteConfig() {
//        remoteConfig.fetch { status, error in
//            if status == .success {
//                self.remoteConfig.activate { _, _ in
//                    print("Remote Config активирован")
//                    self.isConfigured = true
//                }
//            } else {
//                print("Ошибка получения Remote Config: \(error?.localizedDescription ?? "Нет информации об ошибке")")
//                self.isConfigured = false
//            }
//        }
//    }
//    
//}
