# API Docs Downloader, Merger & Builder

This script automates the process of downloading OpenAPI specifications from multiple groups, converting them to YAML, merging them (if multiple groups are selected), and generating a single HTML documentation file using [Redocly CLI](https://redocly.com/cli/).

---

## ✨ Features

- ✅ Interactive group selection (multi-select supported)
- ✅ Automatic JSON → YAML conversion
- ✅ Robust pairwise YAML merge (compatible with `yq` v4.x)
- ✅ Automatic cleanup of temporary files (keeps only the final HTML)
- ✅ Cross-platform support (macOS, Linux, Windows)

---

## ⚙️ Requirements

- **yq v4+** ([install guide](https://github.com/mikefarah/yq))
- **curl**
- **Node.js & npm** (for `npx @redocly/cli`)
- Access to your local API server (`http://localhost:8082/v3/api-docs/...`)

Check your `yq` version:

```sh
yq --version
```

---

## 🚀 How to Run

1. **Make the script executable** (if needed):

   ```sh
   chmod +x ./local-generate-docs.sh
   ```

2. **Run the script:**

   ```sh
   ./local-generate-docs.sh
   ```

3. **Follow the interactive prompts:**

   ```
   0. 0-Auth
   1. 01-Admin
   2. 02-Manager
   ...
   Enter numbers separated by space [0]: 0 9
   ```

4. **Sample output:**

   ```
   📥 Downloading API JSON from http://localhost:8082/v3/api-docs/0-Auth ...
   🔄 Converting JSON → YAML ...
   📥 Downloading API JSON from http://localhost:8082/v3/api-docs/09-Supplier-OpenApi ...
   🔄 Converting JSON → YAML ...
   🔗 Merging 2 YAML files into Auth-Supplier-OpenApi.merged.yaml ...
   📚 Building documentation with Redocly ...
   ✅ Done! Output file: Auth-Supplier-OpenApi.html
   ```

---

## 📄 License by Thanh
