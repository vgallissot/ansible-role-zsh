Role Name
=========
[![license][2i]][2p]

Installs zsh with [oh-my-zsh][4] for all users.
Allows user-wide customizations too.

Description
-----------

Nothing too fancy. I tend to use zsh for **everything** under the sun. As such, the first darn thing to install on my provisions is usually that with a small update to the plugins I use. This is just that.

Role Variables
--------------

| Name  | Default  | Mandatory  | Description  |
| :---- |:--------:|:----------:|:------------ |
| zsh_users | `root` | yes | List of users to whom this role will apply |
| zsh_custom | `~/.zsh.d` | yes | Path to user's custom zsh directory |
| zsh_omz_path | `/usr/local/src/oh-my-zsh` | yes | Path where oh-my-zsh will be git cloned |
| zsh_omz_zshrc | `/etc/oh-my-zsh.zshrc` | yes | Path from whom ~/.zshrc will be linked to for all zsh users |


Usage
-----

Any of variables above is customizable.  
You may only need to modify zsh_users list.

``` yaml
- hosts: localhost

  vars:
    zsh_users:
      - pi

  roles:
    - zsh
```

Author Information
------------------

Fork of Alejandro Baez's repo

[2i]: https://img.shields.io/badge/license-BSD_2-green.svg
[2p]: ./LICENSE
[4]: https://github.com/robbyrussell/oh-my-zsh
