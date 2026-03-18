# OpenRV Annotation Tool Architecture Notes

## Pipeline Modifications

To fix the issue where the color picker was double-applying OCIO transforms (sampling display color but painting in linear space), we re-architected where the paint strokes are rendered.

1. **Top-of-Stack Paint Node**:
   - Added `m_paintNode` (`PaintIPNode`) as the root of `DisplayGroupIPNode`.
   - This moves paint rendering *after* the `OCIODisplay` and `RVDisplayColor` nodes.
   - Tagged the new node with `tag.annotate=true` so the Mu UI can identify it as a valid paint target.
   - **Crucial Fix**: The output of the display paint node must be wrapped in an `IPImage::IntermediateBuffer` (in `DisplayGroupIPNode::evaluate`). Without this, `ImageRenderer::renderPaint` tries to render directly to the final screen FBO, which fails and results in invisible strokes.
   - **Persistence**: Enabled `defaults.persistent=1` on the display paint node to ensure annotations are saved to the session file.

2. **Recursive Paint Rendering**:
   - Modified `ImageRenderer::renderCurrentImage` to use a new `renderPaintRecursive` function.
   - Because the paint node is now inside the `DisplayGroup` (a child in the `IPImage` tree) rather than at the absolute root, the renderer must recursively traverse the `IPImage` tree to find and execute paint commands.
   - **Optimization**: Added a `hasPaintRecursive` flag to `IPImage` that is propagated during graph evaluation. The renderer uses this flag to prune sub-trees that do not contain paint, minimizing the performance overhead of recursion.

3. **High Bit Depth Sampling**:
   - `nodePixelValue` (C++) and `framebufferPixelValue` (Mu) were upgraded to use `GL_FLOAT` with `glReadPixels`.
   - Added checks for `GLContextNotSet()` and valid viewport sizes to prevent segmentation faults.

3. **Export Integration**:
   - **Copy Logic**: Modified `src/lib/app/mu_rvui/export_utils.mu` to copy `RVPaint` node profiles from the active `DisplayGroup` to the `defaultOutputGroup` during export.
   - **RVIO Force View**: Updated `rvio` command arguments in export functions to include `-view defaultOutputGroup`. This ensures that the background rendering process evaluates the correct node hierarchy containing the display-level annotations.
   - **Annotated Frame Marking**: Updated `findAnnotatedFrames` in `extra_commands.mu` to search from the `rootNode()`, ensuring that frames with display-level paint are correctly identified for export.

## UI & Mu Script Changes

1. **Source vs Display Color**:
   - Replaced "Working Space Color" with "Source Color".
   - **Display Color** (`framebufferPixelValue`): Samples what the user sees (post-OCIO). Since the paint node is now post-OCIO, painting this back is visually accurate.
   - **Source Color** (`sourcePixelValue`): Bypasses the GPU pipeline entirely to sample raw data from the image buffer, identical to the "Pixel Inspector" tool.
2. **UI Enhancements**:
   - RGB values are displayed vertically.
   - The `_precisionLabel` uses `Qt.TextSelectableByMouse` so users can copy the high-precision float values.
   - Added a context menu to both the dropper tool and the precision label for "Manual Color Entry".
3. **Graph Search & Selection**:
   - Implemented `rootNode()` Mu command to allow top-down searches for `RVPaint` nodes.
   - **Multi-View Heuristic**: Updated `annotate_mode.mu` to prioritize the paint node belonging to the current `viewNode()` group. This ensures that in multi-monitor or split-view setups, the tool draws to the correct display layer.

## Future Considerations

- **Coordination Mapping**: Continue to monitor `eventToImageSpace` accuracy during extreme zoom/pan on the display group.
- **Baking Strokes**: Users may eventually want a "Bake to Source" feature to move display-level annotations down to the source nodes for permanent metadata storage.
