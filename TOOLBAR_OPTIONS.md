# 🎨 DNT Watcher - Toolbar App Options

DNT Watcher provides **TWO different toolbar implementations** with different strengths. Choose based on your needs!

---

## 📊 Quick Comparison

| Feature | rumps (Enhanced) | PyQt6 |
|---------|-----------------|-------|
| **Platform** | macOS only | Cross-platform |
| **Visual Polish** | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Ease of Setup** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Dependencies** | Small (rumps) | Medium (PyQt6) |
| **Customization** | Limited | Extensive |
| **Installation Size** | ~5MB | ~50MB |
| **Best For** | Quick & Simple | Cross-platform |

---

## 1️⃣ Enhanced rumps (Recommended for Most Users)

### ✨ Features
- **Colored & styled menu items** using NSAttributedString
- Different fonts and font sizes
- Bold text for important info
- Color-coded status (green=good, red=bad, yellow=warning)
- Smallest footprint

### 🎨 What It Looks Like
```
Menu Bar: 🏔✅

When clicked:
━━━━━━━━━━━━━━━
✅ Full Weekends: 2 AVAILABLE!  (green, bold)
📅 Total Dates: 64  (yellow)
🕐 Last Check: 17:23 (5m ago)  (gray, small font)
━━━━━━━━━━━━━━━
🔄 Rerun Check Now
❌ Quit
```

### 📦 Installation
```bash
# Already included!
./setup_toolbar.sh
uv run dnt-toolbar
```

### ✅ Pros
- Lightweight and fast
- Native macOS look and feel
- Easy to set up
- Sufficient for most needs

### ❌ Cons
- macOS only
- Limited layout options
- Can't embed custom widgets

### 🎯 Best For
- Most users who want a polished toolbar app
- When you want native macOS appearance
- Minimal dependencies

---

## 2️⃣ PyQt6 (Cross-Platform Power)

### ✨ Features
- **Rich HTML formatting** in menu items
- Cross-platform (macOS, Windows, Linux)
- Modern Qt framework
- Extensive customization options
- Future-proof (actively maintained)

### 🎨 What It Looks Like
```
Menu Bar: System Tray Icon

When clicked:
╔══════════════════════════════╗
║  🏔 DNT WATCHER              ║
╠══════════════════════════════╣
║ ✅ Full Weekends: 2 AVAILABLE! ║
║ 📅 Total Dates: 64            ║
╠══════════════════════════════╣
║ 🕐 Last Check: 17:23 (5m ago)  ║
╠══════════════════════════════╣
║ 🔄 Rerun Check Now            ║
╠══════════════════════════════╣
║ ❌ Quit                        ║
╚══════════════════════════════╝
```

### 📦 Installation
```bash
# Add PyQt6 to workspace
uv sync --all-packages

# Run
uv run dnt-toolbar-qt
```

### ✅ Pros
- Works on Windows, Mac, and Linux
- Modern, actively developed framework
- Rich text with HTML formatting
- Professional appearance
- Extensive Qt widget library available

### ❌ Cons
- Larger dependency (~50MB)
- Slightly more complex setup
- Not quite as "native" feeling on macOS

### 🎯 Best For
- Cross-platform deployments
- When you need Windows/Linux support
- Building more complex future features
- Teams familiar with Qt

---

## 🤔 Which Should You Choose?

### Use **Enhanced rumps** if:
- ✅ You're on macOS
- ✅ You want something simple and lightweight
- ✅ You value native macOS look/feel
- ✅ Colored text is enough customization

### Use **PyQt6** if:
- ✅ You need cross-platform support
- ✅ You want a modern, maintained framework
- ✅ You're familiar with Qt
- ✅ You might build more complex features later

---

## 🚀 Try Them Both!

You can install both and try each one:

```bash
# Sync all packages
uv sync --all-packages

# Try rumps (enhanced)
uv run dnt-toolbar

# Try PyQt6
uv run dnt-toolbar-qt
```

**They both use the same core logic**, so switching between them is easy!

---

## 🔧 Technical Details

### Architecture
Both apps use:
- `dnt-core` for business logic
- `dnt-notification` for system notifications
- Same configuration file (`dnt_hytter.yaml`)
- Same history storage (`history/` folder)

Only the **UI layer** is different!

### File Sizes (Approximate)
- rumps: 5MB total
- PyQt6: 50MB total (Qt framework)

### Performance
Both have similar performance - the bottleneck is the API calls, not the UI.

---

## 📝 Future Enhancements

### Potential Additions
With these two options, you could add:

**For rumps:**
- More menu items with submenus
- Keyboard shortcuts

**For PyQt6:**
- Charts showing availability over time
- Settings dialog
- Detailed cabin information
- Custom visualizations

---

## 🎓 Learning Resources

### rumps
- [GitHub](https://github.com/jaredks/rumps)
- [Documentation](https://rumps.readthedocs.io/)

### PyQt6
- [Official Docs](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
- [Python GUIs Tutorial](https://www.pythonguis.com/pyqt6-tutorial/)

---

**Choose your style and enjoy beautiful cabin availability monitoring!** 🏔✨
