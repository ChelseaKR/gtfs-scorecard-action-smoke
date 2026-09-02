.PHONY: verify

# The single definition of this repository's gate. CI runs this exact target
# rather than a hand-copied list of its steps: the two had already drifted
# once, with zizmor running only on a contributor's laptop.
#
# Local verification proves the assertion scripts behave, that every action
# reference says what it does, that the workflow is structurally valid, and
# that it carries no known Actions security smell. It cannot execute GitHub
# Actions or reach the live feed, so the hosted run stays authoritative for
# downstream behaviour.
verify:
	bash tests/test-contract.sh
	bash tests/test-unscorable.sh
	bash tests/test-release-ref.sh
	bash tests/test-pinned-versions.sh
	bash scripts/assert-pinned-versions.sh .github/workflows/verify.yml
	actionlint
	zizmor --persona regular --min-severity medium --no-progress .
