# Job automation in R

### Schema 

download data > prepare summary > send e-mail

### How to use it?

Complete the configuration file: `scripts/config` and run this code:

```sh
docker build -t job-automation .
docker run --rm job-automation
```

Sources: [PL](http://www.worksmarter.pl/post/job-automation-r-1) | [EN](http://www.worksmarter.pl/en/post/job-automation-r-1)