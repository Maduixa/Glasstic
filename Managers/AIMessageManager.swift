import Foundation
import NaturalLanguage

class AIMessageManager {
    static let shared = AIMessageManager()
    private init() {}
    
    // Templates for different message types
    private let motivationalTemplates = [
        "You're doing amazing! Keep pushing forward with your {zone} journey.",
        "Your body is now experiencing the benefits of {zone}. Stay strong!",
        "Great work entering {zone}! Your dedication is paying off.",
        "You've reached {zone} - your body is thanking you for this commitment.",
        "Fantastic progress! You're in {zone} and unlocking incredible health benefits."
    ]
    
    private let educationalTemplates = [
        "During {zone}, your body is {process}. This helps with {benefit}.",
        "Right now in {zone}, {process} is happening, which supports {benefit}.",
        "Your {zone} phase means {process}, leading to {benefit}.",
        "In this {zone} stage, your body focuses on {process} for {benefit}."
    ]
    
    private let notificationTemplates = [
        "🎉 Congratulations! You've completed your {hours}-hour fast! Your body has been through an amazing transformation.",
        "✨ Well done! {hours} hours of fasting complete. You've given your body the gift of healing time.",
        "🌟 Amazing achievement! Your {hours}-hour fast is done. Your cells are celebrating this reset!",
        "🔥 Incredible! You've finished {hours} hours of fasting. Your metabolic health is thanking you!"
    ]
    
    func generateFastingMessage(for zone: FastingZone, messageType: MessageType) -> String {
        let templates = getTemplates(for: messageType)
        let template = templates.randomElement() ?? templates.first!
        
        return personalizeMessage(template: template, zone: zone)
    }
    
    func generateNotificationMessage(for duration: TimeInterval) -> (title: String, body: String) {
        let hours = Int(duration / 3600)
        let template = notificationTemplates.randomElement()!
        let body = template.replacingOccurrences(of: "{hours}", with: "\(hours)")
        
        let titles = ["Fasting Complete! 🎉", "Well Done! ✨", "Amazing Achievement! 🌟", "Incredible Work! 🔥"]
        let title = titles.randomElement()!
        
        return (title: title, body: body)
    }
    
    func generateContextualMessage(for zone: FastingZone, timeInZone: TimeInterval) -> String {
        let timeHours = Int(timeInZone / 3600)
        let timeMinutes = Int(timeInZone.truncatingRemainder(dividingBy: 3600) / 60)
        
        let contextualTemplates = [
            "You've been in \(zone.name) for \(timeHours)h \(timeMinutes)m. \(zone.emoji) {encouragement}",
            "\(zone.emoji) \(timeHours) hours and \(timeMinutes) minutes into \(zone.name) - {encouragement}",
            "Your body has been enjoying \(zone.name) benefits for \(timeHours)h \(timeMinutes)m. {encouragement}"
        ]
        
        let encouragements = [
            "Your cellular health is thanking you!",
            "Keep up this incredible journey!",
            "You're unlocking amazing metabolic benefits!",
            "Your future self will be grateful for this dedication!",
            "This commitment to wellness is inspiring!"
        ]
        
        let template = contextualTemplates.randomElement()!
        return template.replacingOccurrences(of: "{encouragement}", with: encouragements.randomElement()!)
    }
    
    private func getTemplates(for messageType: MessageType) -> [String] {
        switch messageType {
        case .motivational:
            return motivationalTemplates
        case .educational:
            return educationalTemplates
        }
    }
    
    private func personalizeMessage(template: String, zone: FastingZone) -> String {
        var message = template.replacingOccurrences(of: "{zone}", with: zone.name)
        
        // Add zone-specific details
        let processes = getZoneProcesses(for: zone)
        let benefits = getZoneBenefits(for: zone)
        
        message = message.replacingOccurrences(of: "{process}", with: processes.randomElement() ?? "cellular optimization")
        message = message.replacingOccurrences(of: "{benefit}", with: benefits.randomElement() ?? "improved health")
        
        return message
    }
    
    private func getZoneProcesses(for zone: FastingZone) -> [String] {
        switch zone.name {
        case "Anabolic":
            return ["nutrient absorption", "protein synthesis", "muscle recovery"]
        case "Catabolic":
            return ["glycogen breakdown", "metabolic shifting", "hormone regulation"]
        case "Fat Burning":
            return ["fat oxidation", "ketone production", "metabolic flexibility"]
        case "Ketosis":
            return ["ketone utilization", "brain fuel optimization", "insulin sensitivity improvement"]
        case "Autophagy":
            return ["cellular cleanup", "damaged protein removal", "mitochondrial renewal"]
        case "Deep Autophagy":
            return ["deep cellular regeneration", "growth hormone release", "longevity activation"]
        default:
            return ["metabolic optimization"]
        }
    }
    
    private func getZoneBenefits(for zone: FastingZone) -> [String] {
        switch zone.name {
        case "Anabolic":
            return ["muscle maintenance", "energy replenishment", "recovery optimization"]
        case "Catabolic":
            return ["metabolic preparation", "fat burning readiness", "hormonal balance"]
        case "Fat Burning":
            return ["weight management", "metabolic health", "energy efficiency"]
        case "Ketosis":
            return ["mental clarity", "stable energy", "metabolic flexibility"]
        case "Autophagy":
            return ["cellular health", "inflammation reduction", "longevity support"]
        case "Deep Autophagy":
            return ["maximum renewal", "anti-aging benefits", "cellular optimization"]
        default:
            return ["overall wellness"]
        }
    }
}

enum MessageType {
    case motivational
    case educational
}