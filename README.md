
# stackql-cloud

`stackql-cloud` is a collection of materials for deployment of `stackql` and `stackql`-supported applications in orchestration systems.

## Manual testing

### Manual testing of stackql

```shell
helm template --release-name v1 --namespace default helm/stackql > helm/stackql/out/stackql-bundle.yaml


## for development on local kube
helm template --release-name v1 --namespace default --set service.type=NodePort helm/stackql > helm/stackql/out/stackql-bundle.yaml

## Then, find local port allocated to stackql node port service
kubectl get svc

## then, you can connect to stackql
psql --host localhost -U stackql -d stackql --port <local port number for stackql node port service>
```

### Manual testing of stackql-dashboard

```shell
helm dependency update helm/stackql-dashboards

helm template --release-name v1 --namespace default helm/stackql-dashboards --set superset.image.tag=latest --set superset.loadExamples=false > helm/stackql-dashboards/out/stackql-dashboards.yaml


## for development on local kube
helm template --release-name v1 --namespace default --set superset.service.type=NodePort --set superset.service.nodePort.http="" helm/stackql-dashboards > helm/stackql-dashboards/out/stackql-dashboards.yaml

## ++secrets, for development on local kube
helm template --release-name v1 --namespace default --set superset.service.type=NodePort --set superset.service.nodePort.http="" --set superset.init.loadExamples=false -f stock/multi-cloud/multi-cloud-values.yaml -f helm/stackql-dashboards/secrets/secret-values.yaml helm/stackql-dashboards > helm/stackql-dashboards/out/stackql-dashboards.yaml


kubectl apply -f helm/stackql-dashboards/out/stackql-dashboards.yaml
```

To bounce on local, **take care not do do against prod**:

```
kubectl delete -f helm/stackql-dashboards/out/stackql-dashboards.yaml

kubectl delete pvc --all
```

### Automating dashboard creation

Locally:

```bash

python bootstrap/bootstrap.py <username> <password> --port=<port>

```

With helm:

```bash

helm template --release-name v1 --namespace default --set dashboardAPI.username="<username>" --set dashboardAPI.password="<password>" helm/superset-primer > helm/superset-primer/out/primer.yaml

```

The whole journey, presuming dashboards template already expanded:

```bash

kubectl apply -f helm/stackql-dashboards/out/stackql-dashboards.yaml

helm template --release-name v1 --namespace default --set dashboardAPI.username="admin" --set dashboardAPI.password="mypassword" helm/superset-primer > helm/superset-primer/out/primer.yaml

kubectl apply -f helm/superset-primer/out/primer.yaml

kubectl delete -f helm/superset-primer/out/primer.yaml

kubectl delete -f helm/superset-primer/out/primer.yaml

kubectl delete pvc --all
```

## Sharing superset dashboards

Dashboards must first be published, then follow [these instructions](https://superset.apache.org/docs/security/).

## Acknowledgements and license

Substantial portions of this work were adapted from Apache-licensed materials, including:

- [bitnami/charts](https://github.com/bitnami/charts).
- [apache/superset](https://github.com/apache/superset).

Please see [the license file](/LICENSE.md).