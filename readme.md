# ⚡ Full Desktop Note Automation

> A lightweight, keyboard-driven Linux workflow designed to capture, structure, and retain knowledge effortlessly while coding, studying, or watching lectures.

---

## 🌟 Why Use This?

Taking notes while studying or debugging usually breaks your focus. Switching back and forth between your IDE, browser, screenshot software, and note editor takes time and context-switching energy. 

This project automates the manual labor of documentation so you can stay in **flow state**.

* **Zero Friction:** Capture screenshots directly into Markdown files with single keyboard shortcuts.
* **Organized by Design:** Auto-arranges your work into structured directories (*Sketch*, *Lecs*, *Notes*).
* **Built-in Retention:** Integrated Spaced Repetition script to review your notes effortlessly.
* **Native Linux Power:** Lightweight, fast, and uses standard Linux tools without bloated dependencies.

---

## 🛠️ Key Features & Architecture

### 1. Instant Visual Capture
* **Window Capture:** Press a shortcut to automatically capture the active window and append it straight into your Markdown file.
* **Area Selection:** Select any section of your screen to grab snippets, diagrams, or code blocks instantly.
* **Auto-Focus:** Keep your editor running in the background and toggle visual access without losing focus on your main task.

### 2. Smart Spaced Repetition Engine
Includes a built-in shell utility (`mspaced-repetition`) that:
* Randomly samples your notes based on interval brackets (Last 7 Days, ~1 Month Ago, ~3 Months Ago).
* Caps reviews to small, manageable batches to prevent study burnout.
* Integrates native desktop notifications (`notify-send`) with randomized mindset reminders to keep reviews fast and concept-focused.

### 3. File & Metadata Organization
* Automatically organizes notes chronologically and structurally.
* Enables easy command-line searching using standard UNIX utilities.
* Fully compatible with standard Markdown renderers and PDF export tools (e.g., VS Code extensions, Pandoc).

---

## 🎹 Custom Keyboard Shortcuts

Designed to work like native window management shortcuts (similar to `Alt+Tab`):

| Shortcut      | Action                                                                                    |
| :------------ | :---------------------------------------------------------------------------------------- |
| **`Alt + 1`** | Takes a screenshot of the active window and appends it to your current Markdown document. |
| **`Alt + 2`** | Prompts for a selected region screenshot and appends it to your Markdown document.        |
| **`Alt + 3`** | Toggles/opens your primary active Markdown note file.                                     |

---

## 💻 Tech Stack & Linux Magic

This tool highlights the flexibility of native Linux environment scripting:

* **Shell Scripting (`bash`):** Core logic leveraging standard utilities (`find`, `grep`, `mtime`, `sort`, `shuf`).
* **Display & Window Automation:** Uses `xdotool` and native desktop screenshot utilities to mimic human input and capture active windows.
* **Environment:** Works seamlessly with **VS Code** (or any preferred text editor/IDE).
* **Notifications:** Uses `notify-send` for non-intrusive desktop reminders.

---

## 🧪 Battle-Tested

This workflow has been continuously used in daily software engineering and study environments since **June 2026**, successfully managing technical documentation, lecture notes, C/C++ sketches, and Linux system notes.

---

## 🖥️ Platform Support

* **Linux:** Fully supported natively (Ubuntu, Debian, Fedora, Arch, etc.).
* **Windows:** Compatible via WSL (Windows Subsystem for Linux) with display server mapping or Cygwin environments.

---
