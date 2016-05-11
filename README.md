# react-native增量更新demo

已经修复对比算法，之前的算法google的对比算法是针对字符串进行比较，当realse版本下jsbundle为压缩后的代码，所有代码都在一行，这时对比会产生异常。现在新算法是基于bsdiff，该算法是对文件二进制进行比较，效率和性能都比之前的要好，目前未测出bug。

diffpatch已经封装完成，在objective-c下可以直接使用

注意：`使用diffpatch要导入libbz2.tbd`

1. diffmatchpatch修改版（弃用） - diffmatchpatch
2. mac端增量包生成工具 - AutoDiff
3. demo - demo
4. diffpatch封装版 - diffpatch

效果图

![](img/gif.gif)

增量包生成工具

![](img/mac.png)


mac端增量包生成工具免编译版下载地址：<http://newfun1994.github.io/react-native-DiffPatch/AutoDiff.zip>


**热更新可行性验证成功**

## ToDo
具体解决实现方案