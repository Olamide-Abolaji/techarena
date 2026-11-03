from typing import Any


def evaluate_weighted_submission(
    submission: dict[str, Any],
    evaluation_config: dict[str, Any],
    pass_score: float = 70.0,
    xp_reward: int = 0,
) -> dict[str, Any]:
    """Deterministic evaluator for server-side accepted-value and evidence rules.

    evaluation_config is private server-side data and must never be returned by
    learner-facing mission endpoints.
    """
    checks: list[dict[str, Any]] = []
    total = 0.0
    earned = 0.0
    for criterion in evaluation_config["criteria"]:
        points = float(criterion["max_points"])
        total += points
        field = criterion["field"]
        method = criterion["scoring_method"]
        if method == "accepted_value":
            passed = submission.get(field) in criterion["accepted_values"]
        elif method == "required_evidence":
            passed = set(criterion["required_ids"]).issubset(set(submission.get(field, [])))
        else:
            raise ValueError(f"Unsupported scoring method: {method}")
        award = points if passed else 0.0
        earned += award
        checks.append({"criterion_key": criterion["criterion_key"], "max_points": points,
                       "earned_points": award, "passed": passed})
    if total <= 0:
        raise ValueError("Evaluation criteria must total more than zero")
    score = round(earned / total * 100, 2)
    passed = score >= pass_score
    return {"score": score, "passed": passed, "max_points": total,
            "earned_points": earned, "checks": checks,
            "xp_eligible": passed, "xp_reward": xp_reward if passed else 0}
