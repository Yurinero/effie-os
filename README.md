# Effie OS

An experimental, opinionated fork of [Omarchy](https://github.com/basecamp/omarchy) designed for daily use, customization, and exploring modern Linux desktop ergonomics.

---

### Acknowledgments & Upstream Credit
All core architecture, foundational work, and original copyrights belong to **Omacom**, **DHH**, and the **Omarchy Contributors**. Effie OS exists purely on top of their groundwork.

---

### Why?
To learn by breaking things, build an intuitive setup for daily workflows, and have genuine fun tailoring an Arch-based system.

---

### What's in the Name?
**Effie** is a feminine Greek name drawn from a memorable personal inspiration, which happened to share an amusing phonetic resemblance to **UEFI**.

---

### Key Additions & Changes
* **Superfile Integration:** Bundled as an optional, feature-packed TUI file manager alongside the default CLI toolchain.
* **Lazy Installer for IDEs & Toolboxes:** Added on-demand lazy installer for JetBrains Toolbox under **Install > Editor** and **Install > Development**.
* **Text Editors:** Added Kate as another on-demand lazy installed Text editor option.
* **Traditional App Launcher GUI:** Bound to `SUPER + A` for quick, visual point-and-click searching for users with a more traditional Windows/MacOS preference.
* **Workspace & Virtual Desktop Switcher:** Bound to `ALT + SPACE` and `SUPER + TAB` for macOS/Windows-style floating workspace cycling with live application icon previews.

---

### Planned Additions & Changes
* **Alternative Application Match:** Integrate lazy-load options for Linux alternatives to popular macOS/Windows applications, for users transitioning from other systems. "Photoshop" may resolve to PhotoGIMP, "Premiere" to DaVinci Resolve, "Illustrator" to Inkscape, etc. This will be done through a plugin that can be enabled and disabled at will.
* **Effie Colour Scheme and Branding:** Add two themes in Light and Dark flavours as the preferred/default for the system, inspired by the Greek origin of the name.
* **Effie Splash Screen:** Add a custom splash screen for the login screen and the application launcher.
* **Effie AI:** A small local model to answer questions about the system and guide new users through common Linux pitfalls.

---

### AI Collaboration & Transparency
Developed openly in collaboration with **Antigravity** (Google DeepMind) for architectural exploration, prototyping, and shell automation.

## Development & Testing

Effie OS includes a built-in packaging pipeline and QEMU virtual machine test harness:

- **Packaging & ISO Build Guide**: [`docs/packaging-and-qemu.md`](docs/packaging-and-qemu.md)
- **Developer CLI**: [`scripts/effie-dev`](scripts/effie-dev)

```bash
# Build local packages into repository:
./scripts/effie-dev pkg

# Build complete bootable live ISO:
./scripts/effie-dev iso

# Boot ISO under QEMU with KVM acceleration & UEFI:
./scripts/effie-dev qemu
```

## Acknowledgments

- Developed in collaboration with **Antigravity** (Google DeepMind).
- Built upon the **Omarchy** desktop architecture and **Arch Linux** ecosystem.

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).
