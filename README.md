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

Source your bash profile (either `~/.profile` on Debian/Ubuntu or 
`~/.bash_profile` on MacOS/CentOS/Fedora/Red Hat):

```
source ~/.profile # or ~/.bash_profile
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

If I wanted to avoid installing Homebrew for instance, I could run:

```
DISABLE_HOMEBREW=1 ./setup.sh
```

If I just wanted to do some quick editing, maybe I only need my Vim files set 
up. So I can run:

```
ENABLE=1 ENABLE_VIM=1 ./setup.sh
```

where `ENABLE=1` tells the script to only run components that are explicitly 
enabled, and `ENABLE_VIM=1` enables the Vim component.

Repository Overview
--------------------

- [setup.sh](setup.sh): 

- [resources](resources):

- [bash_scripts](bash_scripts):

Components
----------

### Homebrew

### Vim

### C++

### Python
