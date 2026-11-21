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

      required_check {
        context        = "Static checks"
        integration_id = 15368
      }

      # Published as a commit status by .github/workflows/review-replies.yml (no app integration).
      required_check {
        context = "Review replies"
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

# Every action reference in the workflows is a full commit SHA (Renovate keeps them current), so GitHub can refuse
# any unpinned reference. Existing values (enabled, allow all actions) are kept as they are.
import {
  to = github_actions_repository_permissions.servarr
  id = "servarr"
}

resource "github_actions_repository_permissions" "servarr" {
  repository           = github_repository.servarr.name
  enabled              = true
  allowed_actions      = "all"
  sha_pinning_required = true
}
