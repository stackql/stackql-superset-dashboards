
# The 5 minute dashboard

This is a bare bones rundown on deploying a `superset` dashboard for cloud resources, leveraging `stackql`.

## Prerequisites

- `docker desktop` (including local `kubernetes` cluster).
- `helm`.


## Steps

### Setup

From the root directory of this repository:

```bash
helm dependency update helm/stackql-dashboards
```

Create a file with all of the secrets for `superset` admin login and all the various providers that `stackql` will access at `helm/stackql-dashboards/secrets/secret-values.yaml`, for example:

```yaml
stackql:
  extraSecretEnv:
    AWS_ACCESS_KEY_ID: "<as per AWS docs>"
    AWS_SECRET_ACCESS_KEY: "<as per AWS docs>"
    AZURE_CLIENT_ID: "<as per Az docs>"
    AZURE_CLIENT_SECRET: "<as per Az docs>"
    AZURE_TENANT_ID: "<as per Az docs>"
    DIGITALOCEAN_TOKEN: '<self explanatory>'
    STACKQL_GITHUB_USERNAME: '<self explanatory>'
    STACKQL_GITHUB_PASSWORD: '<add your github developer token>'
    STACKQL_K8S_TOKEN: '<add your k8s token>'
    GOOGLE_APPLICATION_CREDENTIALS: '/opt/stackql/config/google-credentials.json'
    GOOGLEADMIN_APPLICATION_CREDENTIALS: '/opt/stackql/config/googleadmin-credentials.json'
  extraSecrets:
    google-credentials.json: |
      {
        ...
      }
    googleadmin-credentials.json: |
      {
        ...
      }

superset:
  init:
    adminUser:
      password: '<create your password for Superset admin user>'
    dbConnections:
      - name: 'StackQL'
        uri: 'postgres://stackql:stackql@v1-stackql:7432/stackql' # not secure and not intended to venture off your local machine; you have the power to change all this... proceed with caution

primer:
  dashboardAPI:
    host: v1-superset # you have the power to change nomenclature... proceed with caution
    port: "8088"
    protocol: http
    username: admin # this is default so not input above
    password: '<same Superset admin password>'

```

To customise your own dashboards, alter the inline view definitions and `jinja` templates inside [stock/multi-cloud/multi-cloud-values.yaml](/stock/multi-cloud/multi-cloud-values.yaml).

### Deploy


```bash
helm template --release-name v1 --namespace default --set superset.service.type=NodePort --set superset.service.nodePort.http="" --set superset.init.loadExamples=false -f stock/multi-cloud/multi-cloud-values.yaml -f helm/stackql-dashboards/secrets/secret-values.yaml helm/stackql-dashboards > helm/stackql-dashboards/out/stackql-dashboards.yaml

kubectl apply -f helm/stackql-dashboards/out/stackql-dashboards.yaml
```

Having done this, check out the local node port with `kubectl get svc`.  And then go to `http://localhost:<your node port>` and enjoy the dashboards.

## Teardown good as new

```bash
kubectl delete -f helm/stackql-dashboards/out/stackql-dashboards.yaml

kubectl delete pvc --all
```
