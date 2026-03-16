//
//  UndoManager.swift
//  MT_UI
//
//  Created by Hadi El-Seyed on 14/03/2026.
//

import Foundation

// Handles undo/redo registration for metadata save operations.
// Keeps undo logic out of the view layer.

class MetadataUndoService {
    static let shared = MetadataUndoService()
    
    private init(){
        
    }

    // Registers an undo/redo pair for a metadata save.
    @MainActor
    func registerSave(before: MusicFile, after: MusicFile, onComplete: @escaping @MainActor (MusicFile) -> Void, undoManager: UndoManager?) {

        // Labels the undo menu item so it shows "Undo Edit Metadata" in the Edit menu.
        undoManager?.setActionName("Edit Metadata")

        // Registers the undo action. Uses `self` as the target so UndoManager holds a weak reference.
        // The closure runs when the user triggers Cmd+Z.
        // Inside: writes the `before` state back to disk, then registers the inverse as redo (Cmd+Shift+Z).
        undoManager?.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                do {
                    try await APIClient.shared.writeMetadata(file: before)
                    onComplete(before)
                } catch {}
            }
            // Registers redo by swapping before/after. UndoManager handles Cmd+Shift+Z automatically.
            target.registerSave(before: after, after: before, onComplete: onComplete,undoManager: undoManager)
        }
        
    }
}
