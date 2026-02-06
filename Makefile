SHELL := /bin/bash

ARGS := $(filter-out add remove,$(MAKECMDGOALS))

.PHONY: add remove $(ARGS)
.SILENT: $(ARGS)

$(ARGS):
	@:

add:
	@PROJ="$$(echo "$(ARGS)" | awk '{print $$1}')"; \
	ENV="$$(echo "$(ARGS)" | awk '{print $$2}')"; \
	if [ -z "$$PROJ" ] || [ -z "$$ENV" ]; then \
		echo "Usage: make add <project> <env-name> [DIR=../<project>-<env-name>]"; \
		exit 1; \
	fi; \
	if [ ! -d "$$PROJ/.git" ]; then \
		echo "Project $$PROJ not found or not a git repo in current directory"; \
		exit 1; \
	fi; \
	FULL_NAME="$$PROJ-$$ENV"; \
	DIR="$(DIR)"; \
	BASE="$$PWD"; \
	if [ -z "$$DIR" ]; then DIR="$$BASE/$$FULL_NAME"; \
	elif [[ "$$DIR" != /* ]]; then DIR="$$BASE/$$DIR"; fi; \
	echo "Creating worktree in $$DIR on branch $$FULL_NAME tracking origin/main"; \
	git -C "$$PROJ" worktree add -b "$$FULL_NAME" "$$DIR" origin/main; \
	( cd "$$DIR" && git branch --set-upstream-to=origin/main "$$FULL_NAME" )

remove:
	@PROJ="$$(echo "$(ARGS)" | awk '{print $$1}')"; \
	ENV="$$(echo "$(ARGS)" | awk '{print $$2}')"; \
	if [ -z "$$PROJ" ] && [ -z "$(DIR)" ]; then \
		echo "Usage: make remove <project> <env-name> [DIR=../<project>-<env-name>] [FORCE=1]"; \
		exit 1; \
	fi; \
	if [ -n "$$PROJ" ] && [ ! -d "$$PROJ/.git" ]; then \
		echo "Project $$PROJ not found or not a git repo in current directory"; \
		exit 1; \
	fi; \
	if [ -n "$$PROJ" ] && [ -n "$$ENV" ]; then FULL_NAME="$$PROJ-$$ENV"; fi; \
	DIR="$(DIR)"; \
	BASE="$$PWD"; \
	if [ -z "$$DIR" ]; then DIR="$$BASE/$$FULL_NAME"; \
	elif [[ "$$DIR" != /* ]]; then DIR="$$BASE/$$DIR"; fi; \
	FORCE_FLAG=""; \
	BRANCH_FLAG="-d"; \
	if [ "$(FORCE)" = "1" ]; then FORCE_FLAG="-f"; BRANCH_FLAG="-D"; fi; \
	if [ -d "$$DIR" ]; then \
		git -C "$$PROJ" worktree remove $$FORCE_FLAG "$$DIR"; \
	else \
		echo "Worktree dir $$DIR not found, skipping remove"; \
	fi; \
	if [ -n "$$FULL_NAME" ]; then \
		git -C "$$PROJ" branch $$BRANCH_FLAG "$$FULL_NAME"; \
	fi; \
	if [ -n "$$PROJ" ]; then git -C "$$PROJ" worktree prune; fi

%:
	@:
