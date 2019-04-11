# node-static-build

Scripts for generating static linked nodejs binaries for n3h releases

### Usage

To locally build the full suite, you should first install some deps:

- docker
- qemu-user-static
- pxz

Then, run:

```
TGT_ARCH=x64 ./step1-build-docker-image.bash
TGT_ARCH=x64 ./step2-node-static-build.bash
TGT_ARCH=ia32 ./step1-build-docker-image.bash
TGT_ARCH=ia32 ./step2-node-static-build.bash
TGT_ARCH=armv7l ./step1-build-docker-image.bash
TGT_ARCH=armv7l ./step2-node-static-build.bash
TGT_ARCH=arm64 ./step1-build-docker-image.bash
TGT_ARCH=arm64 ./step2-node-static-build.bash
```
