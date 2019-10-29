# Readme

据说苹果制定了一个小目标：把开发者赶出内核。所以引入一些框架供开发者使用。这些框架主要是针对安全工具的开发。比较关键的有EndpointSecurity。  用这个框架我们可以监控整个系统的文件操作（关闭SIP）。

根据参考博客写了一个小工具。



### Use

用info.plist给project添加entitlement: com.apple.developer.endpoint-security.client  .

`./FileMon   logfile__absolutepath`



### Ref

[https://objective-see.com/blog/blog_0x48.html](https://objective-see.com/blog/blog_0x48.html)

[https://developer.apple.com/documentation/endpointsecurity?changes=latest_major&language=objc](https://developer.apple.com/documentation/endpointsecurity?changes=latest_major&language=objc)


