from app.domain.evaluator import evaluate_weighted_submission

RULES = {"criteria": [
    {"criterion_key": "diagnosis", "field": "diagnosis", "scoring_method": "accepted_value", "accepted_values": ["missing_nat"], "max_points": 60},
    {"criterion_key": "evidence", "field": "evidence", "scoring_method": "required_evidence", "required_ids": ["private_route_table"], "max_points": 40},
]}

def test_perfect_submission_is_deterministic_and_awards_xp():
    answer = {"diagnosis": "missing_nat", "evidence": ["private_route_table"]}
    first = evaluate_weighted_submission(answer, RULES, 70, 100)
    second = evaluate_weighted_submission(answer, RULES, 70, 100)
    assert first == second
    assert first["score"] == 100
    assert first["passed"] is True
    assert first["xp_reward"] == 100

def test_incorrect_submission_does_not_award_xp():
    answer = {"diagnosis": "wrong", "evidence": []}
    result = evaluate_weighted_submission(answer, RULES, 70, 100)
    assert result["score"] == 0
    assert result["passed"] is False
    assert result["xp_reward"] == 0
