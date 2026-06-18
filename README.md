# Strata-Library

The shared content library for **[Strata](https://github.com/)** — the lightweight
Rust + wgpu live-wallpaper engine. Strata's engine ships with **no** shaders,
models, or presets baked in; instead it fetches this library at first launch and
re-syncs on demand. Keeping content here keeps the engine repo small and
license-clean, and lets the community add wallpapers without touching engine code.

> **Status:** prototype. The layout and `index.toml` schema below are what the
> engine reads; expect refinement before the first published `library-v1.0.0` tag.

## Layout

```
Strata-Library/
├── index.toml                  # manifest: schema/library version + per-item hashes
├── models.toml                 # Parallax-Studio depth/segment/upscale model registry
├── presets.toml                # Parallax-Studio quality presets
├── external/                   # shared texture & cubemap assets (referenced by name)
│   └── <sha>.png / <sha>.jpg   # cubemaps add 5 sibling faces <sha>_1..<sha>_5
└── shader-library/             # all wallpaper folders live here
    └── <wallpaper-slug>/       # one folder per wallpaper, self-contained
        ├── manifest.toml       # name, author, source_url, tags, passes, bindings
        ├── image.glsl          # the shader (+ bufferA.glsl…, common.glsl for multipass)
        └── thumbnail.png       # 480×270 preview (generated, ships with the pack)
```

At runtime the engine fetches this tree verbatim into
`%APPDATA%/strata/strata-library/` (as if the repo were cloned there), so a
shader resolves to `…/strata-library/shader-library/<slug>/` and an asset to
`…/strata-library/external/<file>`.

A wallpaper folder is **self-contained**: zip it and it's a complete, importable
pack. Textures/cubemaps are *not* duplicated into each folder — they're referenced
by file name and resolved from `external/` (so one copy serves every shader).

## `index.toml`

```toml
schema_version = 1
library_version = "1.0.0"

[files.models]   # bump version + hash when models.toml changes
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

The client uses `added_in` vs the last-synced `library_version` to flag **NEW**
shaders and drive newest/oldest sorting; the `sha256` fields let it detect what
actually changed (and verify integrity) so it re-fetches only what's needed.

Regenerate `index.toml` + thumbnails from the engine repo with:

```
cargo test -p core-engine --test assemble_library -- --ignored
```

## Distribution

Published via **jsDelivr** off this repo's GitHub releases, pinned to an immutable
tag — e.g. `https://cdn.jsdelivr.net/gh/<owner>/Strata-Library@library-v1.0.0/…`.
Use the explicit `@library-v1.0.0` tag (not `@latest`) so a given engine build
always resolves a known-good, cacheable snapshot.

## Contributing a wallpaper

1. Add a folder `<your-slug>/` with `manifest.toml` + `image.glsl` (and
   `bufferA.glsl…` / `common.glsl` for multipass). Shadertoy shaders can be
   imported in-app (File → Import) and the generated folder dropped in here.
2. Put any textures/cubemaps in `external/` and reference them by file name in the
   manifest's `bindings` (`type = "texture"` / `"cubemap"`). Don't duplicate assets.
3. Include `source_url` for attribution (required for Shadertoy-sourced shaders —
   it powers the clickable "Made by …" credit in the Library).
4. Add a `thumbnail.png` (or let the maintainer regenerate it).
5. Open a PR. Add an `[[shader]]` entry with `added_in` = the next library version.

### wgpu / naga caveats (read before submitting)

Strata compiles GLSL through wgpu's **naga** front-end, which is stricter than
Shadertoy's WebGL/ANGLE compiler. Common gotchas:

- **`mat2(vec4)` / `mat2(float)`** single-argument constructors (the
  `mat2(cos(a + vec4(...)))` rotation idiom) miscompile in naga. The in-app
  importer auto-rewrites these to a safe helper; if you hand-author, spell the
  matrix out (`mat2(v.x, v.y, v.z, v.w)`).
- **Per-channel sampler settings** (wrap/filter/mipmap) aren't honored yet —
  every texture samples as Repeat + Linear with no mipmaps. Avoid relying on
  `clamp` wrapping or high-LOD `textureLod`.
- **Volume (3D) textures** and the **keyboard** input are unsupported; **cubemaps**,
  2D textures (incl. noise), multipass buffers (A–D + common), and audio (`iChannel`
  fed by live system-audio FFT/waveform) are supported.
- naga can reject otherwise-valid constructs; the engine catches compile/codegen
  panics so a bad shader fails to load rather than crashing — but test your shader
  in Strata (Import shows a toast on failure) before submitting.

## License

Engine code lives in the main Strata repo (FOSS). Shaders here retain their
original authors' licenses — see each shader's `source_url`. Shadertoy's default
media assets in `external/` belong to their respective owners; they are included
for compatibility and are **not** relicensed.
