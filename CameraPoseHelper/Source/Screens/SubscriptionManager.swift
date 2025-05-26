//
//  SubscriptionProduct.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 13.05.2025.
//

import Foundation
import RevenueCat
import Combine

/// Модель подписки для UI
public struct SubscriptionProduct: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let priceString: String      // Локализованная строка цены
    public let priceValue: Double       // Числовое значение цены
    public let duration: String         // Описание длительности (e.g. "1 month")
    public let trialDuration: String?   // Пробный период, если есть
    public var discount: String?        // Выгода в процентах относительно недельной подписки
    public let period: SubscriptionPeriod? // Период подписки для расчетов
    /// Сам пакет RevenueCat, чтобы сразу передать его в purchase()
    public let package: Package
}

@MainActor
public class SubscriptionManager: ObservableObject {

    public static let shared = SubscriptionManager()
    
    @Published public private(set) var products: [SubscriptionProduct] = []
    @Published public var isSubscribed: Bool = false
    @Published public var errorMessage: String?
    @Published public var purchasing: Bool = false
    
    private init() { }
    
    /// Конфигурирует RevenueCat SDK. Вызывать сразу при старте приложения.
    public func configure(apiKey: String, appUserID: String? = nil) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        Task {
            await fetchProducts(forOfferingID: "week.subscription")
            await updateSubscriptionStatus()
        }
    }
    
    /// Подгружает все доступные подписки из Offerings
    public func fetchProducts(forOfferingID offeringID: String) async {
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.offering(identifier: offeringID) else {
                self.errorMessage = "Offering с ID «\(offeringID)» не найден."
                self.products = []
                return
            }
            
            // Мапим пакеты в нашу модель с базовыми полями
            let loaded: [SubscriptionProduct] = offering.availablePackages.map { package in
                let prod = package.storeProduct
                // Преобразуем Decimal в Double для расчётов
                let priceValue = NSDecimalNumber(decimal: prod.price).doubleValue
                let durationValue = prod.subscriptionPeriod
                let durationString = durationValue.map { "\($0.value) \($0.unit.unitString(for: $0.value))" } ?? prod.localizedTitle
                
                // Пробный период
                var trial: String? = nil
                if let disc = prod.introductoryDiscount, disc.paymentMode == .freeTrial {
                    let tp = disc.subscriptionPeriod
                    trial = "\(tp.value) \(tp.unit.unitString(for: tp.value))"
                }
                
                return SubscriptionProduct(
                    id: package.identifier,
                    title: prod.localizedTitle,
                    priceString: prod.localizedPriceString,
                    priceValue: priceValue,
                    duration: durationString,
                    trialDuration: trial,
                    discount: nil,
                    period: prod.subscriptionPeriod,
                    package: package
                )
            }
            
            // Вычисляем скидки и сортируем по длительности
            self.products = Self.computeDiscountsAndSort(loaded)
            self.errorMessage = nil
            
        } catch {
            self.errorMessage = "Не удалось загрузить продукты: \(error.localizedDescription)"
            self.products = []
        }
    }
    
    /// Проверяет статус подписки
    public func updateSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.isSubscribed = !info.entitlements.active.isEmpty
            self.errorMessage = nil
        } catch {
            self.isSubscribed = false
            self.errorMessage = "Не удалось проверить статус подписки: \(error.localizedDescription)"
        }
    }
    
    /// Покупка подписки
    public func purchase(_ product: SubscriptionProduct) async {
        purchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: product.package)
            self.isSubscribed = !result.customerInfo.entitlements.active.isEmpty
            self.errorMessage = nil
            self.purchasing = false
        } catch {
            self.errorMessage = "Покупка не удалась: \(error.localizedDescription)"
            self.purchasing = false
        }
    }
    
    /// Восстановление покупок
    public func restorePurchases() async {
        self.purchasing = true
        do {
            let info = try await Purchases.shared.restorePurchases()
            self.isSubscribed = !info.entitlements.active.isEmpty
            self.errorMessage = nil
            self.purchasing = false
        } catch {
            self.errorMessage = "Восстановление не удалось: \(error.localizedDescription)"
            self.purchasing = false
        }
    }

    /// Рассчитывает выгоду в процентах относительно недельной подписки и сортирует список
    private static func computeDiscountsAndSort(_ products: [SubscriptionProduct]) -> [SubscriptionProduct] {
        // Находим недельную подписку (1 неделя)
        guard let weekly = products.first(where: {
            $0.period?.unit == .week && $0.period?.value == 1
        }) else {
            return products
        }
        let baseWeeklyPrice = weekly.priceValue
        
        let withDiscounts = products.map { prod -> SubscriptionProduct in
            var p = prod
            if let period = prod.period {
                let weeksEquivalent = period.unit.weeksEquivalent(of: period.value)
                let pricePerWeek = prod.priceValue / weeksEquivalent
                let saving = (1 - (pricePerWeek / baseWeeklyPrice)) * 100
                p.discount = String(format: "%.0f%%", max(saving, 0))
            }
            return p
        }
        
        // Сортируем: сначала недели, затем месяца по возрастанию value, затем годы
        return withDiscounts.sorted { a, b in
            guard let pa = a.period, let pb = b.period else { return false }
            func rank(_ p: SubscriptionPeriod) -> Int {
                switch p.unit {
                case .week: return p.value
                case .month: return 1000 + p.value
                case .year: return 2000 + p.value
                default: return Int.max
                }
            }
            return rank(pa) < rank(pb)
        }
    }
}

// Расширение для вспомогательных расчетов
extension SubscriptionPeriod.Unit {
    /// Возвращает базовую строку периода: "day"/"days" и т.д.
    func unitString(for value: Int) -> String {
        switch self {
        case .day:   return value == 1 ? "Day" : "Days"
        case .week:  return value == 1 ? "Week" : "Weeks"
        case .month: return value == 1 ? "Month" : "Months"
        case .year:  return value == 1 ? "Year" : "Years"
        @unknown default: return ""
        }
    }
    
    /// Конвертирует период в эквивалент недель для расчета выгоды
    func weeksEquivalent(of value: Int) -> Double {
        switch self {
        case .day:   return Double(value) / 7.0
        case .week:  return Double(value)
        case .month: return Double(value) * 4.345
        case .year:  return Double(value) * 52.143
        @unknown default: return Double(value)
        }
    }
}
