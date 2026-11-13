Generate a human-readable PR description of all changes on this branch, in the
shape defined in `.standards/process/how-we-build.md` § The PR description.

Analyze `git diff main...HEAD` (fall back to `git diff HEAD` if there are only
uncommitted changes).

1. **Requirements first.** Compare `spec/requirements/`, `spec/glossary.md` and
   `spec/design/decisions.md` on this branch against `main`, by number:
   - **Added**: numbers not on `main`. Quote the full text.
   - **Changed**: numbers whose text differs. Quote the new text, then
     `Was:` with the text on `main`. Glossary terms go here as
     `Glossary: <term>`.
   - **Retired**: numbers newly struck through. Quote the text and the reason.
   - **Relies on, unchanged**: requirements the change depends on without
     changing them, from the ticket or conversation if they were named there.
   - Write `None` for an empty group. If nothing under `spec/` changed, write
     `No requirement changes.` with a one-line reason, naming the requirement
     a bug fix restores conformance with.
   - A requirement that exists on `main` but was deleted rather than retired is
     a spec defect: stop and report it instead of listing it.
2. **Design decisions**, only if `spec/design/` changed, in the same groups,
   with a note that the PR needs Engineering review.
3. **Alignment**: the alignment score of the branch surface at the branch point
   and at this branch's latest commit, per
   `.standards/process/decision-rubric.md` § On a branch
   (the same procedure as `/_align branch`, with `--quick`, using the
   opening description of what was asked for as the description of the change),
   using the weights in `spec/README.md`. List each criterion that moved, with
   its evidence; carry the others over unchanged. Mark a drop of 10 or more
   with ⚠️ and a reason. If no criterion's evidence changed, write
   `No alignment change.` with a one-line reason. If `spec/README.md` has no
   Priorities section, write `No priorities defined yet.`
4. **Verification**: for each Added and Changed requirement, the test (file and
   test name) or evidence that demonstrates it, or `not verified` and why.
5. **Implementation notes**: short. The approach, risky spots, whether a
   `changelog.d/` entry is present or was deliberately skipped, follow-ups.
6. Open with one or two sentences on what was asked for and why, in the words
   of the person who asked, and a ⚠️ Breaking line if the change is breaking.

Format the output so it can be pasted directly as a PR description.
