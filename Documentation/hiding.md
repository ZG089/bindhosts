# Hiding Guide

## APatch
 Hiding in APatch is a bit challenging due to the following reasons:
  1. it uses OverlayFS but lacks a built-in unmount mechanism
  2. bind mount is NOT widely adopted

 Recommendations: 
   - [update your APatch](https://nightly.link/bmax121/APatch/workflows/build/main/APatch) and use [ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext)'s enforce denylist
   - for older versions, you can try to use hosts_file_redirect kpm
      - [Usage Tutorial](https://github.com/bindhosts/bindhosts/issues/3), [Download here](https://github.com/AndroidPatch/kpm/releases)
      - NOTE: this workaround is hit-and-miss. I really recommend to just use latest APatch.
   - if hosts_file_redirect fails, install [ZN-hostsredirect](https://github.com/aviraxp/ZN-hostsredirect/releases)

## KernelSU
 Hiding in KernelSU should just work, provided that:
  1. you have path_umount (GKI, backported)
  2. no conflicing modules (e.g. Magical Overlayfs)

 Recommendations:
  - if kernel is non-gki and kernel lacks path_umount, ask kernel dev to [backport this feature](https://github.com/tiann/KernelSU/pull/1464)
  - alternatively, just install [ZN-hostsredirect](https://github.com/aviraxp/ZN-hostsredirect/releases)

### Variants (MKSU, KernelSU-NEXT)
 - For MKSU, you can use [Shamiko](https://github.com/LSPosed/LSPosed.github.io/releases/)
 - For KernelSU-NEXT, hiding will just work (via mode 6)
 
### SuSFS
 - For SuSFS, it should just work

## Magisk
 Hiding in Magisk (and clones, Alpha, Kitsune) should just work as is.
 - Add the apps you want to hide root from to the denylist.
 - optionally you can also use [Shamiko](https://github.com/LSPosed/LSPosed.github.io/releases/)

# FAQ
 - Why is this needed?
   - some root detections now includes and check for modified hosts file.
 - How do I check for detections?
   - Read [how to check for detections](https://github.com/bindhosts/bindhosts/issues/4)
 - How do I move to bind mount on APatch?
   - get ci builds [here](https://nightly.link/bmax121/APatch/workflows/build/main/APatch)

## Glossary of terms
 - bind mount - APatch's term for magic mount, mounting method primarily used by Magisk.

