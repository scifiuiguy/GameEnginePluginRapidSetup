# AGENT Embedded Firmware Rules

This file contains rules and guidelines for maintaining embedded firmware examples in cross-platform codebases.

> **IMPORTANT:** This file is for AGENT's reference only. Do not include this information in developer-facing documentation.

---

## Full Duplication Requirement

All firmware examples **MUST** be fully duplicated across all platform codebases (e.g., Unity and Unreal, or any other cross-platform setup).

### Rationale

- Developers typically work with only one platform, not all platforms
- If a developer needs firmware examples that only exist in another platform's codebase, they would have to pull the entire other codebase just to get firmware examples
- This creates unnecessary friction and dependency
- Firmware examples are small text files - duplication is not a significant overhead

### Rule

When adding, modifying, or updating firmware examples:

1. Make changes in **ALL** platform codebases
2. Ensure file structure is identical across all platforms
3. Verify all files are present in all platforms
4. Update documentation in all platforms

### Example File Locations (for Unity/Unreal projects)

- Platform A: `[ProjectRoot]/[PlatformA]/FirmwareExamples/`
- Platform B: `[ProjectRoot]/[PlatformB]/FirmwareExamples/`

### Verification

- Use file comparison to ensure all platform directories have identical structure
- All `.ino` files, `.h` files, and `README.md` files must exist in all platforms

---

## Folder Organization

All embedded firmware examples **MUST** be located in a dedicated folder (e.g., `FirmwareExamples/`), not in platform-specific special folders.

### Rationale

- Some platforms have special folders (e.g., Unity's `Resources/` folder) that include all assets in builds
- Firmware examples are **NOT** platform assets and should **NOT** be included in builds
- Using a dedicated folder (e.g., `FirmwareExamples/`) avoids this issue while keeping organization clear

### Structure Example

- `FirmwareExamples/Base/` - Generic reusable modules
- `FirmwareExamples/[ExperienceType]/` - Experience-specific examples
- (Organize by functionality or experience type as needed)

---

## Platform Code References

Platform code (e.g., Unity/Unreal) should reference firmware examples in documentation only.

- Code should **NOT** depend on firmware example folder location
- Documentation should point developers to firmware examples folder
- No hardcoded paths to firmware examples in platform code

---

## File Naming

- Use descriptive names that indicate functionality
- Platform-agnostic names preferred (e.g., `ButtonMotor_Example.ino` not `ESP32_ButtonMotor.ino`)
- Platform-specific variants only when necessary (e.g., when hardware limitations require different implementations)
- Include platform support information in comments/documentation

---

## Copyright and License

All firmware examples should include:

- Copyright notice with appropriate attribution
- License statement in file header
- Consistent formatting across all examples

---

## Remember

* **NEVER use backtick marks (`) in responses to the user** - they cause formatting issues in Cursor chat.

---

**Last Updated:** 2025-01-XX

