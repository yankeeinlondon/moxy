<style>
.logo: {
    align: center;
}

.warning {
    text-size: 6rem;
    color: red;
}

@media (prefers-color-scheme: dark) {
    .dark {
        display: default;
    }
    .light {
        display: none;
    }
}

</style>

<h1>
    <img class="dark" src="./docs/moxy-dark.png" alt="Moxy Scripts" />
    <img class="light" src="./docs/moxy.png" alt="Moxy Scripts" />
    <span style="display:none">Moxy Scripts</span>
</h1>

> _Please always be cautious and thoroughly evaluate scripts and automation tasks obtained from external sources._

## <span class="warning">WORK IN PROGRESS</span>

This repo is VERY much a work in progress and this README serves more of a design document than the reality of what's ready.

## Functional Ambitions

- **Utility Functions**
  - **Inventory**

    _Allow the discovery and maintenance of a dynamic homelab "inventory" of machines/services/etc spread across them._

  - **Container Creation**

    _Make the creation of VM's and LXC containers more efficient in setup and reuse._

  - **PVE Host Maintenance**

    _Ensure the PVE host is setup in a way that follows best practice or brings greater utility and/or consistency._
- **Different Execution Contexts**
  - **Cut and Paste**
    - The original idea of this repo was to _extend_ the great [Proxmox VE Helper Scripts](https://tteck.github.io/Proxmox/) resource.
    - With this repo the intent is to provide a website where simple cut-and-paste links are downloaded and then run from the PVE host.
    - This means you don't need anything install on your PVE host and you get immediate automation of LXC and VM creation.
    - The downsides here are:
      - providing a set of _userland_ defaults is hard to achieve so you're forced to always run the interactive UI and set to your preferred defaults
      - the project is open-source and the code is on github so you have full visibility into what this script you just cut-and-paste into your terminal will do but there's enough distance that you need be careful to _understand_ before you _execute_. That said, the interactive nature of the script makes tragedy very hard. :)
  - **CLI**
    - This repo intends to preserve the cut-and-paste features while offering the same scripts as a CLI local to your PVE host locally
    - You just:
      - clone this repo onto your PVE host
      - set any ENV variables into a `.env` file that suits your preferences
      - type `just` to get a list of CLI commands available

        > **Note:** you do need the `just` runner but it's available on all major platforms (brew, apt, etc.)

  - **Ansible**
    - I feel more at home with **bash** than I do **ansible** but I've been meaning to change that since watching [Jeff Geerling's great videos and book](https://ansible.jeffgeerling.com/) on ansible
    - The goal is to allow _all scripts_ be able to be executed from a remote host machine (so long as they have SSH access to the PVE host machines)
    - In this environment a user would:
      - clone this repo, set ENV vars (same as for CLI)
      - on executing a common script they would need to require a TARGET host via CLI, ENV variable, or as a fallback a UI question (this assumes a cluster, if a single node then this is not needed)

### Inventory

Being able to dynamically query your Proxmox hosts to _discover_ what containers exist in the homelab is helpful but then to be able to "interact" with this information to provide

### Container Creation

Container creation allows the quick creation of both LXC and VM instances which follow your standards. They functionally fit into this segmentation:

- Bare Bones:
  - Auto generation of CloudInit VM templates for popular distros
  - Auto generation of LXC containers with just base distro installed
- Functional Containers:
  - containers setup to provide a useful feature (e.g., Home Assistant, PiHole, etc.)
  - in some cases allowing the underlying distro be chosen independently of the feature/service which is being provided

### PVE Host Maintenance

- These scripts allow for the creation of a Linux container or virtual machine in an interactive manner, with options for both basic and advanced configurations.
- The basic setup uses default settings, while the advanced setup offers the possibility to modify the settings.
- The options are presented in a dialog box format using the **whiptail** command and the script collects and validates the user's input to generate the final configuration of the container or virtual machine.

## Usage

- **Network Download** - all scripts can be deployed to a Proxmox console by going to the [website](https://tteck.github.io/Proxmox/), choosing a script, and then copying the one-line script to the console:

    ![example site script](./docs/example-site-script.png)

- **Git Clone** - by cloning this repo into a directory on a Proxmox server you have access to the same script choices via the popular [`just`](https://github.com/casey/just) command runner:

    ```sh
    # list all available scripts and ENV vars
    just
    # example: run PVE post install script
    just pve-post-install
    ```

    > **Note:** your Proxmox server will _not_ have `just` installed by default but you can install it with `apt install just`

## Other Resources

- [User Submitted Guides]() - _user submitted guides to installing software which this repo helps to bootstrap with it's scripts_
- [Code Overview]() - _quick overview of key parts of this repo's code/scripts for any future contributors to get a better handle on where things are_

## Contributing

Everybody is invited and welcome to contribute to Proxmox VE Helper Scripts.

- Pull requests submitted against [**main**](https://github.com/tteck/Proxmox/tree/main) are meticulously scrutinized, so please do not take it personally if the project maintainer rejects your request. By adhering to the established patterns and conventions throughout the codebase, you greatly increase the likelihood that your changes will get merged into [**main**](https://github.com/tteck/Proxmox/tree/main).

- It is important to stress that complaining about the decision after it has been made is not productive behavior for the pull request submitter. It is crucial for all contributors to respect the decision-making process and collaborate effectively towards achieving the best possible outcome for the project.

---
> **NOTE:** Proxmox® is a registered trademark of Proxmox Server Solutions GmbH.
