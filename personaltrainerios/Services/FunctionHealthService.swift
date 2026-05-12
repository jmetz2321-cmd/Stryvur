import Foundation
import Observation

@Observable
class FunctionHealthService {
    var isConnected = false
    var profile: FunctionHealthProfile?
    var vitals: FunctionHealthVitals?
    var isLoading = false
    var errorMessage: String?

    func connect(apiKey: String) async {
        isLoading = true
        errorMessage = nil

        // Simulate API connection — replace with real Function Health API
        try? await Task.sleep(for: .seconds(1.5))

        isConnected = true
        profile = FunctionHealthProfile(
            memberId: "FH-\(apiKey.prefix(6))",
            lastTestDate: Date().addingTimeInterval(-86400 * 30),
            overallScore: 78,
            categories: Self.sampleCategories()
        )
        vitals = FunctionHealthVitals(
            date: Date(),
            biomarkers: Self.sampleCategories().flatMap(\.biomarkers)
        )

        isLoading = false
    }

    func disconnect() {
        isConnected = false
        profile = nil
        vitals = nil
    }

    func refresh() async {
        guard isConnected else { return }
        isLoading = true
        try? await Task.sleep(for: .seconds(1))
        profile?.lastTestDate = Date()
        isLoading = false
    }

    static func sampleCategories() -> [BiomarkerCategory] {
        [
            BiomarkerCategory(name: "Heart", score: 85, biomarkers: [
                Biomarker(name: "Total Cholesterol", value: 190, unit: "mg/dL", normalRange: 125...200, category: "Heart"),
                Biomarker(name: "LDL Cholesterol", value: 110, unit: "mg/dL", normalRange: 0...100, category: "Heart"),
                Biomarker(name: "HDL Cholesterol", value: 55, unit: "mg/dL", normalRange: 40...100, category: "Heart"),
                Biomarker(name: "Triglycerides", value: 120, unit: "mg/dL", normalRange: 0...150, category: "Heart"),
                Biomarker(name: "hs-CRP", value: 0.8, unit: "mg/L", normalRange: 0...1.0, category: "Heart"),
            ], icon: "heart.fill"),
            BiomarkerCategory(name: "Metabolic", score: 72, biomarkers: [
                Biomarker(name: "Fasting Glucose", value: 95, unit: "mg/dL", normalRange: 70...100, category: "Metabolic"),
                Biomarker(name: "HbA1c", value: 5.4, unit: "%", normalRange: 4.0...5.7, category: "Metabolic"),
                Biomarker(name: "Insulin", value: 8, unit: "uIU/mL", normalRange: 2.6...11.1, category: "Metabolic"),
            ], icon: "bolt.fill"),
            BiomarkerCategory(name: "Hormones", score: 68, biomarkers: [
                Biomarker(name: "Testosterone", value: 450, unit: "ng/dL", normalRange: 300...1000, category: "Hormones"),
                Biomarker(name: "Cortisol", value: 18, unit: "ug/dL", normalRange: 6...18.4, category: "Hormones"),
                Biomarker(name: "DHEA-S", value: 280, unit: "ug/dL", normalRange: 100...400, category: "Hormones"),
                Biomarker(name: "Thyroid (TSH)", value: 2.1, unit: "mIU/L", normalRange: 0.5...4.5, category: "Hormones"),
            ], icon: "waveform.path"),
            BiomarkerCategory(name: "Nutrients", score: 62, biomarkers: [
                Biomarker(name: "Vitamin D", value: 25, unit: "ng/mL", normalRange: 30...100, category: "Nutrients"),
                Biomarker(name: "Vitamin B12", value: 500, unit: "pg/mL", normalRange: 200...900, category: "Nutrients"),
                Biomarker(name: "Ferritin (Iron)", value: 45, unit: "ng/mL", normalRange: 30...400, category: "Nutrients"),
                Biomarker(name: "Magnesium", value: 1.9, unit: "mg/dL", normalRange: 1.7...2.2, category: "Nutrients"),
            ], icon: "leaf.fill"),
            BiomarkerCategory(name: "Inflammation", score: 80, biomarkers: [
                Biomarker(name: "CRP", value: 0.8, unit: "mg/L", normalRange: 0...3.0, category: "Inflammation"),
                Biomarker(name: "Homocysteine", value: 9, unit: "umol/L", normalRange: 5...15, category: "Inflammation"),
            ], icon: "flame.fill"),
        ]
    }
}
