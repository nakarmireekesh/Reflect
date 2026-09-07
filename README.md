# Reflect

A private journaling app. The reflection features — a gentle follow-up question
per entry, a weekly digest, and "ask your journal" — run **entirely on device**
using Apple's **Foundation Models** framework (iOS 26). No network, no API key,
nothing leaves the phone.

| Journal | Editor | Insights | Ask |
| --- | --- | --- | --- |
| Timeline of entries, mood + themes per row | Write, then stream a reflective question | Theme-frequency chart + weekly digest | Free-text Q&A grounded in your own entries |

> Add screenshots to `Docs/` once you've run it with Apple Intelligence enabled.

## What it demonstrates

| Area | Detail |
| --- | --- |
| **Foundation Models** | `SystemLanguageModel` availability handling, `LanguageModelSession`, **structured output** with `@Generable` / `@Guide` (`EntryReflection`, `WeeklyDigest`), **streamed** responses, per-request timeout, friendly mapping of `GenerationError` (guardrail / context-window / not-ready) |
| **Context management** | The on-device model has a small context window, so `EntryRetrieval` ranks past entries by keyword overlap, falls back to recency, and trims to a character budget before they're sent — a mini retrieval step, pure and unit-tested |
| **Graceful degradation** | When Apple Intelligence is off or still downloading, the journal stays fully usable; only the reflection features switch off, with an inline reason. Stale "analysing" flags are cleared on launch |
| UI | SwiftUI, `@Entry` environment injection, `Tab`-based `TabView`, `ContentUnavailableView`, Swift Charts |
| Persistence | SwiftData (`@Model JournalEntry`), background analysis after save |
| Concurrency | `async`/`await`, `AsyncThrowingStream`, `withThrowingTaskGroup` timeouts, task cancellation on view teardown |
| Testing | `StubJournalIntelligence` for previews + tests; 11 unit tests (retrieval ranking/budget, insights planning, streaming contract) |
| Dependencies | none |

## Project layout

```
Reflect/
├── App/            ReflectApp, RootView, environment key, preview data
├── Models/         JournalEntry (@Model)
├── Intelligence/
│   ├── JournalIntelligence.swift              protocol + availability + errors
│   ├── GenerableTypes.swift                   @Generable EntryReflection / WeeklyDigest
│   ├── FoundationModelsJournalIntelligence.swift   the on-device implementation
│   ├── StubJournalIntelligence.swift          deterministic stub for previews/tests
│   └── EntryRetrieval.swift                   context selection for "Ask"
├── Features/
│   ├── Timeline/   list of entries
│   ├── Editor/     write + stream a reflective question + background analysis
│   ├── Insights/   InsightsPlanner (pure) + charts + weekly digest
│   └── Ask/        retrieval + streamed answer
└── DesignSystem/   small shared components
ReflectTests/       EntryRetrieval, InsightsPlanner, StubJournalIntelligence
```

## Running it

1. **Xcode 26** or newer. Open `Reflect.xcodeproj`, pick an iPhone 15 Pro / 16 /
   17 simulator (or a device), press **⌘R**. Tests: **⌘U**.
2. The journal, editor, insights layout and Ask UI all work immediately.
3. **To see on-device generation actually run**, Apple Intelligence must be
   enabled on the machine:
   - **Simulator:** enable Apple Intelligence on the host Mac
     (System Settings ▸ Apple Intelligence & Siri) — the model downloads once
     (a few GB, supported region + signed-in Apple Account required) and the
     simulator then inherits it.
   - **Device:** Settings ▸ Apple Intelligence & Siri, on an iPhone 15 Pro or newer.
   Until then the app shows an inline "reflections are off" notice and works as a
   plain journal — which is the intended fallback.

```bash
xcodebuild -project Reflect.xcodeproj -scheme Reflect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build test
```

## Notes on the model

The on-device model is small (~3B params). It's used only for tasks it's good at
— naming a feeling, spotting themes, short reflective questions, brief summaries
— never for facts or advice. Prompts are written as narrow tasks, structured
output is constrained with `@Guide`, and every request has a timeout.
