//
//  BCAICanvasStateModel.swift
//  CanvasApp
//
//  Created by dey18 on 1/12/26.
//


import Foundation
import UIKit
import CoreFoundation


class BACAIPlistManager{
    static let shared:BACAIPlistManager = BACAIPlistManager()
    
    private init() {
        
    }
    
    func loadStructFromPlist<T: Codable>(fileName: String, fileExtension: String = "plist") throws -> T {
        guard let plistPath = Bundle.main.path(forResource: fileName, ofType: fileExtension) else {
            fatalError("Unable to find plist file.")
        }
        
        guard let plistData = FileManager.default.contents(atPath: plistPath) else {
            fatalError("Unable to read plist data.")
        }
        
        let decoder = PropertyListDecoder()
        do {
            let myStruct = try decoder.decode(T.self, from: plistData)
            return myStruct
        } catch {
            throw error
        }
    }
    
}

struct BCAICanvasStateModel{
    
    var filterShift: CGPoint?
    var currentRatioW: CGFloat?
    var currentRatioH: CGFloat?
    var filterTransfromScale: CGFloat
    var isDiffrent = false
    var isOrginal = true
    var lastSelectedIndex: Int
    var selectedCanvas: Int?
    
    init(filterShift: CGPoint? = nil,
         currentRatioW: CGFloat? = nil,
         currentRatioH: CGFloat? = nil,
         filterTransfromScale: CGFloat,
         isDiffrent: Bool = false,
         isOrginal: Bool = true,
         lastSelectedIndex: Int,
         selectedCanvas: Int? = nil) {
        
        self.filterShift = filterShift
        self.currentRatioW = currentRatioW
        self.currentRatioH = currentRatioH
        self.filterTransfromScale = filterTransfromScale
        self.isDiffrent = isDiffrent
        self.isOrginal = isOrginal
        self.lastSelectedIndex = lastSelectedIndex
        self.selectedCanvas = selectedCanvas
    }
    
    
    init() {
        isDiffrent = false
        isOrginal = true
        lastSelectedIndex = 0
        filterTransfromScale = 1.0
    }
}
