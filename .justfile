set dotenv-load

RESET :='\033[0m'
GREEN :='\033[38;5;2m'
RED :='\033[38;5;1m'
YELLOW :='\033[38;5;3m'
BOLD :='\033[1m'
NO_BOLD :='\033[21m'
DIM :='\033[2m'
NO_DIM :='\033[22m'
ITALIC :='\033[3m'
NO_ITALIC :='\033[23m'
STRIKE :='\033[9m'
NO_STRIKE :='\033[29m'
REVERSE :='\033[7m'
NO_REVERSE :='\033[27m'

monorepo := `pwd`
moxy := `pwd` / "moxy"

build_fns := `pwd` / "moxy/utils/build.func"
tests_dir := `pwd` / "moxy/tests"

cmd_runner := `pwd` / "/moxy/moxy/tests/runner.sh"
cmd_info := `pwd` / "moxy/utils//info.sh"

# list all scripts and global ENV variables
default:
    @echo "{{BOLD}}MOXY CLI{{RESET}}"
    @echo "------------------------"
    @echo
    @just --list
    @echo
    @echo "CLI Flags:"
    @echo "  - {{REVERSE}} -v {{RESET}} turns on verbose reporting"
    @echo "  - {{REVERSE}} -f {{RESET}} turns off all interactive prompts"
    @echo "  - {{REVERSE}}--ask{{RESET}} turns off interactive prompts except single yes/no question"
    @echo "    prior to execution"
    @echo ""
    @echo "ENV Variables:"
    @echo "  - there are {{ITALIC}}some{{RESET}} global ENV vars but some are command specific"
    @echo "  - use {{BOLD}}{{GREEN}}info {{NO_BOLD}}<script>{{RESET}} to get all avail ENV variables for a given script"
    @echo "  - you can set ENV variables in a {{GREEN}}.env{{RESET}} file at base of repo"

# get information on a particular script
info SCRIPT:
    @source "{{cmd_info}}"
    fn_info "{{SCRIPT}}"

lint *FILES:
    @MOXY="{{moxy}}" bash -e "{{moxy}}/utils//lint.sh" "{{FILES}}"

test *FILTER:
    @MOXY="{{moxy}}" bash -e "{{moxy}}/tests/runner.sh" "{{FILTER}}"

# create a cloud-init based VM template
create-template *ARGS:
    @MOXY="{{moxy}}" bash -e "{{moxy}}/vm/create-template.sh" "{{ARGS}}"

# create new LXC container with Alpine Linux
ct_alpine:
    @source "{{cmd_runner}}"
    # @MOXY="${PWD}/moxy" && local_runner "ct/alpine.sh"
    @echo Not Implemented Yet

# create new LXC container with Debian Linux
ct_debian:
    @source "{{cmd_runner}}"
    # @MOXY="${PWD}/moxy" && local_runner "ct/alpine.sh"
    @echo Not Implemented Yet
