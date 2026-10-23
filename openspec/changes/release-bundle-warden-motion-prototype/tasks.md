## 1. Preserve and package 0.4.1

- [x] 1.1 Record native-build confirmation and pin accepted binary sizes/hashes; inspect Warden skin/animation metadata without changing model bytes.
- [x] 1.2 Add player controls/objective README, asset credits and exact-version engine/component license notices with provenance.
- [x] 1.3 Implement/test deterministic allowlisted packaging with hash/size verification, no private-file inclusion and nondestructive output handling.
- [x] 1.4 Create and verify the portable ZIP, extract it outside the project and repeat packaged/native startup checks.

## 2. Isolated Warden motion study

- [x] 2.1 Implement a deterministic bounded whole-model pose sampler and documented baseline comparison, preserving the 0.55-second attack reference.
- [x] 2.2 Add a standalone scene with two Warden visuals, phase/limitation labels and clip/auto/pause/replay/quit controls; no gameplay actors or events.
- [x] 2.3 Add explicit prototype exclusions to future exports without re-exporting or changing the accepted binaries.

## 3. Verification and review

- [x] 3.1 Test clip determinism, grounding, phase boundaries, real input/pause/replay, isolation and scene cleanup; prove focused checks detect disabled motion.
- [x] 3.2 Run original source/package regressions and offline tests; render/inspect 720p/1080p study captures and record exact evidence/limitations.
- [x] 3.3 Document package/preview launch instructions and rigging follow-up, without claiming human approval or closing earlier unreported checks.
- [ ] 3.4 Obtain the user's visual review of the motion study and decide whether to scope a proper rigging/limb-animation prototype.

On 2026-10-22 the user reported "tested it - works!", confirming a successful user test of the study. Task 3.4 is partially evidenced and remains open for a candidate-timing preference and rigging follow-up decision; no paid service or gameplay integration is inferred from this feedback.

The user subsequently chose the local-only rigging follow-up and approved portable Blender installation. Implementation is tracked separately in `warden-local-rig-prototype`; task 3.4 now remains open only for its unreported candidate-timing preference, not the already-made rigging decision. No paid service or gameplay integration is authorized by that choice.
