

## Some simple examples

```sql

select name, guestCpus from google.compute.machine_types where project = 'stackql-demo' and zone = 'australia-southeast1-a';


select name, watchers from github.repos.repos where org = 'stackql' and watchers > 5;



```

## TODO


### Google workspace

It is possible to [set up service account access to admin APIs](https://developers.google.com/workspace/guides/create-credentials#python).  This includes the directory (user) api.


