.PHONY: verify

verify:
	bash tests/test-release-ref.sh
	actionlint
