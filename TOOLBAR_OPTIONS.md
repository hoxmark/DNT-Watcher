# 🎨 DNT Watcher - Toolbar App Options

DNT Watcher provides **THREE different toolbar implementations** with increasing levels of sophistication and visual polish. Choose based on your needs!

---

## 📊 Quick Comparison

| Feature | rumps (Enhanced) | PyQt6 | NSPopover (Native) |
|---------|-----------------|-------|-------------------|
| **Platform** | macOS only | Cross-platform | macOS only |
| **Visual Polish** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Ease of Setup** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Dependencies** | Small (rumps) | Medium (PyQt6) | Small (PyObjC) |
| **Customization** | Limited | Extensive | Unlimited |
| **Installation Size** | ~5MB | ~50MB | ~10MB |
| **Best For** | Quick & Simple | Cross-platform | Maximum Beauty |

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

## 3️⃣ NSPopover Native (Ultimate macOS Experience)

### ✨ Features
- **Custom popup window** with any layout
- Native macOS NSPopover component
- Unlimited UI possibilities
- Beautiful animations
- Can add charts, graphs, forms, etc.

### 🎨 What It Looks Like
```
Menu Bar: 🏔

When clicked: Beautiful popup window appears!

┌──────────────────────────────────┐
│      🏔 DNT WATCHER              │
│                                  │
│  ✅ Full Weekends:               │
│     2 AVAILABLE!                 │
│     (green, large, bold)         │
│                                  │
│  🎉 Total Dates: 64              │
│     (yellow, medium)             │
│                                  │
│  🕐 Last Check: 17:23 (5m ago)   │
│     (gray, small)                │
│  ────────────────────────────    │
│                                  │
│  ┌──────────────────────┐        │
│  │ 🔄 Rerun Check Now   │        │
│  └──────────────────────┘        │
│                                  │
│  ┌──────────────────────┐        │
│  │ ❌ Quit              │        │
│  └──────────────────────┘        │
└──────────────────────────────────┘
```

### 📦 Installation
```bash
# Add PyObjC to workspace
uv sync --all-packages

# Run
uv run dnt-toolbar-native
```

### ✅ Pros
- **Most beautiful option**
- Completely custom layout
- Native macOS animations
- Can add ANY UI elements (charts, images, forms, etc.)
- Feels like a native macOS app
- Medium size (~10MB)

### ❌ Cons
- macOS only
- More complex code
- Requires PyObjC knowledge for customization
- Takes more development time for features

### 🎯 Best For
- Maximum visual appeal
- When you want the "wow factor"
- Portfolio/showcase projects
- When you plan to add rich visualizations
- macOS-only deployment

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

### Use **NSPopover Native** if:
- ✅ You're macOS-only
- ✅ You want the most beautiful interface
- ✅ You might add charts/graphs later
- ✅ You want your app to stand out
- ✅ You're comfortable with PyObjC

---

## 🚀 Try Them All!

You can install all three and try each one:

```bash
# Sync all packages
uv sync --all-packages

# Try rumps (enhanced)
uv run dnt-toolbar

# Try PyQt6
uv run dnt-toolbar-qt

# Try NSPopover (native)
uv run dnt-toolbar-native
```

**They all use the same core logic**, so switching between them is easy!

---

## 🔧 Technical Details

### Architecture
All three apps use:
- `dnt-core` for business logic
- `dnt-notification` for system notifications
- Same configuration file (`dnt_hytter.yaml`)
- Same history storage (`history/` folder)

Only the **UI layer** is different!

### File Sizes (Approximate)
- rumps: 5MB total
- PyQt6: 50MB total (Qt framework)
- NSPopover: 10MB total

### Performance
All three have similar performance - the bottleneck is the API calls, not the UI.

---

## 📝 Future Enhancements

### Potential Additions
With these three options, you could add:

**For rumps:**
- More menu items with submenus
- Keyboard shortcuts

**For PyQt6:**
- Charts showing availability over time
- Settings dialog
- Detailed cabin information

**For NSPopover:**
- Interactive calendar view
- Graphs and visualizations
- Animation effects
- Embedded web view

---

## 🎓 Learning Resources

### rumps
- [GitHub](https://github.com/jaredks/rumps)
- [Documentation](https://rumps.readthedocs.io/)

### PyQt6
- [Official Docs](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
- [Python GUIs Tutorial](https://www.pythonguis.com/pyqt6-tutorial/)

### NSPopover / PyObjC
- [PyObjC Docs](https://pyobjc.readthedocs.io/)
- [Apple NSPopover Docs](https://developer.apple.com/documentation/appkit/nspopover)

---

**Choose your style and enjoy beautiful cabin availability monitoring!** 🏔✨
