.PHONY: verify

verify:
	actionlint
	zizmor --persona regular --min-severity medium --no-progress .
