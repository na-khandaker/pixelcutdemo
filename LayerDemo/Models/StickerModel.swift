// MARK: - Models
import UIKit

struct StickerModel {
    let id: String
    var type: StickerType
    var layer: CALayer?
    var position: CGPoint
    var size: CGSize
    var rotation: CGFloat = 0
    var scale: CGFloat = 1.0
    var color: UIColor?
    var image: UIImage?
    var zIndex: Int = 0
    var isSelected: Bool = false
    
    // For lines
    var isHorizontal: Bool? = nil
    var initialEdge: Edge? = nil
    
    init(id: String = UUID().uuidString,
         type: StickerType,
         position: CGPoint,
         size: CGSize,
         color: UIColor? = nil,
         image: UIImage? = nil,
         zIndex: Int = 0,
         isHorizontal: Bool? = nil,
         initialEdge: Edge? = nil) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        self.color = color
        self.image = image
        self.zIndex = zIndex
        self.isHorizontal = isHorizontal
        self.initialEdge = initialEdge
    }
}

enum StickerType {
    case line
    case image
    case shape
}

enum Edge {
    case top
    case bottom
    case left
    case right
}

enum AnimationType: String, CaseIterable, Decodable {
    case RevealUp = "RevealUp"
    case RevealDown = "RevealDown"
    case RevealLeft = "RevealLeft"
    case RevealRight = "RevealRight"
    case DriftUp = "DriftUp"
    case DriftDown = "DriftDown"
    case DriftLeft = "DriftLeft"
    case DriftRight = "DriftRight"
    case None = "None"
    case Fade = "Fade"
    case Scale = "Scale"
}

// MARK: - Protocol for Sticker Factory
protocol StickerFactoryProtocol {
    func createSticker(type: StickerType,
                       configuration: StickerConfiguration) -> StickerModel
}

struct StickerConfiguration {
    var position: CGPoint
    var size: CGSize
    var color: UIColor?
    var image: UIImage?
    var edge: Edge?
    var zIndex: Int = 0
    var isSelectable: Bool = true
}

// MARK: - Sticker Factory
class StickerFactory: StickerFactoryProtocol {
    static let shared = StickerFactory()
    
    private init() {}
    
    func createSticker(type: StickerType,
                       configuration: StickerConfiguration) -> StickerModel {
        switch type {
        case .line:
            return createLineSticker(configuration: configuration)
        case .image:
            return createImageSticker(configuration: configuration)
        case .shape:
            return createShapeSticker(configuration: configuration)
        }
    }
    
    private func createLineSticker(configuration: StickerConfiguration) -> StickerModel {
        let isHorizontal = configuration.size.height < configuration.size.width
        let initialEdge: Edge? = configuration.edge
        
        return StickerModel(
            type: .line,
            position: configuration.position,
            size: configuration.size,
            color: configuration.color ?? getColorForEdge(configuration.edge),
            zIndex: configuration.zIndex,
            isHorizontal: isHorizontal,
            initialEdge: initialEdge
        )
    }
    
    private func createImageSticker(configuration: StickerConfiguration) -> StickerModel {
        return StickerModel(
            type: .image,
            position: configuration.position,
            size: configuration.size,
            image: configuration.image,
            zIndex: configuration.zIndex
        )
    }
    
    private func createShapeSticker(configuration: StickerConfiguration) -> StickerModel {
        return StickerModel(
            type: .shape,
            position: configuration.position,
            size: configuration.size,
            color: configuration.color ?? .systemPurple,
            zIndex: configuration.zIndex
        )
    }
    
    private func getColorForEdge(_ edge: Edge?) -> UIColor {
        guard let edge = edge else { return .systemGray }
        
        switch edge {
        case .top: return .systemBlue
        case .bottom: return .systemRed
        case .left: return .systemGreen
        case .right: return .systemOrange
        }
    }
}
