# GitHub Action to Patch a container image against Log4Shell

[![Build](https://github.com/mgreau/log4shell-cpatch/actions/workflows/test-action.yaml/badge.svg)](https://github.com/mgreau/log4shell-cpatch/actions/workflows/test-action.yaml)

Tool to scan and patch a container image impacted by [Log4Shell](https://www.lunasec.io/docs/blog/log4j-zero-day/
) ([CVE-2021-44228](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-44228).

_WARNING: it is recommended to upgrade your container [to the latest log4j versions](https://search.maven.org/artifact/org.apache.logging.log4j/log4j)_

## Example usage

```yaml
name: Log4shell - Patch and Publish a container image

on:
  push:
    branches: ['main']

jobs:
  publish:
    name: Log4shell - Patch and Publish a container image
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: engineerd/setup-kind@v0.5.0
        with:
          version: "v0.11.1"
      - name: Install Tekton Pipelines
        run: kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.24.1/release.yaml
      - uses: jerop/tkn@v0.1.0

      - name: Patch vulnerable image
        uses: mgreau/log4shell-cpatch@v0.2
        with:
          image: mlinarik/log4j-log4shell-vulnerable-app:latest

```

**That's it!** The process scans the content of the container image, patches any vulnerable JAR files, updates the container image and pushes it to [https://ttl.sh](https://ttl.sh). No "docker build" involved, thanks to `crane`.

### Output logs example
```console
[scan-image : check-jar-files] [INFO] Files to patch:
[scan-image : check-jar-files] /workspace/storage/image_content/app/spring-boot-application.jar
[scan-image : check-jar-files] [INFO] Is the container image affected? 
[scan-image : check-jar-files] yes - found JAR files that need to be patched by removing the JndiLookup.class.

[patch-image : build-patch] [INFO] remove the vulnerable class from detected JARs in-place
[patch-image : build-patch] /workspace/storage/image_content/app/spring-boot-application.jar
[patch-image : build-patch] [INFO] create a tarball file with all the patched JARs
[patch-image : build-patch] /workspace/storage/image_content/app/spring-boot-application.jar

[patch-image : patch-and-push-image] 2022/01/08 02:53:58 pushed blob: sha256:35920a071f912ae4c16897610e8e2d514efcfd0e14ec76c4c73bf9aa7c2c55ea
[patch-image : patch-and-push-image] 2022/01/08 02:53:58 pushed blob: sha256:e3c844e23771b0f749f3a1795cf51ea31a541cf71e9b6f1a4453f32cb3ed22e3
[patch-image : patch-and-push-image] 2022/01/08 02:53:59 pushed blob: sha256:89ee3548903bbcd332a7765f096caa1a59b0590f16390e1b925421690bf7d721
[patch-image : patch-and-push-image] 2022/01/08 02:53:59 pushed blob: sha256:cd784148e3483c2c86c50a48e535302ab0288bebd587accf40b714fffd0646b3
[patch-image : patch-and-push-image] 2022/01/08 02:54:04 pushed blob: sha256:c182a1c16707219422e92cf7025b399e23f0fd6615a87664f60cc9ad53a29ce5
[patch-image : patch-and-push-image] 2022/01/08 02:54:09 pushed blob: sha256:6ab77d92d7f6ee82534a0db0255b897ae563f9f8462453dd506d9193e5ed56ee
[patch-image : patch-and-push-image] 2022/01/08 02:54:24 pushed blob: sha256:f8a5c2c61767e93d1e332a4319f396f39b0dc6b2ee9e4cd2b9d0d5270c82556c
[patch-image : patch-and-push-image] 2022/01/08 02:54:25 ttl.sh/20220108025351:1h: digest: sha256:477040401f74ee41e24c12c50c47d862d357ce15c0a1455079206248b9bf451b size: 1243
[patch-image : patch-and-push-image] ttl.sh/20220108025351:1h
```

It uses the following components:

- [`log4jscanner`](https://github.com/google/log4jscanner) from Google a log4j vulnerability filesystem scanner that can remove the vulnerable class from detected JARs in-place
- [`crane`](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) from Google, a tool for managing container images.
- [https:/ttl.sh]([https:/ttl.sh) to publish the patched image
- [Tekton CD](https://tekton.dev/) to execute the workflows through this GH Action or any Kubernetes cluster tekton-compatible. 
## The Tekton way

The following example shows how to do a quick test locally without the GH Action:

**Note: Tekon Pipelines and CLI need to be installed locally**
```
$ kubectl apply -f tekton/log4shell-cpatch.yaml
$ tkn pipeline start log4shell-cpatch \
	--param image=mgreau/log4shell-cpatch-demo:1.0 \
	--workspace name=storage,volumeClaimTemplateFile=tekton/pvc.yaml --showlog
```
The logs provides the tag from https://ttl.sh where the patched image is pushed, for example:
```
[patch-image : patch-and-push-image] ttl.sh/20220107045528:1h
```

### Quick test using a non-vulnerale image

The default image is set to `alpine` and shows the result when an image is not impacted by Log4shell.
```
$ kubectl apply -f tekton/log4shell-cpatch.yaml
$ tkn pipeline start log4shell-cpatch --workspace name=storage,volumeClaimTemplateFile=tekton/pvc.yaml --showlog --use-param-defaults
```

### Publish to gchr

There is another yaml file to push the patched image to ghcr.io. This is not used by the GitHub action for now.

```bash
$ echo -n ${GH_TOKEN} > ./token
$ kubectl create secret generic ghcr --from-file=./token
$ rm -f ./token
$ kubectl apply -f tekton/log4shell-cpatch-runs.yaml
$ tkn pr logs -f log4shell-cpatch
```
