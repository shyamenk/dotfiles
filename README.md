# My dotfiles

This directory contains my dotfiles.

## Requirements

ensure you have the following installed:

### Git

```bash
sudo apt install git

```

### Stow

```bash
sudo apt install stow
```

### Installation

First, check out the dotfiles repo in your $HOME directory:

```bash
git clone git@github.com/shyamenk/dotfiles.git
cd dotfiles
```
then use GNU stow to create symlinks

```bash
stow . 

stow --adopt .
```

