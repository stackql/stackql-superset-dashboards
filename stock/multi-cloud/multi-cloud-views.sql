

CREATE VIEW cross_cloud_vms AS 
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