# AGENT Cloud Agents Rules

This file contains rules and guidelines for agentic local repository commits when operating in cloud VM environments away from direct user supervision.

> **IMPORTANT:** This file is for AGENT's reference only. Do not include this information in developer-facing documentation.

---

## Cloud Agent Workflow Exception

* There may be times when an agent is operating in a cloud VM away from user supervision.
* User may pop in via RDP occasionally to give feedback.
* These cases are an **exception** to the "only user adds and commits to repos" rule.
* Cloud agents may perform git operations (add, commit) independently when following the workflow below.

---

## Cloud Agent Workflow

When operating as a cloud agent in an unsupervised environment, follow this workflow:

1. **Check out latest from designated dev branch** into a feature branch labeled with `AGENTNAME_FEATURENAME`.
2. **Compile source and confirm error-free.**
3. **If there are errors:** Notify user and hold. There will be a designated way to ping user.
4. **If the dev branch is error-free:** Begin with high-level task planning.
5. **Write MD files in a Research directory** - Answer unknowns regarding feasibility of ideal implementation.
6. **When unknowns become known and the feature is deemed feasible:** Document target implementation in `FEATURENAME_README.md` in the most appropriate section of the codebase. Ping user with current task list detailed in that readme. Pause and request approval per user-provided rules.
7. **If continuation permission is deemed auto** for this feature per user rules/allow lists, then implement the tasks.
8. **Seek to compartmentalize classes** in standalone ways such that they can be easily unit-tested. When a unit test for a task is ready, test it. If it passes, add and commit. **Do not push to dev.**
9. **If user arrives prior to completion of task list:** Summarize current status.
10. **If task list is complete prior to user arrival:** Ping user for code review.
11. **Implement user's notes as new tasks.** When complete, merge to dev branch **only with user's express permission.**

---

## Git Operations for Cloud Agents

* Cloud agents may perform `git add` and `git commit` operations independently when following the workflow above.
* Cloud agents **must NOT** push to dev branch without user's express permission.
* Cloud agents **must NOT** merge to dev branch without user's express permission.
* All commits should be made to feature branches (`AGENTNAME_FEATURENAME`).
* User retains full control over branch merging and remote repository operations.

---

## Remember

* **CRITICAL:** NEVER use backtick marks (`) in responses to the user - they cause formatting issues in Cursor chat.

---

**Last Updated:** 2025-01-XX

