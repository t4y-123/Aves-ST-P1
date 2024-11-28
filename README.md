## Aves-ST, 收图浏览

比「自带相册/Google相册/绝大多数保险柜or私密相册」更好用本地相册；

比「Wallpaper Engine/小米画报」更合用的静态手机壁纸软件；

免费，开源，全程禁止联网使用即可。

A local album better than "built-in albums/Google Photos/most vault or private albums";

A static mobile wallpaper app more suitable than "Wallpaper Engine/Xiaomi Wallpaper".

Free, open-source,can with no internet usage allowed at most point.


## 功能 Features：

### 1 更好的条件搜索：
文件名，文件类型，文件大小，文件宽高，文件日期，文件至今时长，

文件标签，评分，元数据，指定媒体集，长按反选筛除不需要的特征，

多条件搜索，减轻翻查媒体集的难度。

![f001_search.png](snap%2Fmain_feature_pic%2Ff001_search.png)


### 2 快速固化条件搜索为场景，密码锁定护隐私
假设你大量图片视频不适合公开他人查看，但你又要演示相册所有功能，

可以加个测试限制：只显示有标签tag{test}的图。

如图示，3万张变100张。

比诸多保险箱like私密相册好用了：与其隐藏什么，不如决定只显示什么。

且不会因卸载或清空数据而丢失相册数据。

![f002_scenario_restrictions.png](snap%2Fmain_feature_pic%2Ff002_scenario_restrictions.png)


### 3 临时指定与临时场景，自动密码锁定

当临时需要给别人看几张图，却不希望他乱滑看到不该看的；

【临时指定】自动生成临时标签和临时场景，并锁定，隐藏除选中内容外所有内容；

![f003_tmp_assign_and_tmp_scenario.png](snap%2Fmain_feature_pic%2Ff003_tmp_assign_and_tmp_scenario.png)


### 4 弃用其它软件如微信QQ孱弱的图片浏览功能

在收图浏览中按条件搜索找到图片，

【复制分享】项目至Aves_Copied_For_Share，且更新日期EXIF信息，

简单就能在如微信最近文件处使用，不用额外翻找。

不想复制，旁边就是【直接更新日期，不复制】。

复制项目自动删除，默认删除至回收站，但我习惯手动设为彻底删除。

![f004_weak_image_browsing.png](snap%2Fmain_feature_pic%2Ff004_weak_image_browsing.png)


### 5 等级隐私壁纸通知栏快速切换（可密码锁定）

不同等级设置不同的壁纸，私人时间随便什么壁纸。

无需额外导入文件，几万张几十GB手机图片自由原处随机：

不像小米画报额外存储，50G变100G，100G变200G，这谁用得起？

![f005_privacy_guard_level_wallpaper.png](snap%2Fmain_feature_pic%2Ff005_privacy_guard_level_wallpaper.png)

### 6 壁纸操作：快删除，快分享；

点击进入快速删除不满意的壁纸，释放存储空间，

或快速复制分享，原图分享好看的给朋友；

快速按记录显示被使用过设为壁纸的文件；

【警告：按记录显示，删除直接删除文件！无删除单个记录功能，有清空记录功能】

![f006_01_quick_delete.png](snap%2Fmain_feature_pic%2Ff006_01_quick_delete.png)

![f006_02_quick_copy_share.png](snap%2Fmain_feature_pic%2Ff006_02_quick_copy_share.png)

### 7 为了看横向的壁纸：添加横向桌面工具前台壁纸

（受等级影响显示不同设置图片）

![f007_01_landscape_wallpaper.png](snap%2Fmain_feature_pic%2Ff007_01_landscape_wallpaper.png)

![f007_01_landscape_wallpaper_modify_size.png](snap%2Fmain_feature_pic%2Ff007_01_landscape_wallpaper_modify_size.png)

### 8 Thibault Deckers：视频【按帧前进后退+捕获帧】【4倍速播放】

![f008_01_video_aves.png](snap%2Fmain_feature_pic%2Ff008_01_video_aves.png)

我认为【捕获帧】很可以用来提取视频截屏生成壁纸，所以想提醒下有这个功能。




## 说明

本项目基于开源项目：

https://github.com/deckerst/aves

修改。

我对原开发者的了解除了帐号名称并不知道更多，邮件联系作者了，他说不考虑合并代码。


-----------------------------------
原项目部分说明：

## Features

Aves can handle all sorts of images and videos, including your typical JPEGs and MP4s, but also more exotic things like **multi-page TIFFs, SVGs, old AVIs and more**!

It scans your media collection to identify **motion photos**, **panoramas** (aka photo spheres), **360° videos**, as well as **GeoTIFF** files.

**Navigation and search** is an important part of Aves. The goal is for users to easily flow from albums to photos to tags to maps, etc.

Aves integrates with Android (from KitKat to Android 14, including Android TV) with features such as **widgets**, **app shortcuts**, **screen saver** and **global search** handling. It also works as a **media viewer and picker**.

## Screenshots


## Changelog

The list of changes for past and future releases is available [here](https://github.com/deckerst/aves/blob/develop/CHANGELOG.md).

## Permissions

Aves requires a few permissions to do its job:
- **read contents of shared storage**: the app only accesses media files, and modifying them requires explicit access grants from the user,
- **read locations from media collection**: necessary to display the media coordinates, and to group them by country (via reverse geocoding),
- **have network access**: necessary for the map view, and most likely for precise reverse geocoding too,
- **view network connections**: checking for connection states allows Aves to gracefully degrade features that depend on internet.


## Project Setup（修改适配本项目）

Before running or building the app, update the dependencies for the desired flavor:
```
# scripts/apply_flavor_t4play.sh
```

To build the project, create a file named `<app dir>/android/key.properties`. It should contain a reference to a keystore for app signing, and other necessary credentials. See [key_template.properties](https://github.com/deckerst/aves/blob/develop/android/key_template.properties) for the expected keys.

To run the app:
```
# ./flutterw run -t lib/main_t4play.dart --flavor t4play
```
To make release app:
```
# ./flutterw build apk --flavor t4play -t lib/main_t4play.dart
```

[Version badge]: https://img.shields.io/github/v/release/deckerst/aves?include_prereleases&sort=semver
[Build badge]: https://img.shields.io/github/actions/workflow/status/deckerst/aves/quality-check.yml?branch=develop
