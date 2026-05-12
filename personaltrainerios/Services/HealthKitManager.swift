import Foundation
import HealthKit
import Observation

@Observable
class HealthKitManager {
    let healthStore = HKHealthStore()
    var isAuthorized = false {
        didSet { UserDefaults.standard.set(isAuthorized, forKey: "healthKitAuthorized") }
    }
    var todaySnapshot: HealthSnapshot?
    var weeklySnapshots: [HealthSnapshot] = []

    init() {
        if UserDefaults.standard.bool(forKey: "healthKitAuthorized") && HKHealthStore.isHealthDataAvailable() {
            isAuthorized = true
            Task {
                await fetchTodayData()
                startObservingChanges()
            }
        }
    }

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(calories) }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(weight) }
        if let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) { types.insert(bodyFat) }
        if let exercise = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) { types.insert(exercise) }
        types.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        return types
    }()

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayData()
            startObservingChanges()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    private func startObservingChanges() {
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .heartRate, .restingHeartRate,
            .bodyMass, .bodyFatPercentage, .appleExerciseTime
        ]

        for identifier in quantityTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, _, _ in
                guard let self else { return }
                Task { await self.fetchTodayData() }
            }
            healthStore.execute(query)
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepQuery = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, _, _ in
            guard let self else { return }
            Task { await self.fetchTodayData() }
        }
        healthStore.execute(sleepQuery)
    }

    func fetchTodayData() async {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        async let steps = fetchSum(.stepCount, start: startOfDay, end: now, unit: .count())
        async let calories = fetchSum(.activeEnergyBurned, start: startOfDay, end: now, unit: .kilocalorie())
        async let activeMin = fetchSum(.appleExerciseTime, start: startOfDay, end: now, unit: .minute())
        async let hr = fetchLatest(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let restHR = fetchLatest(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let sleep = fetchSleepHours(date: now)
        async let weight = fetchLatest(.bodyMass, unit: .pound())
        async let bodyFat = fetchLatest(.bodyFatPercentage, unit: .percent())

        let s = await steps
        let c = await calories
        let a = await activeMin
        let h = await hr
        let rh = await restHR
        let sl = await sleep
        let w = await weight
        let bf = await bodyFat

        let quality: HealthSnapshot.SleepQuality = {
            if sl >= 8 { return .excellent }
            if sl >= 7 { return .good }
            if sl >= 5.5 { return .fair }
            return .poor
        }()

        todaySnapshot = HealthSnapshot(
            date: now,
            steps: Int(s),
            caloriesBurned: c,
            activeMinutes: Int(a),
            heartRate: h,
            restingHeartRate: rh,
            sleepHours: sl,
            sleepQuality: quality,
            weight: w > 0 ? w : nil,
            bodyFatPercentage: bf > 0 ? bf : nil
        )
    }

    private func fetchSum(_ identifier: HKQuantityTypeIdentifier, start: Date, end: Date, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepHours(date: Date) async -> Double {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let startOfDay = Calendar.current.date(byAdding: .hour, value: -12, to: Calendar.current.startOfDay(for: date))!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: date, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalSeconds = (samples as? [HKCategorySample])?.reduce(0.0) { total, sample in
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        return total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    return total
                } ?? 0
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            healthStore.execute(query)
        }
    }
}
