# How to Boil: Lessons Learned from Tinygrad Dependency Discovery

## Overview
This document captures lessons learned from enhancing the "boil" system - a tool that discovers minimal dependencies for Python projects by starting with a stripped-down codebase and incrementally restoring only the necessary files through automated error detection and resolution.

## The Boil Process
1. Start with a heavily stripped-down codebase (most files deleted)
2. Run target script (e.g., `beautiful_mnist.py`)
3. Detect import/runtime errors
4. Automatically restore missing files/components
5. Repeat until script runs successfully
6. Result: Minimal dependency set discovered

## Key Error Patterns and Handlers Implemented

### 1. Forward Reference NameErrors (`handle_future_annotations`)
**Problem**: Classes used in type annotations before they're defined
```python
class DTypeMetaClass(type):
    dcache: dict[tuple, DType] = {}  # DType not yet defined
```
**Detection**: NameError with type annotation patterns like `dict[..., ClassName]`
**Solution**: Add `from __future__ import annotations` import
**Lesson**: Need multiple regex patterns to catch various type annotation formats

### 2. Indentation Errors (`handle_indentation_error`) 
**Problem**: Broken code structure from partial file restoration
- Missing TYPE_CHECKING blocks
- Orphaned method definitions
- "unexpected indent" vs "expected indented block"
**Solution**: 
- Detect TYPE_CHECKING issues → full file restoration
- Unexpected indent → immediate full file restoration
- Expected indent → attempt targeted repair, fallback to full restoration
**Lesson**: Partial repairs often leave files in broken states; be aggressive about full restoration

### 3. Circular Import Errors (`handle_circular_import_error`)
**Problem**: "partially initialized module" errors during import
```
ImportError: cannot import name 'optim' from partially initialized module 'tinygrad.nn'
```
**Solution**: Restore missing submodule files (e.g., `tinygrad/nn/optim.py`)
**Lesson**: Circular imports often mean missing submodule files, not missing code in main module

### 4. Path Handling with Spaces
**Problem**: macOS paths like `/Users/mattMacBook Pro/tinygrad/` contain spaces
**Original Issue**: Overly restrictive space checks were rejecting valid paths
**Solution**: 
- Remove blanket space restrictions
- Only reject paths that look like shell command arguments
- Handle paths with spaces in git operations
**Lesson**: Don't make assumptions about path formats across different systems

### 5. FileNotFoundError Parsing (`handle_file_not_found`)
**Problem**: Complex error messages with errno formatting
```
FileNotFoundError: [Errno 2] No such file or directory: '/path/to/file'
```
**Solution**: Enhanced regex to extract actual file paths from errno-wrapped messages
**Lesson**: Error message parsing needs to handle system-specific formatting

### 6. Directory Restoration
**Problem**: Missing entire directories (e.g., `tinygrad/runtime/`)
**Solution**: 
- Search for all files within the directory pattern
- Restore files individually rather than trying to restore directory directly
- Use both exact and broader pattern matching
**Lesson**: Git works with files, not directories - restore directory contents individually

## Handler Priority Order (Critical!)
```python
HANDLERS = [
    handle_mypy_errors,           # Static analysis errors first
    handle_indentation_error,     # Structural issues
    handle_future_annotations,    # Type annotation issues  
    handle_name_error,           # Basic name resolution
    handle_module_attribute_error,
    handle_object_attribute_error,
    handle_circular_import_error, # Before generic import handlers!
    handle_import_error2,
    # ... other import handlers
]
```
**Lesson**: Order matters! More specific handlers must come before generic ones.

## Key Implementation Insights

### 1. Pattern Matching Evolution
Started with overly specific patterns, evolved to broader detection:
```python
# Too specific - only caught weakref patterns
if not re.search(rf"\[{re.escape(name)}\]", stderr):

# Better - catches multiple type annotation patterns  
type_annotation_patterns = [
    rf"\[.*,\s*{re.escape(name)}\]",  # dict[tuple, DType]
    rf"\[{re.escape(name)}\]",       # list[DType]
    rf"\[.*{re.escape(name)}.*\]",   # any bracket containing name
]
```

### 2. Repair Strategy: Incremental vs Full Restoration
- **Incremental**: Use `py_repair` to restore specific missing items
- **Full**: Use `git checkout HEAD -- file` to restore entire file
- **Lesson**: When structure is broken (indentation errors), go straight to full restoration

### 3. Error Detection Robustness
Each handler should:
- Use specific regex patterns for detection
- Have clear success/failure return values
- Log what it's attempting to do
- Handle edge cases gracefully
- Fall back to simpler approaches when complex ones fail

## Limitations Discovered

### 1. Semantic Understanding Gap
The boil system successfully resolves **syntactic dependencies** (imports, missing functions) but struggles with **semantic dependencies** (runtime behavior, device initialization, proper object construction).

**Example**: Successfully imported all device-related modules but didn't restore enough of the device initialization logic to properly detect available compute devices.

### 2. Runtime vs Import-time Dependencies
Two different dependency types:
- **Import-time**: What's needed for `import module` to succeed
- **Runtime**: What's needed for the code to actually execute correctly

Boil excels at import-time dependencies but may under-restore runtime logic.

### 3. Configuration and Environment Dependencies
Missing pieces often include:
- Environment variable handling
- Configuration initialization  
- Resource discovery (devices, backends)
- System-specific setup code

## Success Metrics
- **Before enhancements**: Experiment stalled around attempt 60-70
- **After enhancements**: Reached attempt 144+ 
- **Final state**: All imports resolved, reached actual execution phase
- **Key achievement**: Discovered minimal import dependency set for `beautiful_mnist.py`

## Future Improvements

### 1. Runtime Dependency Detection
Need handlers for:
- "no usable devices" → restore device backends
- Configuration missing → restore config files
- Resource initialization failures → restore setup code

### 2. Semantic Analysis
Consider integrating:
- Static analysis tools to understand call graphs
- Runtime tracing to capture actual execution dependencies
- Configuration dependency analysis

### 3. Validation Against Working Version
After boil completes, compare behavior against fully-restored version to ensure semantic equivalence, not just syntactic correctness.

## Key Takeaway
The boil system is excellent for discovering **import dependency graphs** but needs enhancement for **runtime behavior equivalence**. The goal isn't just "imports work" but "behaves identically to full version."

This session successfully enhanced boil's ability to navigate complex Python import scenarios, but highlighted the distinction between syntactic completeness and semantic correctness in dependency discovery.