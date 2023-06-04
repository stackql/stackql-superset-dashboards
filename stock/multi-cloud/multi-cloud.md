

## Some simple examples

```sql

select name, guestCpus from google.compute.machine_types where project = 'stackql-demo' and zone = 'australia-southeast1-a';


select name, watchers from github.repos.repos where org = 'stackql' and watchers > 5;



```

## TODO

We probably want to get some more parser support for pg stuff such as interval, eg this does not currently work:

```sql
select 
UserName, 
PasswordLastUsed, 
CASE WHEN ( TO_TIMESTAMP(PasswordLastUsed, 'YYYY-MM-DDTHH:MI:SSZ') > (now() - interval '7 days' ) ) then true else false end as inactive
from aws.iam.users WHERE region = 'us-east-1' and PasswordLastUsed is not null;
```