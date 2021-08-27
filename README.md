# Buildkite agent

A [Buildkite](https://buildkite.com/) agent is described as a build runner process used for automation pipelines. It
essentially polls data from its repository and runs the defined steps specified in the given pipeline.

Documentation for the latest version of Buildkite agent can be found [here](https://buildkite.com/docs/agent).

## Install

This instance is specifically aimed at ```kubernetes```. To start it directly from the host, it should be possible but
minor adjustments need to be made. Therefore, the focus is on ```kubernetes```.

### Kubernetes

Thw ```kubernetes``` resource manifests are found under ```.kustomization/```. A quick installation can be done
this way:

```bash
ENV=dev  # change to prd (production), if applicable
cd .kustomization/
kubectl -k apply overlays/${ENV}/
```

All the services should now be up and running.

For more information on this, check [README.md](.kustomization/README.md) under ```.kustomization/``` directory.

## License

[GPLv3](LICENSE) license
