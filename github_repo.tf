# The repository itself and its branch ruleset, managed in Terraform so that a change made in the
# GitHub UI shows up as drift (weekly drift check) instead of silently sticking.
# Both resources were imported as-is: the first plan after import must show no changes.

import {
  to = github_repository.servarr
  id = "servarr"
}

import {
  to = github_repository_ruleset.main
  id = "servarr:8276307"
}

resource "github_repository" "servarr" {
  name         = "servarr"
  description  = "A secure, reliable, hybrid cloud Plex server"
  homepage_url = "https://nathanjn.com/posts/plex-serv-arr/"
  visibility   = "public"

  has_issues      = true
  has_projects    = true
  has_wiki        = false
  has_discussions = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = false
  allow_update_branch    = true
  delete_branch_on_merge = true

  merge_commit_title          = "MERGE_MESSAGE"
  merge_commit_message        = "PR_TITLE"
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"

  web_commit_signoff_required = false

  lifecycle {
    prevent_destroy = true

    # TEMPORARY. Provider 6.13 does not read these settings on import, so the first plan wants to "update"
    # them to the values that are already live. The workspace's github_access_token cannot write to the
    # repository (403 on PATCH; it needs Administration: read/write), so the apply failed. Ignoring them
    # means the apply only imports. Remove this block once the token has Administration write; the
    # next plan will then apply values equal to what is live today.
    ignore_changes = [
      allow_merge_commit,
      allow_squash_merge,
      allow_rebase_merge,
      allow_update_branch,
      delete_branch_on_merge,
      merge_commit_title,
      merge_commit_message,
      squash_merge_commit_title,
      squash_merge_commit_message,
      ignore_vulnerability_alerts_during_read,
    ]
  }
}

resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = github_repository.servarr.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    required_status_checks {
      strict_required_status_checks_policy = true
      do_not_enforce_on_create             = false

      required_check {
        context        = "Terraform plan"
        integration_id = 15368
      }
    }

    required_code_scanning {
      required_code_scanning_tool {
        tool                      = "CodeQL"
        alerts_threshold          = "errors"
        security_alerts_threshold = "high_or_higher"
      }
    }

    copilot_code_review {
      review_on_push             = false
      review_draft_pull_requests = false
    }

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = ["merge", "squash", "rebase"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
