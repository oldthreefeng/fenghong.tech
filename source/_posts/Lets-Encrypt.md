---
title: Let’s Encrypt使用
date: 2018-11-08 23:59:32
urlname: https-encrypt
tags: 
- Linux
- nginx
- certbot
- https
categories: server
---

###  **Let’s Encrypt 及 Certbot 简介**

Let’s Encrypt 是 一个叫 [ISRG](https://linuxstory.org/tag/isrg/) （ Internet Security Research Group ，互联网安全研究小组）的组织推出的免费安全证书计划。参与这个计划的组织和公司可以说是互联网顶顶重要的先驱，除了前文提到的三个牛气哄哄的发起单位外，后来又有思科（全球网络设备制造商执牛耳者）、 Akamai 加入，甚至连 Linux 基金会也加入了合作，这些大牌组织的加入保证了这个项目的可信度和可持续性。

![lets-encrypt](https://linuxstory.org/wp-content/uploads/2016/11/lets-encrypt.png)

尽管项目本身以及有该项目签发的证书很可信，但一开始 Let’s Encrypt 的安全证书配置起来比较麻烦，需要手动获取及部署。存在一定的门槛，没有一些技术底子可能比较难搞定。然后有一些网友就自己做了一些脚本来优化和简化部署过程。
**1. 获取 Certbot 客户端**


```
wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
./certbot-auto --help 
```
**2. 配置 nginx 、验证域名所有权**

在虚拟主机配置文件`/usr/local/nginx/conf/vhost/fenghong.tech.conf`中添加如下内容，这一步是为了通过 Let’s Encrypt 的验证，验证 fenghong.tech 这个域名是属于我的管理之下。（具体解释可见下一章“一些补充说明”的“ certbot 的两种工作方式”）

```

location ^~ /.well-known/acme-challenge/ {  
default_type "text/plain";   
root     /www;
} 
location = /.well-known/acme-challenge/ {   
return 404;
} 
```

**3. 重载 nginx**

配置好 [Nginx](https://fenghong.tech/tag/nginx/) 配置文件，重载使修改生效（如果是其他系统 nginx 重载方法可能不同）
```
 sudo nginx -s reload 
```


**4. 生成证书**


```
./certbot-auto certonly --webroot -w /www -d  fenghong.tech 
```

中间会有一些自动运行及安装的软件，不用管，让其自动运行就好，有一步要求输入邮箱地址的提示，照着输入自己的邮箱即可，顺利完成的话，屏幕上会有提示信息。

**此处有坑！如果顺利执行请直接跳到第五步，我在自己的服务器上执行多次都提示**

```
connection :: The server could not connect to the client for DV :: DNS query timed out 
```

发现问题出在 DNS 服务器上，我用的是 DNSpod ，无法通过验证，最后是将域名的 DNS 服务器临时换成 Godaddy 的才解决问题，通过验证，然后再换回原来的 DNSpod 。
证书生成成功后，会有 Congratulations 的提示，并告诉我们证书放在 /etc/letsencrypt/live 这个位置


```
IMPORTANT NOTES:
- Congratulations! Your certificate and chain have been saved at   /etc/letsencrypt/live/fenghong.tech/fullchain.pem. Your cert   will expire on 2019-02-0. To obtain a new version of the   certificate in the future, simply run Let's Encrypt again.
```



**5. 配置 Nginx**（修改 `/usr/local/nginx/conf/vhost/fenghong.tech.conf`），使用 SSL 证书


```
listen 443 ssl;
server_name fenghong.tech www.fenghong.tech;
index index.html index.htm index.php;
root  /www; 
ssl_certificate      /etc/letsencrypt/live/fenghong.tech/fullchain.pem;
ssl_certificate_key  /etc/letsencrypt/live/fenghong.tech/privkey.pem;
```

上面那一段是配置了 https 的访问，我们再添加一段 http 的自动访问跳转，将所有通过 [http://www.fenghong.tech](http://www.fenghong.tech/) 的访问请求自动重定向到 [https://fenghong.tech](https://fenghong.tech/)

```
server {    
	listen 80;    
	server_name fenghong.tech www.fenghong.tech;    
	return 301 https://$server_name$request_uri;
} 
```

**6. 重载 nginx，大功告成，此时打开网站就可以显示绿色小锁了**




```
 sudo nginx -s reload 
```



### **♦后续工作**

出于安全策略， Let’s Encrypt 签发的证书有效期只有 90 天，所以需要每隔三个月就要更新一次安全证书，虽然有点麻烦，但是为了网络安全，这是值得的也是应该的。好在 Certbot 也提供了很方便的更新方法。

1. 测试一下更新，这一步没有在真的更新，只是在调用 Certbot 进行测试

```
./certbot-auto renew --dry-run 
```
如果出现类似的结果，就说明测试成功了（总之有 Congratulations 的字眼）

```
Congratulations, all renewals succeeded. The following certs have been renewed:
  /etc/letsencrypt/live/wiki.fenghong.tech/fullchain.pem (success)
  /etc/letsencrypt/live/fenghong.tech/fullchain.pem (success)
** DRY RUN: simulating 'certbot renew' close to cert expiry
**          (The test certificates above have not been saved.)
```

2. 手动更新的方法

```
./certbot-auto renew -v 
```
3. 自动更新的方法

```
./certbot-auto renew --quiet --no-self-upgrade 

```


### **♦一些补充说明解释**

1、certbot-auto 和 certbot

certbot-auto 和 certbot 本质上是完全一样的；不同之处在于运行 certbot-auto 会自动安装它自己所需要的一些依赖，并且自动更新客户端工具。因此在你使用 certbot-auto 情况下，只需运行在当前目录执行即可

```
./certbot-auto 
```
2、certbot的两种工作方式

certbot （实际上是 certbot-auto ） 有两种方式生成证书：

- **standalone** 方式： certbot 会自己运行一个 web server 来进行验证。如果我们自己的服务器上已经有 web server 正在运行 （比如 Nginx 或 Apache ），用 standalone 方式的话需要先关掉它，以免冲突。
- **webroot** 方式： certbot 会利用既有的 web server，在其 web root目录下创建隐藏文件， Let’s Encrypt 服务端会通过域名来访问这些隐藏文件，以确认你的确拥有对应域名的控制权。

本文用的是 webroot 方式，也只推荐 webroot 方式，这也是前文第二步验证域名所有权在 nginx 虚拟主机配置文件中添加 location 段落内容的原因。
