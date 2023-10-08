

CREATE OR REPLACE VIEW cross_cloud_vms AS 
select 
name, 
split_part(split_part(machineType, '/', 11), '-', 2) as type, 
json_extract_path_text(json_extract_path_text(networkInterfaces, '0'), 'networkIP') as ipAddress
from google.compute.instances 
where project = 'stackql-demo' and zone = 'australia-southeast1-a' 
UNION ALL 
select instanceId as name, 
split_part(instanceType, '.', 2) as type, 
case when ipAddress is null then privateIpAddress else ipAddress end as ipAddress 
from aws.ec2.instances 
where region = 'ap-southeast-2' 
;

CREATE OR REPLACE VIEW cross_cloud_users AS 
select 
'aws' as cloud,
UserName as user_name,
PasswordLastUsed as last_Login_time,
CASE 
  WHEN PasswordLastUsed is null then 'false'
  WHEN PasswordLastUsed = '' then 'false'
  WHEN ( 
  TO_TIMESTAMP(PasswordLastUsed, 'YYYY-MM-DDTHH:MI:SSZ') 
  > (now() - interval '7 days' ) )
 then 'true' else 'false' end as active 
from aws.iam.users 
WHERE 
region = 'us-east-1'
UNION ALL
select 
  'google' as cloud,
  json_extract(name, '$.fullName') as user_name, 
  lastLoginTime as last_Login_time,
  CASE 
  WHEN lastLoginTime is null then 'false'
  WHEN lastLoginTime = '' then 'false'
  WHEN ( 
  TO_TIMESTAMP(lastLoginTime, 'YYYY-MM-DDTHH:MI:SSZ') 
  > (now() - interval '7 days' ) )
 then 'true' else 'false' end as active
from googleadmin.directory.users 
where 
domain = 'ryukit.com'
;


CREATE OR REPLACE VIEW cross_cloud_identities AS 
select 
  aid.UserName as aws_user_name,
  aid.PasswordLastUsed as aws_last_Login_time,
  CASE 
    WHEN aid.PasswordLastUsed = '' then 'false'
    WHEN ( 
    TO_TIMESTAMP(aid.PasswordLastUsed, 'YYYY-MM-DDTHH:MI:SSZ') 
    > (now() - interval '7 days' ) )
    then 'true' 
    else 'false' 
  end as aws_is_active,
  json_extract(gad.name, '$.fullName') as google_user_name, 
  gad.lastLoginTime as google_last_Login_time,
  CASE 
  WHEN gad.lastLoginTime is null then 'false'
  WHEN gad.lastLoginTime = '' then 'false'
  WHEN ( 
  TO_TIMESTAMP(gad.lastLoginTime, 'YYYY-MM-DDTHH:MI:SSZ') 
  > (now() - interval '7 days' ) )
 then 'true' else 'false' end as google_is_active
from aws.iam.users aid
LEFT OUTER JOIN
googleadmin.directory.users gad
ON
lower(substr(aid.UserName, 1, 5)) = lower(substr(json_extract_path_text(gad.name, 'fullName'), 1, 5))
WHERE 
aid.region = 'us-east-1'
AND
gad.domain = 'stackql.io'
;


select 
  aid.UserName as aws_user_name,
  aid.PasswordLastUsed as aws_last_Login_time,
  CASE 
    WHEN aid.PasswordLastUsed = '' then 'false'
    WHEN ( 
    strftime('%Y-%m-%d %H:%M:%SZ', aid.PasswordLastUsed) 
    > ( datetime('now', '-20 days' ) ) )
    then 'true' 
    else 'false' 
  end as aws_is_active,
  json_extract(gad.name, '$.fullName') as google_user_name, 
  gad.lastLoginTime as google_last_Login_time,
  CASE 
  WHEN gad.lastLoginTime is null then 'false'
  WHEN gad.lastLoginTime = '' then 'false'
  WHEN ( 
  strftime('%Y-%m-%d %H:%M:%SZ', gad.lastLoginTime) 
  > ( datetime('now', '-20 days' ) ) )
 then 'true' else 'false' end as google_is_active
from aws.iam.users aid
LEFT OUTER JOIN
googleadmin.directory.users gad
ON
lower(substr(aid.UserName, 1, 5)) = lower(substr(json_extract(gad.name, '$.fullName'), 1, 5))
WHERE 
aid.region = 'us-east-1'
AND
gad.domain = 'ryukit.com'
;

-- sqlite embedded demo 
select 
   aid.UserName as aws_user_name
  ,aid.PasswordLastUsed as aws_last_Login_time
  ,CASE 
    WHEN aid.PasswordLastUsed = '' then 'false' 
    WHEN ( strftime('%Y-%m-%d %H:%M:%SZ', aid.PasswordLastUsed) > ( datetime('now', '-20 days' ) ) ) then 'true' 
    else 'false' end as aws_is_active
  ,json_extract(gad.name, '$.fullName') as google_user_name
  ,gad.lastLoginTime as google_last_Login_time 
  ,CASE 
    WHEN gad.lastLoginTime is null then 'false' 
    WHEN gad.lastLoginTime = '' then 'false' 
    WHEN ( strftime('%Y-%m-%d %H:%M:%SZ', gad.lastLoginTime) > ( datetime('now', '-20 days' ) ) ) then 'true' 
    else 'false' end as google_is_active
  ,lower(substr(json_extract(gad.name, '$.fullName'), 1, 5)) as gcp_fuzz_name
  ,lower(substr(aid.UserName, 1, 5)) as aws_fuzz_name 
from 
  aws.iam.users aid 
  LEFT OUTER JOIN 
  googleadmin.directory.users gad 
  ON lower(substr(aid.UserName, 1, 5)) = lower(substr(json_extract(gad.name, '$.fullName'), 1, 5)) 
WHERE aid.region = 'us-east-1' AND gad.domain = 'stackql.io'
;

select 
   aid.UserName as aws_user_name
  ,lower(substr(aid.UserName, 1, 5)) as aws_fuzz_name 
  ,lower(substr(json_extract(gad.name, '$.fullName'), 1, 5)) as gcp_fuzz_name
from 
  aws.iam.users aid 
  LEFT OUTER JOIN 
  googleadmin.directory.users gad 
  ON lower(substr(aid.UserName, 1, 5)) = lower(substr(json_extract(gad.name, '$.fullName'), 1, 5)) 
WHERE aid.region = 'us-east-1' AND gad.domain = 'grubit.com'
ORDER BY aws_user_name DESC
;

-- Good for a partition chart "Top Level Projects Summary"
select name,
  displayName,
  lower(state) as state,
  case
    when labels is null then 'labelled'
    else 'unlabelled'
  end as has_labels
from google.cloudresourcemanager.projects
where parent = 'organizations/141318256085'
;

-- Good for "Cross Cloud Users" sunset chart
select aid.UserName as aws_user_name,
  aid.PasswordLastUsed as aws_last_Login_time,
  CASE
    WHEN aid.PasswordLastUsed = '' then 'aws inactive'
    WHEN (TO_TIMESTAMP(aid.PasswordLastUsed, 'YYYY-MM-DDTHH:MI:SSZ') > (now() - interval '7 days')) then 'aws active'
    else 'aws inactive'
  end as aws_is_active,
  json_extract(gad.name, '$.fullName') as google_user_name,
  gad.lastLoginTime as google_last_Login_time,
  CASE
    WHEN gad.lastLoginTime is null then 'google non existent'
    WHEN gad.lastLoginTime = '' then 'google non existent'
    WHEN (TO_TIMESTAMP(gad.lastLoginTime, 'YYYY-MM-DDTHH:MI:SSZ') > (now() - interval '7 days')) then 'google active'
    else 'google inactive'
  end as google_status
from aws.iam.users aid
LEFT OUTER JOIN googleadmin.directory.users gad ON lower(substr(aid.UserName, 1, 5)) = lower(substr(json_extract_path_text(gad.name, 'fullName'), 1, 5))
WHERE aid.region = 'us-east-1'
AND gad.domain = 'stackql.io'
;


select 
name, 
lower(split_part(split_part(machineType, '/', 11), '-', 2)) as type, 
lower(status) as status,
CASE 
  WHEN labels is null then 'untagged'
  WHEN labels = '' then 'untagged'
  ELSE 'tagged'
END as isTagged,
json_extract_path_text(json_extract_path_text(networkInterfaces, '0'), 'networkIP') as ipAddress
from google.compute.instances 
where project = 'stackql-demo' and zone = 'australia-southeast1-a' 
UNION ALL 
select instanceId as name, 
split_part(instanceType, '.', 2) as type,  
CASE
  WHEN instanceState like '%stopped%' then 'terminated'
  ELSE instanceState
END as status, 
CASE 
  WHEN tagSet is null then 'untagged'
  WHEN tagSet = '' then 'untagged'
  ELSE 'tagged'
END as isTagged,
case when ipAddress is null then privateIpAddress else ipAddress end as ipAddress 
from aws.ec2.instances 
where region = 'ap-southeast-2' 
;
