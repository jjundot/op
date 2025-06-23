#!/bin/bash
# 添加额外软件源
echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> feeds.conf.default
echo "src-git small https://github.com/kenzok8/small" >> feeds.conf.default
