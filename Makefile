.PHONY: verify

# Local verification proves the assertion scripts behave, that the workflow is
# structurally valid, and that it carries no known Actions security smell. It
# cannot execute GitHub Actions or reach the live feed, so the hosted run stays
# authoritative for downstream behaviour.
verify:
	bash tests/test-contract.sh
	bash tests/test-release-ref.sh
	actionlint
	zizmor --persona regular --min-severity medium --no-progress .
