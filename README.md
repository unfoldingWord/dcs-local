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
**a)** Prepare the following files. They already contain default information
    * `source_languages.txt`\
The languages that you need information for, indicated by their [ISO 639-1 2-letter code](https://en.wikipedia.org/wiki/ISO_639-1)

    * `source_metadata_types.txt`\
The types of metadata types you want (rc, sb, ts, tc). Leave empty for all.
        * rc = 
        * sb = Scripture Burrito
        * ts = translationStudio
        * tc = translationCore

    * `source_owners.txt`\
The organizations whose resources you want to load into your local DCS instance.

    * `source_subjects.txt`\
The subjects (resources) you would like to load into your local DCS instance

    **b)** Run the import for source repos\
    `docker exec -it -u git dcs-local /data/scripts/run load_sources`

    This will pull all the sources from the production DCS and load them into your local server.

    **Warning**\
    This script  can be called whenever you want to update your sources locally, **but it will overwrite any repository** that meets the criteria as specified in the `source_*.txt` files.

5) Load the organization for which all the work will be done

    Run the import for target repos\
    `docker exec -it -u git dcs-local /data/scripts/run load_targets <org>`

    **Warning**\
    This will update your local DCS with the indicated organization and its repositories from DCS production. You should only do this initially, or when you know you really want to overwrite your local copy with productions copy.

6) Create users for your target organization

    `docker exec -it -u git dcs-local /data/scripts/run add_users <prefix> <num> <password> <org> <start>`

    * **prefix** - the prefix for each user, which will have a number appended to it. Default: user
    * **num** - the number of users to create. Default: 10
    * **password** - the initial password for all created users. Default: password
    * **org** - the organization of your target repos (imported in step #5) to add your users to. If no organization is given, users will be added but not as members of any organization.
    * **start** - the initial user number. Useful if you already created users and want to add more. Default: 1

7) Upload your target repos to production
    
    Run this to push the master branch of all your target org repos to production\
    `docker exec -it -u git dcs-local /data/scripts/run upload_all_target_repos https://<username>:<password>@git.door43.org`

    You must give a URL to the DCS instance you are pushing to with a username and password that has write access to this org.

    **Warning**\
    If there are conflicts with production, The push will not happen. In that case you will have to manually go into that repo's directory and do a force push.
