.PHONY: verify

verify:
	bash tests/test-contract.sh
	actionlint
