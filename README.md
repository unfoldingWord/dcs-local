# DCS local
A local installation of Door43 Content Service (DCS), empowering teams without a proper internet connection to have the full DCS experience on the local network.

# Used terms
**Remote DCS** - the DCS server residing on the internet. This would normally be the server behind the `git.door43.org` URL, but can be other DCS servers such as `qa.door43.org`.

**Source language** - language that functions as a source for translation work. These need to have releases which are in the catalog. These will be added to your local DCS's catalog.

**Source organization** - the organization that functions as the source for all translation work. This can be for example `unfoldingWord`. If the app you're using to translate supports other orgs, you can add them as well (see loading sources below)

**Source repository** - a repository that holds sources used as reference for translation

**Target language** - language that is being translated into which you and your team are working on

**Target organization** - your team's DCS organization, in which all the translation work will be done. This should exist on the remote DCS and will be synced to your local DCS

**Target repository** - a repository that holds translated resources

# Overview
To setup a local DCS server, a couple of steps are needed

1) Download all resources of the needed source language from one or more organizations from the remote DCS
2) Download all the repositories for the target language organization as set up by gatewayAdmin on the remote DCS (these repositories may or may not already have been worked on, but should be set up to the point your desired app can work with them)
3) Create local users which need to belong to the local target organization, to be able to work locally. These users do not need to exist on the remote DCS

Furthermore, the local DCS server has the following capabilities
1) Update the source repositories from the remote DCS
2) Update the target repositories from the remote DCS
3) Push all local changes in the local target organizations repositories back to the remote DCS

# Prerequisites
It is assumed that Docker is installed and running. If not, please [go here](https://www.docker.com/get-started/) and follow the instructions.
Make sure that Docker Compose [is installed](https://docs.docker.com/compose/install/) as well. This might be a separate step for your environment. 

The availability of [git](https://git-scm.com/download) is also needed. 

This setup also assumes that the organization that is being worked in has already been created on the remote DCS server.

# Steps to setup a local DCS server

1. Clone this repository into your local server
    ```
    git clone git@github.com:unfoldingWord/dcs-local.git
    ```

1. Set up URL and your credentials (auth token) for the remote DCS and that can access the target language org, reading and writing:\
    1. In the `dcs-local` directory, copy the `settings.sh-example` file to `settings.sh`\
        ```
        cp settings.sh-example settings.sh
        ```
    1. OPTIONAL: Edit the `settings.sh` file and change the REMOTE_DCS_URL if you do not want to use `git.door43.org`
    1. In your browser, go to the URL for the remote DCS you used and log in and from the user menu at the top right, go to Settings -> Application. Generate a token with repo read and write access. (See [screenshot](readme/create_token.png) for an example of setting up
    a token)
    1. After you click "Generate Token" you will be shown the token. Copy and paste the string of characters into value of the `REMOTE_DCS_TOKEN=` variable in the `dcs-connections.sh`. Save the file.

1. OPTIONAL: Change the username and password for the local admin user in the `settings.sh` file. Defaults are username `root` and password `password`

1. OPTIONAL: If you cannot or don't want to run DCS on port 3000 of your machine, edit the `docker-compose.yml` file and change the FIRST "3000" in "3000:3000" of the ports property to your desired port

1. Use Docker Compose to initialize and start the DCS system
    ```
    docker compose pull
    docker compose up -d
    ```


1. Create the admin user as the first user using the username and password in the `settings.sh` you created above. Run the following to create your admin user:
    ```
    docker exec -it -u git dcs-local /data/scripts/run create_admin_user
    ```
    _**Note:** If you change the passowrd for root within your local copy of DCS, be sure to also change it in the `settings.sh` file, otherwise it will be reset to what is in the settings file when you run other admin commands_

1. Verify if your local installation is running:
    1. Go to http://localhost:3000 (change the port if you changed it above). You should be greeted by the DCS homepage.\
    _**Note:** If you get a 'Connection reset' warning, please wait a minute and try again._\
    2. Click on the [Sign in](http://localhost:3000/user/login) link at the top right of the screen, and log in as admin using the credentials in your `settings.sh` file\
    Defaults:\
    User: `root`\
    Password: `password`\
    _(These credentials have been initially configured in the `settings.sh` file)_


1. Pre-load DCS with the information (owners, languages, and subjects (resources)) that you want to be available.

    **a)** Prepare the following files. They already contain default information.
    * `source_languages.txt`\
    The languages that you need resources for, indicated by their [ISO 639-1 2-letter code](https://en.wikipedia.org/wiki/ISO_639-1). Suggested languages:
        * en (English)
        * hbo (Hebrew)
        * el-x-koine (Greek)

    * `source_metadata_types.txt`\
    The types of metadata you want (rc, sb, ts, tc). Leave empty for all.
        * rc = Resource Container (Suggested)
        * sb = Scripture Burrito
        * ts = translationStudio
        * tc = translationCore

    * `source_owners.txt`\
    The organizations whose resources you want to load into your local DCS instance. Suggested orgs:
        * unfoldingWord

    * `source_subjects.txt`\
    The subjects (resources) you would like to load into your local DCS instance. File contains all suggested subjects, but tailer to what you will be translating.\
    _**Note:** that some may depend on others, like `Translation Words` depends on `TSV Translation Words Links`)_

    **b)** Run the import for source repositories
    ```
    docker exec -it -u git dcs-local /data/scripts/run load_sources
    ```
    
    This will pull all the sources you just defined from the production DCS and load them into your local server. This process will take a while...

    **Warning**\
    This script  can be called whenever you want to update your sources locally, **but it will overwrite any repository** that meets the criteria as specified in the `source_*.txt` files.

    You can verify if the import was succesful by going to http://localhost/catalog. 

1. Load the organization and its repositories in which all the work will be done.

    Run the import for target repositories
    ```
    docker exec -it -u git dcs-local /data/scripts/run load_targets <org>
    ```

    **Warning**\
    This will update your local DCS with the indicated organization and its repositories from DCS production. You should only do this initially, or when you know you really want to overwrite your local copy with the copy from production.

1. Create local users for your target organization
    ```
    docker exec -it -u git dcs-local /data/scripts/run add_users <prefix> <num> <password> <org> <start>
    ```

    * **prefix** - the prefix for each user, which will have a number appended to it. Default: user
    * **num** - the number of users to create. Default: 10
    * **password** - the initial password for all created users. Default: password
    * **org** - the organization of your target repositories (imported in step #5) to add your users to. If no organization is given, users will be added but not as members of any organization.
    * **start** - the initial user number. Useful if you already created users and want to add more. Default: 1

    **Example:**
    ```
    docker exec -it -u git dcs-local /data/scripts/run add_users u 20 mypass
    ```
    
    This will create 20 users with the names u1 through u20, all with the same password of "mypass"

    **Example 2:**\
    If you already created users, such as in the above example, but you need to add them to a new organization (such as your target organization), you can still run `add_users` and give the target organization and it will update those existing users:
    ```
    docker exec -it -u git dcs-local /data/scripts/run add_users u 10 mypass myorg`
    ```
    Now 10 of the 20 users that we created in the first example are moved into the "myorg" organization.

# Upload your target repositories to production
    
Run this to push the master branch of all your target organizations repositories to production
```
docker exec -it -u git dcs-local /data/scripts/run upload_all_target_repos https://<username>:<password>@git.door43.org
```

You must give a URL to the DCS instance you are pushing to with a username and password that has write access to this organization.

**Warning**\
If there are conflicts with production, the push will not happen. In that case you will have to manually go into that repo's directory and do a force push.