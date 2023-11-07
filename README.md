# dcs-local

* [Download](https://www.docker.com/get-started/x``) and install Docker
* Edit `source_*.txt` to set what owners, languages, and subjects (resources) to download
* `docker compose pull && docker compose up -d`
* `docker exec -it -u git dcs-local bash /data/scripts/load_sources.sh` ==> NOTE! This can be called whenever you want to update your sources locally, BUT it will clobber and repos that meet the criteria (specified in the `source_*.txt`` files)
* `docker exec -it -u git dcs-local bash /data/scripts/load_target.sh <org>` ==> must be an existing org that you have already set up with gatewayAdmin to have the proper repos to be translated.
* `docker exec -it -u git dcs-local bash /data/scripts/add_users.sh <username prefix> <number of users> <password> <org> <num to start from>`
* `docker exec -it -u git dcs-local bash /data/scripts/upload_all_target_repos.sh https://<username>:<password>@git.door43.org/<org>` ==> Prefix for all git pushes. Must provice your username and password on that server that has push access to all the org's repos.


