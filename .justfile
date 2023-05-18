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

base := `pwd`
build_fns := `pwd` / "utils/build.func"
cmd_runner := `pwd` / "utils/local/runner.sh"
cmd_info := `pwd` / "utils/local/info.sh"
cmd_lint := `pwd` / "utils/local/lint.sh"

# list all scripts and global ENV variables
default:
    @echo "{{BOLD}}Proxmox helper scripts{{RESET}}"
    @echo "------------------------"
    @echo
    @just --list
    @echo
    @echo "ENV Variables:"
    
    @echo "  - {{GREEN}}SSH{{RESET}} {{ITALIC}}allows setting a default value for new containers:"
    @echo "      [ {{DIM}}no{{NO_DIM}}, {{DIM}}password{{NO_DIM}}, {{DIM}}crypto{{NO_DIM}}, {{DIM}}crypto-and-password{{NO_DIM}} ]{{RESET}}"

    @echo "  - {{GREEN}}AUTHORIZED_KEYS{{RESET}} - {{ITALIC}}allows adding a set of SSH keys which will be added to "
    @echo "    any new container (if SSH is enabled in some form){{RESET}}"

    @echo "  - {{GREEN}}FORCE{{RESET}} - {{ITALIC}}changes the interactive script into a fully automated one which"
    @echo "    accepts all defaults (with ENV vars overriding){{RESET}}"
    @echo
    @echo "{{BOLD}}Note:{{RESET}}"
    @echo "  - you can set ENV variables in a {{GREEN}}.env{{RESET}} file at base of repo"
    @echo "  - the {{GREEN}}.gitignore{{RESET}} in the repo ensures {{ITALIC}}your settings{{RESET}} will not bleed into repo"
    @echo "  - use {{BOLD}}{{GREEN}}info {{NO_BOLD}}<script>{{RESET}} to get all avail ENV variables for a given script"

# get information on a particular script
info SCRIPT:
    @source "{{cmd_info}}"
    fn_info "{{SCRIPT}}"

lint *FILES:
    @eval "{{cmd_lint}} {{base}} {{FILES}}"

test *FILTER:
    @bash -e "{{base}}/tests/runner.sh" "{{FILTER}}"

# create new LXC container with Alpine Linux
ct_alpine:
    @source "{{cmd_runner}}"
    local_runner "ct/alpine.sh" "{{base}}"

# create new LXC container with Debian Linux
ct_debian:
    @source "{{cmd_runner}}"
    local_runner "ct/alpine.sh" "{{base}}"
