# Code Overview

This section is intended to be a resource for future contributors and highlight key parts of the code base so that you may start becoming productive faster.

If you are considering submitting a PR, please ensure that you understand everything here first before diving in (and definitely before sending in a PR).

## Focus Areas

- [`whiptail`](https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail)
  - this is a provided utility in all modern versions of Debian
  - since Proxmox is _based_ on top of Debian it's also always present on your Proxmox server
  - functionally, it provides a nice text/CLI based UI for interactive engagement with the user.
- **Key Files**
  - `./misc/build.func`
    - provides a lot of support/util functions
    - includes error handling, text colors, but also the core interactive script for base and advanced configuration
  - `./.justfile`
    - this repo had primarily been used in the cut-and-paste of network downloadable scripts found on the [website](https://tteck.github.io/Proxmox/)
    - but with the introduction the `.justfile` at the root of the repo you can now _clone_ the repo and have a convenient means of running those same scripts
    - the syntax for justfile's is well [documented](https://just.systems/man/en/) should you be interested.
- **Directory Structure**
  - `ct` / `vm` directories
    - these directories contain script _entry points_ for the various utilities being provided

- **Utility Structure**
  - all functional utilities should follow a basic structure
  - to start, they must incorporate the shared functions found in `misc/build.func`:

      ```sh
      if [[ -z "${LOCAL_RUNNER}" ]]; then
          source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
      else
          source "${LOCAL_RUNNER}"
      fi
      ```

  - then we must define the following:
    - **header_info** - provides a ASCII art into to the utility
    - **default_values**
    - **
