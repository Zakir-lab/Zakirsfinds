# PyGPT cloud desktop for an Android tablet

This branch runs the **original PyGPT 2.8.30 Linux app** in a GitHub Codespace. A private browser port streams the Linux desktop through noVNC to an Android tablet. It is not a rewritten web version of PyGPT.

## Start

1. In this branch, select **Code → Codespaces → Create codespace on pygpt-cloud-desktop**. Use the 2-core machine; it has 8 GB RAM.
2. Let the setup finish. It downloads the official 798 MB AppImage, verifies its published SHA-256, and unpacks it. This can take several minutes.
3. Open the **PyGPT desktop** notification or port **6080** in the Codespace's **Ports** tab. The port should remain **Private**.
4. Sign in to a model provider within PyGPT if you want cloud AI responses. The app itself does not include API credits.

The tablet connects only while the Codespace is running. Its free monthly compute and storage allowance is limited. Closing the browser does not necessarily stop compute immediately; stop the Codespace when done. Settings and chats remain in that Codespace until it is deleted. If the desktop is empty after a restart, run `bash .devcontainer/start-pygpt.sh` in the Codespace terminal and see `~/.local/share/pygpt-cloud/logs/` for errors.

The Codespace setup lives on a separate branch. Nothing is merged into `main`.
