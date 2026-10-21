# Model sources

Six reviewed Meshy GLB exports are bundled under `assets/models/`, with original embedded textures extracted by Godot. Their source bytes and AI-origin metadata are preserved. Texture import files limit runtime dimensions to 1024px.

Normalized visual scenes live in `scenes/models/` and are instanced by the weapon/enemy/prop wrappers. Set a wrapper's `use_placeholder` property to true to use its original procedural alternative; gameplay collision remains separate.

See `docs/asset-manifest.md`, `docs/meshy-generation.md`, and `docs/model-workflow.md` for provenance, the user-confirmed paid-plan review, import transforms, and replacement instructions.
