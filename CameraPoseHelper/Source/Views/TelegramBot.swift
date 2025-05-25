//
//  TelegramBot.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import Foundation

final class TelegramBot {
    static let shared = TelegramBot()
    
    private init() {}
    
    private let botToken = "7500780332:AAGSMqxs114_JZHp-IOMLPF70GCmHlIkoaM"
    private let chatId = "308922388"
    
    func sendMessage(_ text: String) {

        guard let url = URL(string: "https://api.telegram.org/bot\(botToken)/sendMessage") else {
            return
        }
        
        // Формируем тело POST-запроса
        let body: [String: Any] = [
            "chat_id": chatId,
            "text": "[OverCam]: " + text,
            "parse_mode": "Markdown"
        ]
        
        // Преобразуем тело запроса в JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            return
        }
        
        // Настраиваем запрос
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при отправке сообщения: \(error.localizedDescription)")
                return
            }
            
            if let data = data,
               let result = String(data: data, encoding: .utf8) {
                print("Ответ Telegram: \(result)")
            }
        }
        task.resume()

    }
}
