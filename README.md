machine-setup
=============

Sets up a machine environment from a clean install.

I end up on new machines all the time and need to reinstall the same things 
over again, copy settings files, etc. This repo is my solution. Everything 
here is my personal files and preferences, so you may not want to use them 
(though I think my Vim setup is pretty nice!). That being said, you may still 
find this repo useful to co-opt for your own purposes or as an example of 
various things (like a great [.vimrc](resources/vim/.vimrc) file!).

To run it, you need to get the repository over to the machine, most of which 
come with `git` preinstalled:

```
git clone https://github.com/jeremyephron/machine-setup
```

Navigate to the repository:

```
cd machine-setup
```

Run the setup script:

```
./setup.sh
```

Source your bashrc and bash profile (either `~/.profile` on Debian/Ubuntu or 
`~/.bash_profile` on MacOS/CentOS/Fedora/Red Hat; this command covers both):

```
source ~/.bashrc
(test -r ~/.bash_profile && source ~/.bash_profile) || source ~/.profile
```

Now, you can delete the repository, and you're good to go:

```
cd .. && rm -rf machine-setup
```

Configuring the Setup
---------------------

This setup script installs a lot of stuff that I may not want all the time.
For this reason you can disable specific components or enable only the 
components you need.

If I wanted to avoid installing LaTeX for instance, I could run:

```
DISABLE_LATEX=1 ./setup.sh
```

If I just wanted to do some quick editing, maybe I only need my Vim files set 
up. So I can run:

```
ENABLE=1 ENABLE_VIM=1 ./setup.sh
```

where `ENABLE=1` tells the script to only run components that are explicitly 
enabled, and `ENABLE_VIM=1` enables the Vim component.

Alternatively, you can run the setup in interactive mode, where it will ask 
you to confirm whether each component should run:

```
INTERACTIVE=1 ./setup.sh
```

Repository Overview
--------------------

Here's an overview of important files or directories:

- [setup.sh](setup.sh): the main setup script

- [resources](resources): directory containing any files that need to copied

- [bash_scripts](bash_scripts): directory containing the defined behavior for 
each of the components

Components
----------

### Homebrew

[Homebrew](https://brew.sh/) is my favorite package manager for Mac or Linux, 
and is required to install many of the other components.

### Vim

[Vim](https://www.vim.org/) is my goto editor, and it will install the latest 
version with `brew`. Additionally, it configures a 
[.vimrc](resources/vim/.vimrc) file along with a colorscheme and other 
vim settings files viewable in [](resources/vim/).

### FZF

[FZF](https://github.com/junegunn/fzf) is a fuzzy file searcher that 
dramatically enhances your command line experience, and the Vim component 
includes it as a plugin (separate from this component).

### tree

Just your standard `tree` command to recursively list directories.

### Git

I prefer having the latest version of [Git](https://git-scm.com/) installed 
with `brew`.

### nnn

[nnn](https://github.com/jarun/nnn) is a very powerful terminal file manager 
that helps you get around more efficiently.

### LateX

[LaTeX](https://www.latex-project.org/) is a typesetting system mostly used 
for academic and scientific work. This component installs the
[Tex Live](https://www.tug.org/texlive/) distribution on Linux and
[MacTeX](https://www.tug.org/mactex/) on MacOS.

### Python

Installs the latest version of [Python](https://www.python.org/) with `brew`.
Also installs [`pyenv`](https://github.com/pyenv/pyenv), which I use for 
Python version management.

### NodeJS

Installs [NodeJS](https://nodejs.org/en/) and [Yarn](https://yarnpkg.com/) for 
package management.

### Java

Installs [OpenJDK](https://openjdk.java.net/).

### Rust

Installs [rustup](https://rustup.rs/) with `brew`, and then installs 
[Rust](https://www.rust-lang.org/) with `rustup`.

### Boost

The [Boost](https://www.boost.org/) C++ libraries are a great extension to the 
STL.

### Python Packages

Installs various Python packages that I like to have installed globally on my 
system, including:

- `setuptools`
- `twine`
- `numpy`
- `scikit-learn`
- `matplotlib`
- `pandas`
- `jupyter`
- `requests`
- `pillow`
- `beautifulsoup4`
