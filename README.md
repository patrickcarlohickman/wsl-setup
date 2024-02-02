# wsl-setup

[![Software License][ico-license]](LICENSE.txt)

This repository includes a set of scripts useful for installing and configuring an initial set of tooling for PHP development on WSL using Ubuntu.

## Usage

1. Enable WSL on Windows.
2. Install Ubuntu for WSL.
3. Start Ubuntu to initialize it and setup your WSL user.
4. Clone the repo.
    - `git clone https://github.com/patrickcarlohickman/wsl-setup.git`
5. Go to the `setup` directory.
    - `cd wsl-setup/setup`
6. Copy `.env.example` to `.env`.
    - `cp .env.example .env`
7. Update the `.env` values.
8. Go through the files in the `resources` directories and update them with your information.
9. Run `sudo -i $HOME/wsl-setup/setup/setup-wsl.sh`. This will take a while to run.
10. Exit WSL and reconnect, or just start a new shell with `exec $SHELL -l`.
11. Run `startup` to ensure all your services are up and running.
12. Copy the scripts in the `bin` directory to somewhere on the Windows host machine.

## What does it do?

1. Upgrades the Ubuntu distribution.
2. Installs a `wsl.conf` file to enable filesystem metadata.
3. Sets the system timezone.
4. Installs a startup script to start desired services (ex: apache, mysql, redis).
5. Installs a sudoers file to allow the startup script to be run by the wsl user.
6. Installs default user files to setup bash aliases, git configuration, git ignore, and a git commit message template.
7. Creates new SSH keys or copies SSH keys from Windows host.
8. Installs initial software.
    - phpenv
    - PHP (version set in .env)
    - Apache
    - MySQL 5.7
    - Redis
    - Composer
    - NVM
    - Yarn
    - Ngrok
    - FreeTDS

## Startup

There is a startup script installed at `/usr/local/bin/startup.sh` that is used to start up all the services (apache, mysql, redis, php-fpm, etc.). There is also a `startup` alias defined that runs this script as sudo. When you connect to your WSL instance, just run `startup` and it will (re)start all the services.

## MySQL

The `setup/resources/mysql/create-databases-mysql.sh` script is available to create databases in MySQL. It reads from the `create-databases-mysql.sql` file in the same directory. To add new databases, just update `setup/resources/mysql/create-databases-mysql.sql` and run the `setup/resources/mysql/create-databases-mysql.sh` script.

## PHP

This setup is designed to allow multiple versions of PHP running at the same time. This is done through [phpenv](https://github.com/phpenv/phpenv). While you can use phpenv directly to install new versions of PHP, it is better to use the install script at `setup/resources/php/install-php.sh`. This script will:

- Automatically resolve certain build issues with building older versions of PHP (older dependencies, expecting files in certain locations, etc.)
- Setup a new PHP log file for the version installed
- Configure the PHP-FPM user and listener
- Install the PHP-FPM service script

## Enable new websites

When you setup a new website in your vhost directory (`/var/www/vhost` or the value specified in the `VHOST_DIRECTORY` variable in the `.env` file), you'll need a new apache config file for the new website. To set this up, use the site install script at `setups/resources/apache/make-site.sh`. This script will:

- Create a new apache site config file at `/etc/apache2/sites-available`. This config file will:
    - Enable a new virtual host for `your-domain.test` and `www.your-domain.test`
    - Enable http and https
    - Configure the site to use the PHP version specified
    - Configure new error and access logs for the site
    - Add a forwarding host fix for ngrok
- Add the new site to the ngrok config file
- Generate the openssl private key if one doesn't exist
- (Re)generate the openssl self-signed cert with the new site added

Usage: `make-site.sh < domain > < php_version > [ directory [ ngrok_start_name ] ]`

Notes:

- The script assumes the document root directory is at `<domain>/public`. If that is not the document root, specify the directory using the third parameter.
- The ngrok start name defaults to the domain. Use the fourth parameter to change this.
- Make sure to remember to update the host computer hosts file to access the new website at the new domain (`bin/add-host.bat` helps with this).
- If using https, the SSL cert is self-signed, so the browser will complain about it, but you should be able to click through.

## Windows Scripts

There are a couple useful helper scripts for Windows located in the `bin` directory. These are meant to be run from the Windows host machine, so they will need to be copied somewhere onto the Windows host machine. Ex: `cp -r bin /mnt/c/WSL`

- `update-hosts-ips.bat`
    - With WSL2, you cannot access the domains hosted on the WSL machine using the loopback address (127.0.0.1) in the Windows hosts file. The Windows hosts file will need to be kept up-to-date with the IP address of the WSL machine.
    - This script will get the current WSL IP address and update the hosts file with it for any host under the `.test` TLD.
- `add-host.bat`
    - When you add a new site inside of WSL, you'll need to add a new hosts entry in the Windows hosts file to point to the new site.
    - This script will prompt for the new host name and add it to the end of the Windows hosts file with the WSL IP address already assigned.

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
