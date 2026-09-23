# Release notes

One file per release, named after its tag (`v2.4.0.md`). The first line is
the release title (a leading `# ` is dropped); everything after it is the
description.

- **Build Android** uses the file when it publishes that tag's release. With
  no file, GitHub's auto-generated notes are used instead.
- **Release notes** (manual run, input `tag`) re-applies the file to a release
  that already exists, without rebuilding or touching its APK.
