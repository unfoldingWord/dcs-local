# DCS local
A local installation of Door43 Content Service (DCS), empowering teams without a proper internet connection to run the full DCS experience on the local network.

# Assumptions
It is assumed that Docker is installed and running. If not, please [go here](https://www.docker.com/get-started/) and follow the instructions.
Make sure that Docker Compose [is installed](https://docs.docker.com/compose/install/) as well. This might be a separate step for your environment. 

# Steps to setup a local DCS server
1) Clone this repo into your local server
```
git clone git@github.com:unfoldingWord/dcs-local.git
```

2) Use Docker Compose to initialize and start the DCS system.
```
docker compose pull
docker compose up -d
```

3) Verify if your local installation is running by going to http://localhost:3000. You should be greeted by the DCS homepage.

4) Pre-load DCS with the information (owners, languages, and subjects (resources)) that you want to be available.\
**a)** Prepare the following files. They already contain default information. Any lines starting with `#` will be ignored.
    * `source_languages.txt`\
The languages that you need information for, indicated by their [ISO 639-1 2-letter code](https://en.wikipedia.org/wiki/ISO_639-1)

    * `source_metadata_types.txt`\
The types of metadat types you want (rc, sb, ts, tc). Leave empty for all.

    * `source_owners.txt`\
The organizations whose resources you want to load into your local DCS instance.

    * `source_subjects.txt`\
The subjects (resources) you would like to load into your local DCS instance

    **b)** Run the import for source repos\
    `docker exec -it -u git dcs-local /data/scripts/run load_sources` 

    This will pull all the sources from the live DCS and load them into your local server.

    **Note and warning**
    This script  can be called whenever you want to update your sources locally, **but it will overwrite any repository** that meets the criteria as specified in the `source_*.txt` files.

5) Load your org which all the work will be done in and users will be added to

    **a)** Run the import for target repos\
    `docker exec -it -u git dcs-local /data/scripts/run load_targets <org>`

    **Note and warning***
    This will update your local copy with the target org on production. You should only do this initially or
    when you know you want to overwrite your local copy with production's copy.

6) Create users for your target org

    **a)** Run the add users for your target org above\
    `docker exec -it -u git dcs-local /data/scripts/run add_users <prefix> <num> <password> <org> <start>`

    * **prefix** - the prefix of each user which will have a number appended to it. Default: user
    * **num** - the number of users to create. Default: 10
    * **password** - the password all users created will have. Default: password
    * **org** - the org of your target repos (imported in step #5) to add your users. If no org, users will not be adde to any org
    * **start** - the number to start at. Useful if you already created users and want to add 10 more. Default: 1\

    Example:\
    `docker exec -it -u git dcs-local /data/scripts/run add_users u 20 mypass`\
    (This will make 20 users with the names u1 to u20 all with the same password of "mypass")

    Note: If you already have users, such as in the above example, but you need to add them to a new org (such as your target org and didn't when you made the users), you can still run add_users and give an org and it will update those existing users:\
    `docker exec -it -u git dcs-local /data/scripts/run add_users u 10 mypass myorg`\
    (Now 10 of the 20 users are in the myorg" org)

7) Upload your target repos to production
    
    **a)** Run this to push the master branch of all your target org repos to production\
    `docker exec -it -u git dcs-local /data/scripts/run upload_all_target_repos https://<username>:<password>@git.door43.org`

    You must give a URL to the DCS instance you are pushing to with a username and password that has write access to this org.

    Note & warning: If there are conflicts with production, it will not push. You will have to manually go into that repo's directory and do a force push.
