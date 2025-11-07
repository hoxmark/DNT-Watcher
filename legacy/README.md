# Legacy Files (Deprecated)

This directory contains the original single-file architecture from before the UV Workspace refactoring.

## ⚠️ These Files Are Deprecated

**Do not use these files.** They are kept for historical reference only.

The project has been refactored to use a modern UV Workspace architecture with proper package separation:
- `run.py` → `packages/cli/src/dnt_cli/run.py`
- `helper.py` → `packages/core/src/dnt_core/` (split into `api.py`, `analysis.py`)
- `config.py` → `packages/core/src/dnt_core/config.py`
- `notify.py` → `packages/notification/src/dnt_notification/notify.py`
- `test_helper.py` → `tests/test_core.py`

## Using the New Architecture

Instead of running the old files, use:

```bash
# Install dependencies (only needed once)
uv sync

# Run the CLI
uv run dnt-watcher

# Launch the toolbar app
uv run dnt-toolbar

# Run tests
uv run python -m unittest tests/test_core.py -v
```

See the main [README.md](../README.md) for full documentation.

## Why Keep These Files?

These files are preserved for:
1. **Reference**: Understanding the evolution of the codebase
2. **Recovery**: In case any edge case logic was missed in the migration
3. **Learning**: Seeing how single-file code was refactored into packages

## Removal

These files can be safely deleted in a future release once the new architecture is proven stable in production.
