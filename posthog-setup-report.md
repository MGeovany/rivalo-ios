<wizard-report>
# PostHog post-wizard report

The wizard has completed a deep integration of PostHog analytics into the Rivalo iOS app. The PostHog iOS SDK (3.58.0) was added via Swift Package Manager, initialized in the `RivaloApp` entry point using environment variables set in the Xcode scheme, and event capture + user identification was wired across 9 source files covering every major user flow: authentication, match recording, session management, profile completion, and account churn.

User identification (`PostHogSDK.shared.identify`) is called on sign-up, sign-in, and session restore so that all events are correlated to the authenticated user. `PostHogSDK.shared.reset()` is called on sign-out and account deletion to clear the identity.

| Event | Description | File |
|---|---|---|
| `user_signed_up` | User successfully created a new account | `Sources/Features/Authentication/AuthenticationFeature.swift` |
| `user_signed_in` | User successfully signed in with email and password | `Sources/Features/Authentication/AuthenticationFeature.swift` |
| `user_signed_out` | User signed out of their account | `Sources/App/AppFeature.swift` |
| `password_recovery_requested` | User submitted a password recovery request | `Sources/Features/Authentication/AuthenticationFeature.swift` |
| `match_start_requested` | User tapped Record to start a match on Apple Watch (result: started/queued/unavailable) | `Sources/Features/Record/RecordFeature.swift` |
| `live_match_ended` | User tapped End during a live match (includes elapsed_s, distance_m) | `Sources/Features/Record/LiveMatchFeature.swift` |
| `match_context_saved` | User saved post-match context (outcome, match_type) | `Sources/Features/Record/MatchContextFeature.swift` |
| `session_deleted` | User confirmed deletion of an activity session | `Sources/Features/Sessions/SessionDetailFeature.swift` |
| `session_viewed` | User opened a session detail | `Sources/Features/Sessions/SessionsFeature.swift` |
| `profile_saved` | User saved profile changes | `Sources/Features/Profile/ProfileFeature.swift` |
| `player_card_photo_added` | User selected a photo for their player card | `Sources/Features/Profile/ProfileFeature.swift` |
| `player_card_photo_processed` | Background removal completed (success: true/false) | `Sources/Features/Profile/ProfileFeature.swift` |
| `account_deleted` | User confirmed permanent account deletion (churn signal) | `Sources/Features/Profile/ProfileFeature.swift` |
| `insights_position_viewed` | User opened the position insights detail screen | `Sources/Features/Sessions/InsightsFeature.swift` |
| `court_measured` | User tapped to measure a court | `Sources/Features/Record/RecordFeature.swift` |

## Next steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

- [Analytics basics (wizard) — Dashboard](https://us.posthog.com/project/455314/dashboard/1672641)
- [New signups & sign-ins](https://us.posthog.com/project/455314/insights/zUSgeMOy)
- [Match recording funnel](https://us.posthog.com/project/455314/insights/CgRbpKJt)
- [Session engagement trend](https://us.posthog.com/project/455314/insights/Ha3UJONj)
- [Profile completion trend](https://us.posthog.com/project/455314/insights/1jvSOo0Y)
- [Churn signals](https://us.posthog.com/project/455314/insights/FuoOkEVy)

**Important — Xcode scheme setup required:** The PostHog environment variables (`POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST`) are defined in `project.yml` under the `schemes.Rivalo.run.environmentVariables` section. You must re-run `xcodegen generate` so the updated scheme with these variables is written to the `.xcodeproj`. After that, build and run the app and the SDK will initialize automatically.

### Agent skill

We've left an agent skill folder in your project at `.claude/skills/integration-swift/`. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

</wizard-report>
