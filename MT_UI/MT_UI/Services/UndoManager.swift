//
//  UndoManager.swift
//  MT_UI
//
//  Created by Hadi El-Seyed on 14/03/2026.
//

import Foundation

// Handles undo/redo registration for metadata save operations.
// Keeps undo logic out of the view layer.

// TODO: Define a class MetadataUndoService with a static or shared instance.

// TODO: Add a method registerSave(before: MusicFile, after: MusicFile, undoManager: UndoManager?)
// This method should:
//   1. Register an undo action that calls APIClient.writeMetadata with `before`
//   2. Inside the undo action, call registerSave(before: after, after: before, ...) to register redo
//   3. Call undoManager?.setActionName("Edit Metadata") to label the Undo menu item
