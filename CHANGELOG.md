# Changelog

All notable changes to this project will be documented in this file.

## [2.13.1] - WIP

### Added
- N/A

### Changed
- N/A

### Fixed
- Mistral vision does not work (https://github.com/nbonamy/witsy/issues/382)
- PDF webpage content not extracted )https://github.com/nbonamy/witsy/issues/383)

### Removed
- N/A


## [2.13.0] - 2025-08-08

This release introduces agents in Witsy! When Deep Research was relesed, it was built on top of an agent creation and execution framework that was not exposed through Witsy UI. This is now fixed. Head-over to the [Create you own agents](https://github.com/nbonamy/witsy/wiki/Creating-your-first-agents) tutorial to learn how to create multi-step workflow agents and have agents delegate tasks to other agents!

### Added
- [Create you own agents](https://github.com/nbonamy/witsy/wiki/Creating-your-first-agents)
- Document Repository file change monitoring (https://github.com/nbonamy/witsy/discussions/304)
- OpenAI GPT-5 model support (vision flag, verbosity) (https://github.com/nbonamy/witsy/issues/379)

### Changed
- N/A

### Fixed
- N/A

### Removed
- N/A


## [2.12.5 / 2.12.6] - 2025-08-06

### Added
- ChatGPT History Import (https://github.com/nbonamy/witsy/issues/378)

### Changed
- N/A

### Fixed
- API key field for a new provider should start out empty (https://github.com/nbonamy/witsy/issues/368)
- OpenAI responses API integration (https://github.com/nbonamy/witsy/issues/338)
- Deleted experts are still used when called from specific applications (https://github.com/nbonamy/witsy/issues/375)
- Refresh of Gemini embedding model in Embedding selector (https://github.com/nbonamy/witsy/issues/374)
- Using “provider order” breaks OpenRouter (https://github.com/nbonamy/witsy/issues/372)
- Deep Research mode tries to download a PDF instead of reading it (https://github.com/nbonamy/witsy/issues/371)

### Removed
- N/A


## [2.12.4] - 2025-07-31

### Added
- On macOS, Cmd-N should start a new chat (https://github.com/nbonamy/witsy/issues/363)

### Changed
- N/A

### Fixed
- Dialogs in settings can be cut-off (https://github.com/nbonamy/witsy/issues/359)
- Checkboxes always look checked in dark mode (https://github.com/nbonamy/witsy/issues/361)
- Plugins that are disabled in app settings, are still available and enabled in chat settings (https://github.com/nbonamy/witsy/issues/362)

### Removed
- N/A


## [2.12.3] - 2025-07-28

### Added
- N/A

### Changed
- N/A

### Fixed
- N/A

### Removed
- Soniox STT support (https://github.com/nbonamy/witsy/issues/355)


## [2.12.2] - 2025-07-27

### Added
- Tooltips (https://github.com/nbonamy/witsy/discussions/344)
- OpenAI responses API integration (https://github.com/nbonamy/witsy/issues/338)
- Allow specifying allowed providers for OpenRouter (https://github.com/nbonamy/witsy/issues/350)
- Soniox STT (https://github.com/nbonamy/witsy/pull/353) 

### Changed
- Specific models to create chat title
- Allow empty prompts with attachments (https://github.com/nbonamy/witsy/pull/351)

### Fixed
- Create / edit commands : cannot create new line (https://github.com/nbonamy/witsy/issues/348)

### Removed
- N/A


## [2.12.1] - 2025-07-23

### Added
- Google video creation
- Mistral Voxtral STT models support (@ljbred08)
- Support for New Gemini Embedding model (https://github.com/nbonamy/witsy/issues/322)

### Changed
- N/A

### Fixed
- xAI image generation
- STT/Whisper: "language" parameter should not be sent (https://github.com/nbonamy/witsy/issues/340)
- Gladia STT: Maximum Call stack size exceeded (https://github.com/nbonamy/witsy/issues/341)

### Removed
- N/A


## [2.12.0] - 2025-07-20

### Added
- Add, Edit & Delete System Prompts (https://github.com/nbonamy/witsy/issues/308)
- Backup/Restore of data and settings
- Onboarding experience
- Japanese localization (https://github.com/nbonamy/witsy/pull/326)
- Design Studio image drop and image paste
- Design Studio prompt library

### Changed
- Document Repository UI update 

### Fixed
- Design Studio History label overflow fix
- Duplicated models (https://github.com/nbonamy/witsy/issues/331)
- Ctrl+Shift+C does not copy transcript and close transcript window (https://github.com/nbonamy/witsy/issues/336)
- Error when using Eleven Labs for Transcription (https://github.com/nbonamy/witsy/issues/335)
- Wrong position of delete shortcut buttons at shortcut settings (https://github.com/nbonamy/witsy/issues/334)
- Mermaid chart fixes and improvements (https://github.com/nbonamy/witsy/issues/333)
- Google image generation

### Removed
- Google image edit ([not supported by Google API](https://github.com/googleapis/js-genai/blob/36a14e4e05e8808ba65ed392b869be7d9840220b/src/models.ts#L985))


## [2.11.2] - 2025-07-14

### Added
- N/A

### Changed
- N/A 

### Fixed
- xAI function calling (https://github.com/nbonamy/witsy/issues/317)
- Settings Commands and Experts display issue

### Removed
- N/A


## [2.11.1] - 2025-07-14

### Added
- Support for Elevenlabs custom voices (https://github.com/nbonamy/witsy/issues/313)
- MCP Server label (https://github.com/nbonamy/witsy/pull/303)
- Exa native search engine (https://github.com/nbonamy/witsy/issues/310)

### Changed
- N/A 

### Fixed
- MCP Server start when using Nushell (https://github.com/nbonamy/witsy/issues/315) 

### Removed
- N/A


## [2.11.0] - 2025-07-07

### Added
- Custom HTTP Headers for MCP Streamable
- File upload for transcriptions (with dropzone)
- Summarize/Translate/Run AI command for transcription
- Drag and drop to attach files

### Changed
- N/A 

### Fixed
- N/A 

### Removed
- N/A


## [2.10.0] - 2025-07-03

### Added
- DeepResearch
- Fileystem plugin to read/write local files

### Changed
- Text headings font size and spacing 

### Fixed
- PDF export when tools displayed
- Fullscreen exit requiring multiple clicks
- YouTube transcript download
- Duplicate MCP servers sent to model ([#302](https://github.com/nbonamy/witsy/issues/302))

### Removed
- N/A
