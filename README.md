# react-native增量更新demo

已经修复对比算法，之前的算法google的对比算法是针对字符串进行比较，当realse版本下jsbundle为压缩后的代码，所有代码都在一行，这时对比会产生异常。现在新算法是基于bsdiff，该算法是对文件二进制进行比较，效率和性能都比之前的要好，目前未测出bug。

diffpatch已经封装完成，在objective-c下可以直接使用

注意：`使用diffpatch要导入libbz2.tbd`

抱歉之前早就做好了，忘记更新。也没有将AutoDiff开源，在创建项目时，选择了本地git，一直没注意，导致工程一直没有被上传。

### 更新日志
2016.3月 热更新验证成功，制作增量包一键生成工具

2016.4月 替换对比算法，弃用谷歌提供的objective-c的算法，使用bsdiff算法基于c语言封装oc接口，目前方案是在开辟子线程在后台检查更新并合并bundle文件，在下次打开app时展示更新。增加patch合成测试

2016.7.6 优化工具使用体验，增加新旧地址路径交换，patch测试时无需修改newBundel文件名，解除对jsbundle上传限制

该工具可以对任何两个文件进行差异化对比并合并

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

