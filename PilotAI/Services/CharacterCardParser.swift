import Foundation
import UIKit

public struct CharacterCardParser {
    public static func parseCharacter(from url: URL) -> Character? {
        if url.pathExtension.lowercased() == "json" {
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            return extractCharacter(from: json)
        } else if url.pathExtension.lowercased() == "png" {
            guard let data = try? Data(contentsOf: url) else { return nil }
            // Try extracting tEXt / iTXt chunk containing "chara" or "ccv3"
            if let str = String(data: data, encoding: .isoLatin1),
               let range = str.range(of: "\"name\"") {
                let jsonSubstring = str[range.lowerBound...]
                if let endRange = jsonSubstring.range(of: "}") {
                    let validJsonStr = String(jsonSubstring[...endRange.lowerBound])
                    if let jsonData = validJsonStr.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        return extractCharacter(from: json)
                    }
                }
            }
        }
        return nil
    }
    
    private static func extractCharacter(from json: [String: Any]) -> Character {
        let dataDict = (json["data"] as? [String: Any]) ?? json
        let name = (dataDict["name"] as? String) ?? "Imported Character"
        let description = (dataDict["description"] as? String) ?? (dataDict["personality"] as? String) ?? ""
        let greeting = (dataDict["first_mes"] as? String) ?? (dataDict["greeting"] as? String) ?? ""
        let persona = (dataDict["personality"] as? String) ?? (dataDict["scenario"] as? String) ?? ""
        let prompt = (dataDict["system_prompt"] as? String) ?? (dataDict["mes_example"] as? String) ?? ""
        
        return Character(
            id: UUID().uuidString,
            name: name,
            avatarEmoji: "🎭",
            description: description,
            greeting: greeting,
            persona: persona,
            systemPrompt: prompt,
            isBuiltin: false
        )
    }
}
