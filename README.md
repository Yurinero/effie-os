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
* **Traditional App Launcher GUI:** Bound to `SUPER + A` for quick, visual point-and-click searching for users with a more traditional Windows/MacOS preference.

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
