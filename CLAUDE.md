# AtomiCloud Shared Repository

This repository stores shared files and conventions used across all AtomiCloud repositories.

## Purpose

1. **Standard Documentation** - Central source of truth for how AtomiCloud operates on code
2. **Principles & Conventions** - Planning principles, coding principles, and development workflows
3. **LLM Training** - Teaches LLMs (and humans) "the AtomiCloud way" of writing code, thinking, and planning

## Structure

```
templates/
├── .claude/
│   └── skills/          # Skill definitions (triggers)
└── docs/
    └── developer/
        └── standard/     # Main documentation (source of truth)
```

## Key Concepts

### Skills vs Documentation

| Location                             | Purpose                                                                 |
| ------------------------------------ | ----------------------------------------------------------------------- |
| `templates/.claude/skills/`          | **Triggers** - Concise skill definitions that invoke the right context  |
| `templates/docs/developer/standard/` | **Source of Truth** - Detailed explanations, principles, and guidelines |

- **Skills** act as lightweight triggers that link to main docs
- **Docs** contain the actual content — explanations of principles, patterns, and conventions
- Skills reference docs; docs explain skills

## Distribution

The `templates/` folder is shared to all other repositories via **cyanprint**. This ensures consistent conventions across the entire AtomiCloud codebase.

## For LLMs

When working in any AtomiCloud repository:

1. This shared context provides the "AtomiCloud way" of doing things
2. Skills act as entry points to specific conventions
3. Always reference the standard docs for detailed explanations
4. Follow the principles outlined in the standard documentation

## Repository References

Reference implementations across languages are stored in `.claude/REPO_REFS.md`. When refining skills, consult these repos to extract common patterns and language-specific adaptations.

## Supported Languages

Skills are designed to be language-agnostic with implementation guidance for:

- TypeScript (Bun)
- C# (.NET)
- Go
- Rust
