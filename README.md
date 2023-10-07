# dcs-local

* [Download](https://www.docker.com/get-started/) and install Docker
* Edit `source_*.txt` to set what owners, languages, and subjects (resources) to download
* `docker compose pull && docker compuse up -d`
* `docker exec -it dcs-local bash /data/scripts/load_sources.sh` ==> NOTE! This can be called whenever you want to update your sources locally, BUT it will clobber and repos that meet the criteria (specified in the `source_*.txt`` files)
