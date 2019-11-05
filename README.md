# Overview
[Laradock](http://laradock.io/) based docker environment for Wordpress site

# Install

### General

At first clone the repo somewhere on your machine.

In order to run the scripts on Mac or Linux use the terminal, on Windows use [GitBash](https://gitforwindows.org/).

The first step is cover (inject) an existing project / empty folder (of a project that will be implemented in a time) with the scripts.

`./scripts/cover-a-project.sh ~/path/to/your/project`

Then if everything went smoothly get the project directory and place `/.env` file from the example:

`cp ./scripts/.env-example ./scripts/.env`

Notice that if you about set up local environment, before install edit `.env` file. Set `EMIT_LOCAL_SSL=1` to get certs to use `https://localhost`, also change project name, email for emit etc. To turn on possibility of using XDebug, set `XDEBUG=1`. Check out WP version, if you need to install some specific, change it so.

Make sure you have got installed node, npm, git, docker, docker-compose, git bash (for Windows machines) or curl, sed, unzip (for linux/mac, usually preinstalled). And check your Docker is started and has enough resources to run smoothly (disk space at least 10Gb, 4CPU, 2Gb RAM, 1Gb swap)

Useful links: [Docker for Mac](https://download.docker.com/mac/stable/Docker.dmg), [Docker for Windows](https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)

Then make installation:

`./scripts/install-docker-env.sh`

_This script has a list of options:_
* `-n|--no-theme-required` do not require wp-content dir exists
* `-f|--force-reinstall` reinstall, remove laradock folder and perform the whole script again
* `--skip-wp-install` do not download wordpress itself
* `--skip-composer-install` do not run composer install anyway
* `--skip-npm-install` do not run npm install anyway

Issues: 
* if there is no wp-content folder that means no wordpress at all, so you might loss the path but if you don't and it's just new project from scratch try again with -n option.
* if there is laradock directory already exists that means everything has been installed, but if you anyway want to reinstall, try again with option of -f

To start and stop the containers:
`./scripts/start-docker.sh`, 
`./scripts/stop-docker.sh`

_This script `./scripts/start-docker.sh` has a list of options:_
* `--phpmyadmin` run phpmyadmin container

**Actually it won't work without local ssl certs for now because nginx conf expects that certs files. Will fix it**

### Localhost needs more

To allow SSL (if it set on in `.env`) for localhost you have got to add a self-signed root certificate as trusted in your OS. The certificate is placed in project root `certs-local/rootCA.pem`.

Windows, using Google Chrome (seems like on Linux, but didn't check)
* Go to Chrome Settings.
* Click on "advanced settings"
* Under HTTPS/SSL click to "Manage Certificates"
* Go to "Trusted Root Certificate Authorities"
* Click to "Import"
* You probably can’t see `rootCA.pem` because there is a file extension filter, set it as `All files *.*`
* There will be a pop up window that will ask you if you want to install this certificate. Click "yes".

Mac:
* Call Spotlight search and type 'Keychain Access', press Return.
* Choose Category of Certificates
* In top menu go File->Import Items… and pick up the sert (`rootCA.pem`)
* It should appear in the list as ‘<name of project from .env here>’, double click it
* Expand section of Trust and set ‘Always Trust’, close the window, it’s going to require user password
* Exit this app, done

Troubleshooting: make sure ports of 80, 443, 3306 are free on your (host) machine, the docker won’t be able to run the containers if those ports are busy. On Windows machines especially you can face that IIS server is ran, you should stop it 

In a case you keep going first installation, do start the site using a command above and type https://localhost in your browser address line, press Enter/Return.

As it’s the first installation and there is no any DB data and the WP prompts you to make Install, do it: choose English language, for database use next config values:
* database name: `default` 
* database user: `default` , on Windows you might need to type `root`
* password: `secret` , on Windows you might need to type `root`
* host: `mariadb`, on Windows it's `mysql`
* prefix: `_wp` .. actually it's up to you.

Done 

### Xdebug with PHPStorm

![image](https://user-images.githubusercontent.com/1494325/56646188-c435f780-6687-11e9-84d9-0cf69822ea62.png)

<sup>*</sup>Perhaps you should change php-fpm port form 9000 to something else

[Laradock github](https://github.com/laradock/laradock)
