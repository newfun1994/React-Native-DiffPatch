# react-native增量更新demo

`警告:现在使用realse版本下bundle文件对比有问题，正在更换对比算法`

原因:realise版本下生产的jsbundle文件所以代码都在一行，google对比算法无法完成差异对比

1. diffmatchpatch修改版 - diffmatchpatch
2. mac端增量包生成工具 - AutoDiff
3. demo - demo

效果图

![](img/gif.gif)

增量包生成工具

![](img/mac.png)


mac端增量包生成工具免编译版下载地址：<http://newfun1994.github.io/react-native-DiffPatch/AutoDiff.zip>


**热更新可行性验证成功**

## ToDo
具体解决实现方案