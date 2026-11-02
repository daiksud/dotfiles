"""Offline regression tests for the actual Python embedded in the workflow."""

import ast
import contextlib
import io
import json
import os
from pathlib import Path
import unittest
from unittest.mock import Mock, patch


WORKFLOW = Path(__file__).resolve().parents[1] / "workflows/approve-codex-review.yml"
HEAD = "a" * 40
OTHER = "b" * 40
BOT = "chatgpt-codex-connector[bot]"
APPROVER = "github-actions[bot]"
PREFIX = "<!-- codex-pull-request-review-summary -->"


def summary(code=HEAD, security=HEAD):
    state = {
        "code_review": {"commit_sha": code},
        "security_review": {"commit_sha": security},
    }
    return (
        PREFIX + "\n"
        "| Review | Status |\n"
        "| **Code Review** | **Completed** |\n"
        "| **Security Review** | **Completed** |\n"
        "<!-- codex-review-state:v1 " + json.dumps(state) + " -->"
    )


class ApprovalTests(unittest.TestCase):
    def setUp(self):
        text = WORKFLOW.read_text()
        start = text.index("          import json\n")
        end = text.index("          PYTHON\n", start)
        script = "\n".join(line[10:] for line in text[start:end].splitlines())
        tree = ast.parse(script)
        # Load definitions without invoking the top-level runner/error handler.
        self.assertIsInstance(tree.body[-1], ast.Try)
        tree.body.pop()
        self.env = patch.dict(os.environ, {
            "GITHUB_REPOSITORY": "example/dotfiles", "PR_NUMBER": "12",
            "GITHUB_STEP_SUMMARY": "",
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.ns = {}
        exec(compile(tree, str(WORKFLOW), "exec"), self.ns)
        self.comments = [{"id": 1, "user": {"login": BOT}, "body": summary()}]
        self.reactions = [{"user": {"login": BOT}, "content": "+1"}]
        self.reviews = []
        self.head = HEAD
        self.posts = []
        self.real_api = self.ns["api"]
        self.ns["api"] = self.api
        self.ns["report"] = Mock()

    def api(self, endpoint, *args):
        if endpoint == "--method":
            self.posts.append(args)
            return {"state": "APPROVED", "commit_id": HEAD}
        if endpoint.endswith("/pulls/12"):
            return {"head": {"sha": self.head}}
        if "/comments?" in endpoint:
            return [self.comments]
        if "/reactions?" in endpoint:
            return [self.reactions]
        if "/reviews?" in endpoint:
            return [self.reviews]
        self.fail("Unexpected API call: " + endpoint)

    def run_workflow(self):
        # Any unintended real subprocess (including gh or sleep) fails the test.
        with patch("subprocess.run", side_effect=AssertionError("Unexpected subprocess")):
            with contextlib.redirect_stdout(io.StringIO()):
                self.ns["run"]()

    def withheld(self):
        self.run_workflow()
        self.assertEqual(self.posts, [])
        self.assertEqual(self.ns["report"].call_args.args[0], "Withheld")

    def test_approves_current_head_once_with_commit_pinned(self):
        self.run_workflow()
        self.assertEqual(self.posts, [(
            "POST", "repos/example/dotfiles/pulls/12/reviews",
            "-f", "event=APPROVE", "-f", "commit_id=" + HEAD,
        )])
        self.reviews.append({
            "user": {"login": APPROVER}, "state": "APPROVED", "commit_id": HEAD,
        })
        self.run_workflow()
        self.assertEqual(len(self.posts), 1)

    def test_approved_and_dismissed_history_both_prevent_reapproval(self):
        for state in ("APPROVED", "DISMISSED"):
            with self.subTest(state=state):
                self.reviews = [{
                    "user": {"login": APPROVER}, "state": state,
                    "commit_id": HEAD.upper(), "body": "",
                }]
                self.withheld()

    def test_other_commit_author_or_state_do_not_block(self):
        for user, state, sha in (
            (APPROVER, "APPROVED", OTHER),
            ("human", "APPROVED", HEAD),
            (APPROVER, "COMMENTED", HEAD),
        ):
            with self.subTest(user=user, state=state, sha=sha):
                self.reviews = [{"user": {"login": user}, "state": state, "commit_id": sha}]
                self.posts.clear()
                self.run_workflow()
                self.assertEqual(len(self.posts), 1)

    def test_both_review_shas_must_match(self):
        for code, security in ((OTHER, HEAD), (HEAD, OTHER), (HEAD[:7], HEAD), (None, HEAD)):
            with self.subTest(code=code, security=security):
                self.comments[0]["body"] = summary(code, security)
                self.withheld()

    def test_missing_duplicate_or_malformed_metadata_withholds(self):
        valid = summary()
        for body in (
            valid.split("\n<!-- codex-review-state")[0],
            valid + "\n" + valid.splitlines()[-1],
            valid.replace(json.dumps(HEAD), "null", 1),
            valid.replace('"code_review":', '"code_review": {}, "code_review":'),
            valid.replace('{"code_review"', '{broken "code_review"'),
        ):
            with self.subTest(body=body):
                self.comments[0]["body"] = body
                self.withheld()

    def test_incomplete_missing_or_duplicate_status_withholds(self):
        for body in (
            summary().replace("**Completed**", "**Running**", 1),
            summary().replace("| **Security Review** | **Completed** |\n", ""),
            summary() + "\n| **Code Review** | **Completed** |",
            summary().replace("| **Code Review** | **Completed** |", "| **Code Review** | Pending | **Completed** |"),
        ):
            with self.subTest(body=body):
                self.comments[0]["body"] = body
                self.withheld()

    def test_latest_bot_summary_wins_not_latest_edit_or_human(self):
        self.comments.extend([
            {"id": 2, "user": {"login": BOT}, "body": summary(OTHER, OTHER)},
            {"id": 3, "user": {"login": "human"}, "body": summary()},
        ])
        self.withheld()

    def test_no_summary_withholds(self):
        self.comments.clear()
        self.withheld()

    def test_missing_or_wrong_author_reaction_never_approves(self):
        for reactions in ([], [{"user": {"login": "human"}, "content": "+1"}],
                          [{"user": {"login": BOT}, "content": "-1"}]):
            with self.subTest(reactions=reactions):
                self.reactions = reactions
                with patch("subprocess.run") as sleep:
                    self.ns["run"]()
                self.assertEqual(self.posts, [])
                self.assertEqual(sleep.call_count, 6)
                sleep.assert_called_with(["sleep", "30"], check=True)

    def test_delayed_reaction_rechecks_summary(self):
        signals = iter((False, True))
        self.ns["thumbs_up"] = lambda: next(signals)
        with patch("subprocess.run") as sleep:
            self.ns["run"]()
        self.assertEqual(sleep.call_count, 1)
        self.assertEqual(len(self.posts), 1)

    def test_head_advance_before_verification_withholds(self):
        self.head = OTHER
        self.withheld()

    def test_invalid_head_fails_closed(self):
        self.head = "short"
        with self.assertRaises(RuntimeError):
            self.run_workflow()
        self.assertEqual(self.posts, [])

    def test_review_history_is_paginated(self):
        review = {"user": {"login": APPROVER}, "state": "DISMISSED", "commit_id": HEAD}
        self.ns["api"] = Mock(return_value=[[], [review]])
        self.assertTrue(self.ns["already_approved"](HEAD))
        self.ns["api"].assert_called_once_with(
            "repos/example/dotfiles/pulls/12/reviews?per_page=100", "--paginate", "--slurp",
        )

    def test_malformed_pagination_fails_closed(self):
        for value in ({}, [None], [[None]]):
            with self.subTest(value=value):
                self.ns["api"] = Mock(return_value=value)
                with self.assertRaises(RuntimeError):
                    self.ns["pages"]("endpoint")

    def test_api_failure_or_invalid_json_does_not_expose_response(self):
        for code, stdout in ((1, "secret"), (0, "not json")):
            with self.subTest(code=code):
                with patch("subprocess.run", return_value=Mock(returncode=code, stdout=stdout)):
                    with self.assertRaises(RuntimeError) as error:
                        self.real_api("endpoint")
                self.assertNotIn(stdout, str(error.exception))

    def test_unconfirmed_post_fails(self):
        original = self.ns["api"]
        def unconfirmed(endpoint, *args):
            if endpoint == "--method":
                return {"state": "APPROVED", "commit_id": OTHER}
            return original(endpoint, *args)
        self.ns["api"] = unconfirmed
        with self.assertRaises(RuntimeError):
            self.run_workflow()


if __name__ == "__main__":
    unittest.main()
