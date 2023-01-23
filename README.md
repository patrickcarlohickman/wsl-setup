# wsl-setup

[![Software License][ico-license]](LICENSE.txt)

This repository includes a set of scripts useful for installing and configuring an initial set of tooling for PHP development on WSL using Ubuntu.

## Usage

1. Enable WSL on Windows.
2. Install Ubuntu for WSL.
3. Start Ubuntu to initialize it and setup your WSL user.
4. Clone the repo.
5. Go to the `setup` directory.
6. Copy `.env.example` to `.env` and update the values inside.
7. Go through the files in the `resources` directories and update them with your information. Required:
    - `resources/bash/user/.gitconfig`
    - `resources/wsl/wsl-sudoers`
8. Run `setup-wsl.sh`.

## What does it do?

1. Upgrades the Ubuntu distribution.
2. Installs a `wsl.conf` file to enable filesystem metadata.
3. Sets the system timezone.
4. Installs a startup script to start desired services (ex: apache, mysql, redis).
5. Installs a sudoers file to allow the startup script to be run by the wsl user.
6. Installs default user files to setup bash aliases, git configuration, git ignore, and a git commit message template.
7. Creates new SSH keys or copies SSH keys from Windows host.
8. Installs initial software.
    - PHP 7.2
    - Apache
    - MySQL 5.7
    - Redis
    - Composer
    - NVM
    - Ngrok
    - FreeTDS

## MySQL

`setup/resources/mysql/create-databases-mysql.sh` is available to create databases in MySQL. It reads from the `create-databases-mysql.sql` file in the same directory. To add new databases, just update `create-databases-mysql.sql` and run the `create-databases-mysql.sh` script.

## Notes

Ignore `wsl-setup.bat`. That was the start of attempting to install WSL from scratch and allow multiple WSL instances on one host machine, each with different software setups. Very early, and probably won't get much more attention. I think if you want to go that way, may as well use Docker.

## Contributing

Contributions are welcome. Please see [CONTRIBUTING](CONTRIBUTING.md) for details.

## Credits

- [Patrick Carlo-Hickman][link-author]
- [All Contributors][link-contributors]

## License

The MIT License (MIT). Please see [License File](LICENSE.txt) for more information.

[ico-license]: https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[link-author]: https://github.com/patrickcarlohickman
[link-contributors]: ../../contributors
