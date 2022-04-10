# Github Actions dynamic containers

[![Build Containers](https://github.com/tbobm/gha-dynamic-containers/actions/workflows/main.yaml/badge.svg)](https://github.com/tbobm/gha-dynamic-containers/actions/workflows/main.yaml)

Dynamically build containers in a monolithic Github repository and upload them
to [ghcr][ghcr].

[ghcr]: https://github.com/features/packages

## What does this repository do ?

Sometimes, repositories are used to centralize multiple service, either
applications such as microservices or more simply, different application
components.

This repository template allows to dynamically build and publish the
corresponding Container Images (or "Docker Image") to Github's Container
Registry.

Everything it configured in a single Github Actions Workflow located in the
[`./.github/workflows/main.yaml`](./.github/workflows/main.yaml) file.

This is achieved using the following pattern:
1. The `matrix` job (`Generate the matrix`) finds every directory containing
a Dockerfile. It then creates a list of `target` by using the
[`generate_matrix.sh`](./generate_matrix.sh) script and outputs a JSON string
that defines the [matrix strategy][gh-matrix] that will be used downstream.
2. The `check-matrix` (`Validate and display matrix`) job ensure that the
output is using the proper JSON format that can be injected in the Github
Actions Workflow
3. The main course. The `build-containers` job uses the matrix definition
created in the `matrix` job to start N (where N is the number of targets)
parallel jobs that will build each service and upload it to the ghcr repository
matching the current Github Repository. Each image tag is prefixed by a slug
of the used path to automatically apply a naming convention. The current
Github Reference slug is used as the suffix (i.e.: branch, tag)

[gh-matrix]: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix

### Matrix definition

_Note: this can be adapted by modifying the `generate_matrix.sh` script in the
top-level directory of the repository._

Each directory containing a `Dockerfile` is used as a `target`.

Considering that we have 2 targets structured as the following:
```console
$ tree demo/
demo/
├── app1
│   └── Dockerfile
└── app2
    └── Dockerfile
```

We will end up with a matrix with a structure matching the one below:
```yaml
target:
  - src: ./demo/app2
    name: ./demo/app2/Dockerfile
  - src: ./demo/app1
    name: ./demo/app1/Dockerfile
```

It is then exposed as an output in a single-line JSON using [`yq`][yq].

Pretty printed JSON:
```json
{
  "target": [
    {
      "src": "./demo/app2",
      "name": "./demo/app2/Dockerfile"
    },
    {
      "src": "./demo/app1",
      "name": "./demo/app1/Dockerfile"
    }
  ]
}
```

Single-line JSON:
```json
{"target":[{"src":"./demo/app2","name":"./demo/app2/Dockerfile"},{"src":"./demo/app1","name":"./demo/app1/Dockerfile"}]}
```

[yq]: https://mikefarah.gitbook.io/yq/

### Example

This repository includes a `./demo` directory that acts as a dummy
implementation of this Workflow.

Once rendered, the Github Actions Workflow "Build Containers" creates the
following container images when running against the `main` branch:
- `ghcr.io/tbobm/gha-dynamic-containers:demo-app1-main`
- `ghcr.io/tbobm/gha-dynamic-containers:demo-app2-main`

## Matrix injection

Github Actions Workflow can be dynamically adapted using the `fromJson`
function that will inject the string directly in the Workflow.

This is configured in the `build-containers` attribute, as shown below:
```yaml
  build-containers:
    runs-on: "ubuntu-latest"
    name: "Build and push OCIs"
    needs:
      - matrix
    strategy:
      matrix: ${{fromJson(needs.matrix.outputs.matrix)}}
```

Using the `demo` example, we will end up with 2 `build-containers` jobs:
- `./demo/app1`
- `./demo/app2`

Both of them resulting in a different images based on the OCI tag.

Once rendered using the dynamic matrix, the Workflow looks like the following:
```yaml
  build-containers:
    runs-on: "ubuntu-latest"
    name: "Build and push OCIs"
    needs:
      - matrix
    strategy:
      matrix:
        target:
          - src: ./demo/app2
            name: ./demo/app2/Dockerfile
          - src: ./demo/app1
            name: ./demo/app1/Dockerfile
```

## How to use this repository template ?

Simply create your new repository using the `Use this template` button
available in this repository.

Everything is pretty much bootstrapped to work out of the box thanks to
the [github-slug-action][gh-slug-action] that injects the current repository
name as the registry entry in [ghcr][ghcr].

[gh-slug-action]: https://github.com/marketplace/actions/github-slug-action#overview

For more information see [Creating a Repository from a Template][gh-template]
in the Github documentation.

[gh-template]: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template#creating-a-repository-from-a-template

Once done, you can create your own directory structure that will be easy
to use in your existing workflow.

## Sources

- [Dynamic build matrix in GitHub Actions](https://www.cynkra.com/blog/2020-12-23-dynamic-gha/)
