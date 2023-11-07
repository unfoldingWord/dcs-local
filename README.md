# DCS local
A local installation of Door43 Content Service (DCS), empowering teams without Internet connection

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

4) Pre-load DCS with the information (owners, languages, and subjects (resources)) that you want to be available.
a) Prepare the following files. They already contain default information
* source_languages.txt
The languages that you need information for, indicated by their [ISO 639-1 2-letter code](https://en.wikipedia.org/wiki/ISO_639-1)

* source_metadata_types.txt
?

* source_owners.txt
The organizations whose resources you want to load into your local DCS instance

* source_subjects.txt
The subjects (resources) you would like to load into your local DCS instance

b) Run the import
* `docker exec -it dcs-local bash /data/scripts/load_sources.sh` 

This will pull all the sources from the live DCS and load them into your local server.

**Note and warning**
This script  can be called whenever you want to update your sources locally, **but it will overwrite any repository** that meets the criteria as specified in the `source_*.txt` files.

