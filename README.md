## Aves-ST, 收图浏览
Better than any vault-style photo album app

This app offers enhanced features, flexibility, and convenience for managing and sharing photos, better than any traditional secure photo album apps.

## 1

In real-life scenarios, when sharing photo albums with others:

(1) Static protection against social embarrassment: Only display selected photos/videos.

(2) Dynamic protection against social embarrassment: 
Set different conditions for display scenarios, quickly switch between scenarios, and show only photos or videos that meet the criteria.

(3) Restrictions can be locked or unlocked at any time.

## 2

More convenient and flexible use of personal wallpapers:

Set private photos that might be inappropriate to display publicly as your personal wallpaper and switch to harmless, public-friendly wallpapers (e.g., random landscape photos) whenever needed.

## 3
More efficient image browsing :

Search Assistant: Quickly filter and find suitable images using various criteria.

Copy and share/update to current usage: Easily use images/videos in the "recent files" section of other apps, bypassing their often limited image browsing capabilities.

1、在现实生活中，给他人查看相册内容时：

(1)静态防社死：指定只显示固定选择的图片/视频内容。

(2)动态防社死：指定不同条件限制场景，快速切换场景，只显示符合条件的图片或视频；

(3)可随时锁定解锁限制。

2、更方便大胆地设置任何不方便被他人看到的图片作为私人时间手机壁纸，同时随时切换无害的可当众展示的例如随便什么风景图壁纸。

3、更方便的找图和用图模式，

【查询助手】，使用各种限制，快速筛选合用的图片；

【复制分享/更新于现】，使得更容易在其他软件【最近文件】处直接使用图片/视频，抛开不用其他软件孱弱的图片浏览功能。

## 功能

防社死

1、临时指定,分享图片给好友观看时只显示指定的图片：
Temporarily specify images to share with friends:
Only the designated images will be displayed for viewing.
![001_tmp_assign.png](snap%2F001_tmp_assign.png)


2、自定义场景，例如只允许显示最近3小时内拍摄的照片：

Custom scenarios:

For example, only allow photos taken within the past 3 hours to be shown.

![002_add_scenario.png](snap%2F002_add_scenario.png)


3、等级壁纸，随时切换会让人社死的壁纸设置与不会社死的壁纸设置：

Tiered wallpapers:

Easily switch between socially embarrassing wallpapers and safe, non-embarrassing ones.

![003_level_wallpaper.png](snap%2F003_level_wallpaper.png)


4、复制分享，使想要分享的图片在其它APP中总是显示在最新。在查找图片这点上，图片浏览器总是比其它社交软件的图片查看功能更好用，不是么？

Copy and share:

Ensure that the images you want to share always appear at the top of the "recent files" list in other apps. 

For finding and using images, a dedicated image viewer is always better than the built-in features of most social apps, isn’t it?
![004_share_by_copy.png](snap%2F004_share_by_copy.png)


5、卓面小部件显示横向壁纸，查询助手帮助查看指定条件图片：

Desktop widgets and query assistant:

Display horizontal wallpapers with a widget, and use the query assistant to find images that meet specific criteria.
![005_fgw_widget_and_query_helper.png](snap%2F005_fgw_widget_and_query_helper.png)

## 说明

本项目基于开源项目：
https://github.com/deckerst/aves
修改。
我对原开发者的了解除了帐号名称并不知道更多，所以以上功能可能被添加入原项目也可能不。
除【展示】功能外的bug请联系原开发。


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
# ./flutterw run -t lib/main_play.dart --flavor t4play
```
To make release app:
```
# ./flutterw build apk --flavor t4play -t lib/main_t4play.dart
```

[Version badge]: https://img.shields.io/github/v/release/deckerst/aves?include_prereleases&sort=semver
[Build badge]: https://img.shields.io/github/actions/workflow/status/deckerst/aves/check.yml?branch=develop
