#!/usr/bin/env bats
# Behavior tests for dotfiles/zsh/starship-qwt-worktree.sh.
#
# Each test builds its own throwaway git layout under a temp directory, so no
# fixtures are checked into the repository.

SCRIPT="${BATS_TEST_DIRNAME}/../dotfiles/zsh/starship-qwt-worktree.sh"

setup() {
  ORIGINAL_DIR="$(pwd)"
  TEST_TMP="$(mktemp -d)"
}

teardown() {
  cd "$ORIGINAL_DIR"
  rm -rf "$TEST_TMP"
}

# Builds a qwt-style bare-repo + worktree layout:
#   $TEST_TMP/<owner>/<repo>/.bare        bare repository
#   $TEST_TMP/<owner>/<repo>/.git         "gitdir: ./.bare" pointer file
#   $TEST_TMP/<owner>/<repo>/<branch>/... worktree for $branch
make_qwt_worktree() {
  local owner="$1" repo="$2" branch="$3"
  local repo_dir="$TEST_TMP/$owner/$repo"
  local scratch

  mkdir -p "$repo_dir"
  git init -q --bare "$repo_dir/.bare"
  printf 'gitdir: ./.bare\n' >"$repo_dir/.git"

  scratch="$(mktemp -d)"
  git clone -q "$repo_dir/.bare" "$scratch"
  (
    cd "$scratch" || exit 1
    git -c commit.gpgsign=false checkout -q -b "$branch"
    git -c commit.gpgsign=false commit -q --allow-empty -m init
    git -c commit.gpgsign=false push -q origin "$branch"
  )
  rm -rf "$scratch"

  git -C "$repo_dir" --git-dir=.bare worktree add -q "$branch" "$branch"
}

@test "prints owner/repo/branch at the worktree root" {
  make_qwt_worktree owner repo main
  cd "$TEST_TMP/owner/repo/main"

  run sh "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "owner/repo/main" ]
}

@test "appends the relative path from a nested subdirectory" {
  make_qwt_worktree owner repo main
  mkdir -p "$TEST_TMP/owner/repo/main/src/lib"
  cd "$TEST_TMP/owner/repo/main/src/lib"

  run sh "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "owner/repo/main/src/lib" ]
}

@test "preserves branch names containing a slash" {
  make_qwt_worktree owner repo feature/foo
  mkdir -p "$TEST_TMP/owner/repo/feature/foo/subdir"
  cd "$TEST_TMP/owner/repo/feature/foo/subdir"

  run sh "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "owner/repo/feature/foo/subdir" ]
}

@test "exits non-zero outside a qwt-managed worktree" {
  git init -q "$TEST_TMP/plain"
  cd "$TEST_TMP/plain"

  run sh "$SCRIPT"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "exits non-zero outside any git repository" {
  mkdir -p "$TEST_TMP/no-git"
  cd "$TEST_TMP/no-git"

  run sh "$SCRIPT"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
}
