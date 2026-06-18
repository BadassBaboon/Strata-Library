# 🌌 Strata-Library

> The shared content library for **[Strata](https://github.com/BadassBaboon/Strata)** — the hyper-lightweight Rust + `wgpu` live-wallpaper engine.

Strata's engine ships with **no** shaders, models, or presets baked in. Instead it fetches this library on first launch and re-syncs on demand. Keeping content here keeps the engine repo small and license-clean, and lets the community add wallpapers via pull request without ever touching engine code.

---

## 📂 Layout

```
Strata-Library/
├── index.toml                  # GENERATED manifest: schema/library version + per-item hashes
├── models.toml                 # Parallax-Studio depth/segment/upscale model registry
├── presets.toml                # Parallax-Studio quality presets
├── update-index.ps1            # regenerates index.toml (contributor tool — see below)
├── external/                   # shared texture & cubemap assets (referenced by file name)
│   └── <sha>.png / <sha>.jpg   # cubemaps add 5 sibling faces <sha>_1..<sha>_5
└── shader-library/             # every wallpaper folder lives here
    └── <wallpaper-slug>/        # one folder per wallpaper, fully self-contained
        ├── manifest.toml        # name, author, source_url, tags, passes, bindings
        ├── image.glsl           # the shader (+ bufferA.glsl…, common.glsl for multipass)
        └── thumbnail.png        # 480×270 preview (ships with the pack)
```

At runtime the engine fetches this tree verbatim into `%APPDATA%/strata/strata-library/` — *as if the repo were cloned there* — so a shader resolves to `…/strata-library/shader-library/<slug>/` and an asset to `…/strata-library/external/<file>`.

A wallpaper folder is **self-contained**: zip it and it's a complete, importable pack. Textures and cubemaps are *not* duplicated into each folder — they're referenced by file name and resolved from `external/`, so one copy serves every shader.

---

## 🧾 `index.toml`

`index.toml` is **generated, never hand-edited** (see [Updating the index](#-updating-the-index)).

```toml
schema_version = 1
library_version = "1.0.0"

[files.models]      # version bumps + hash refreshes when models.toml changes
version = "1.0.0"
sha256  = "…"
[files.presets]
version = "1.0.0"
sha256  = "…"

[[shader]]
slug       = "clearly-a-bug"
name       = "Clearly a Bug"
author     = "mrange"
source_url = "https://www.shadertoy.com/view/33cGDj"
tags       = ["Abstract", "Organic", "Animated"]
added_in   = "1.0.0"          # library version this shader first appeared in
updated    = "2026-06-18"     # last content change (ISO date)
sha256     = "…"              # hash of authored files (manifest + *.glsl)
```

| Field | Purpose |
| :--- | :--- |
| `library_version` | The whole library's version; the client compares it to its last sync. |
| `added_in` | Drives the **NEW** badge + newest/oldest sorting in the app. |
| `updated` | Human-readable "last touched" date. |
| `sha256` | Lets the client detect what actually changed and verify integrity, so it re-fetches only what's needed. |

---

## 🛠️ Updating the index

You never edit `index.toml` by hand. Two tools regenerate it, and they hash content **identically** so the result is consistent either way.

### `update-index.ps1` — the contributor tool

Pure PowerShell (built into Windows). **No Rust, no engine checkout, no GPU.** Run it from the repo root after adding or editing shader folders:

```powershell
.\update-index.ps1                 # contributor mode (default)
.\update-index.ps1 -Release        # maintainer: prompts for the new library_version
.\update-index.ps1 -Version 1.2.0  # maintainer: set the version non-interactively
.\update-index.ps1 -NoPause        # don't wait for a keypress (CI)
```

It scans every `shader-library/<slug>/manifest.toml`, content-hashes each shader (`manifest.toml` + `*.glsl`), and rewrites `index.toml`:

* **new** folders → added, `updated` = today;
* **changed** shaders → `updated` re-dated, `sha256` refreshed (`added_in` preserved);
* **removed** folders → dropped;
* `models.toml` / `presets.toml` → hashes refreshed.

It also warns about a missing `name` / `author` / `source_url` / `thumbnail.png`, but it does **not** render thumbnails — include your own, or let the app make one at runtime.

#### Versioning: contributors don't bump it 🔒

By default the script **never changes `library_version`.** New shaders are tagged `added_in = "unreleased"`. This lets the maintainer merge several contributor PRs first, then assign one version for the batch:

```powershell
.\update-index.ps1 -Release        # finalizes every "unreleased" entry to the chosen version
git tag library-v1.1.0 && git push origin library-v1.1.0
```

Only `-Release` (or `-Version`) bumps `library_version` and turns the pending `unreleased` shaders into the real version. If a PR's `index.toml` ever conflicts on merge, just re-run the script — it rebuilds the index from the folders on disk.

### Engine tool — for maintainers regenerating thumbnails too

To regenerate the index **and re-render every `thumbnail.png`** (needs a GPU), clone this repo inside a checkout of the main Strata repo and run:

```
cargo test -p core-engine --test assemble_library -- --ignored
```

---

## 📦 Distribution

Published via **jsDelivr**, served straight off this repo's Git tags (no release `.zip` needed):

```
https://cdn.jsdelivr.net/gh/BadassBaboon/Strata-Library@library-vx.x.x/index.toml
https://cdn.jsdelivr.net/gh/BadassBaboon/Strata-Library@library-vx.x.x/shader-library/<slug>/thumbnail.png
```

We always pin an explicit tag (`@library-v1.0.0`), **never `@latest`** — tagged content is cached immutably, so a given engine build always resolves a known-good snapshot. To publish we commit, `git tag library-v<version>`, push the tag.

---

## 🤝 Contributing a wallpaper

You only need to clone **this** repo and have PowerShell.

1. **Clone** `Strata-Library`.
2. **Add your shader** as `shader-library/<your-slug>/` with `manifest.toml` + `image.glsl` (plus `bufferA.glsl…` / `common.glsl` for multipass). Easiest path: import the shader in the Strata app (**File → Import**) — it converts a Shadertoy `.json`/`.zip` into this exact folder layout *and* generates a `thumbnail.png` — then copy that folder in here.
3. **Textures / cubemaps** go in `external/`, referenced by file name in the manifest's `bindings` (`type = "texture"` / `"cubemap"`). Don't duplicate assets.
4. **Attribution:** set `source_url` in the manifest (required for Shadertoy-sourced shaders — it powers the clickable "Made by …" credit in the Library).
5. **Thumbnail:** include a `thumbnail.png` (480×270). If omitted the app generates one at runtime, but shipping it shows a preview immediately and works on read-only installs.
6. **Regenerate the index:** run `.\update-index.ps1`, then commit your folder + `index.toml` and open a PR. (The maintainer assigns the version and cuts the tag.)

### ⚠️ wgpu / naga caveats (read before submitting)

Strata compiles GLSL through wgpu's **naga** front-end, which is stricter than Shadertoy's WebGL/ANGLE compiler:

* **`mat2(vec4)` / `mat2(float)`** single-argument constructors (the `mat2(cos(a + vec4(...)))` rotation idiom) miscompile in naga. The in-app importer auto-rewrites these; if you hand-author, spell the matrix out: `mat2(v.x, v.y, v.z, v.w)`.
* **Per-channel sampler settings** (wrap / filter / mipmap) aren't honored yet — every texture samples as Repeat + Linear with no mipmaps. Avoid relying on `clamp` wrapping or high-LOD `textureLod`.
* **Volume (3D) textures** and the **keyboard** input are unsupported. **Cubemaps**, 2D textures (incl. noise), multipass buffers (A–D + `common`), and audio (`iChannel` fed by the live system-audio FFT/waveform) are supported.
* naga can reject otherwise-valid constructs. The engine catches compile/codegen panics so a bad shader fails to load rather than crashing — but **test your shader in Strata** (Import shows a toast on failure) before submitting.

---

## 📜 License

Engine code lives in the main Strata repo (FOSS). Shaders here retain their original authors' licenses — see each shader's `source_url`. Shadertoy's default media assets in `external/` belong to their respective owners; they are included for compatibility and are **not** relicensed.
