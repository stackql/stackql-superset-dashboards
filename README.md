
# stackql-cloud

`stackql-cloud` is a collection of materials for deployment of `stackql` and `stackql`-supported applications in orchestration systems.

## Manual testing

```shell
helm template --release-name v1 --namespace default helm/stackql > helm/stackql/out/stackql-bundle.yaml


```

## Acknowledgements and license

Substantial portions of this work were adapted from Apache-licensed materials, including:

- [bitnami/charts](https://github.com/bitnami/charts).
- [apache/superset](https://github.com/apache/superset).

Please see [the license file](/LICENSE.md).