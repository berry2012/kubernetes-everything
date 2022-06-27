
# list installed releases
helm -n <namespace> ls

# uninstall a release
helm -n <namespace> uninstall <NAME>

# to upgrade a release,
helm repo list
helm repo update
helm search repo nginx
helm -n <namespace> upgrade internal-issue-report-apiv2 bitnami/nginx

# Also check out helm rollback for undoing a helm rollout/upgrade

# install a new release, with a customised values setting
helm show values bitnami/apache # will show a long list of all possible value-settings
helm show values bitnami/apache | yq e # parse yaml and show with colors
helm -n <namespace> install internal-issue-report-apache bitnami/apache --set replicaCount=2
# If we would also need to set a value on a deeper level, for example image.debug, we could run:
helm -n <namespace> install internal-issue-report-apache bitnami/apache \
  --set replicaCount=2 \
  --set image.debug=true

# By default releases in pending-upgrade state aren't listed, but we can show all to find and delete the broken release:
helm -n <namespace> ls -a
