# ceph内网编译

此文档针对 `v12.2.5` 版本

## 准备条件

* yum源

手动配置内网同步的 epel 和 base 源 ，禁止 `install-dep.sh` 安装epel 源


* pip源

安装 `install-dep.sh`的逻辑，在内部的pip源中，准备所有的依赖包

```shell
for i in `find ${ceph_base} -name "*requirements.txt"`;do cat $i;done|sort|uniq > req.txt

```


```
configobj
coverage==3.6
discover
-e git+https://github.com/ceph/sphinx-ditaa.git@py3#egg=sphinx-ditaa
-e git+https://github.com/michaeljones/breathe#egg=breathe
fixtures>=0.3.14
flake8==3.0.4
mock
pytest
python-subunit
Sphinx==1.6.3
testrepository>=0.0.17
testtools>=0.9.32
tox>=2.0
pip
wheel
virtualenv
setuptools<36,>=0.8

```

python3补充
```
more-itertools>=4.0.0
pluggy<0.8,>=0.5
```

* boost依赖

在内网的apache目录准备boost源码包

```shell
http_base=/var/www/ceph-dep

boost_version=1.66.0
boost_md5=b2dfbd6c717be4a7bb2d88018eaccf75
boost_version_underscore=${boost_version//./_}

mkdir -p ${http_base}/boostorg/release/${boost_version}/source
boost_url=https://dl.bintray.com/boostorg/release/${boost_version}/source/boost_${boost_version_underscore}.tar.bz2
echo ${boost_url}
curl --silent --show-error --retry 12 --retry-delay 10 -L -o ${http_base}/boostorg/release/${boost_version}/source/boost_${boost_version_underscore}.tar.bz2 ${boost_url}

#cmake 3.7 upper
mkdir -p ${http_base}/project/boost/boost/${boost_version}/

boost_url=http://downloads.sourceforge.net/project/boost/boost/${boost_version}/boost_${boost_version_underscore}.tar.bz2
echo ${boost_url} 
curl --silent --show-error --retry 12 --retry-delay 10 -L -o ${http_base}/project/boost/boost/${boost_version}/boost_${boost_version_underscore}.tar.bz2  ${boost_url}

mkdir -p ${http_base}/qa/
boost_url=https://download.ceph.com/qa/boost_${boost_version_underscore}.tar.bz2
echo ${boost_url} 
curl --silent --show-error --retry 12 --retry-delay 10 -L -o ${http_base}/qa/boost_${boost_version_underscore}.tar.bz2 ${boost_url}

echo ${boost_md5}"  "boost_${boost_version_underscore}.tar.bz2 > ${http_base}/boostorg/release/${boost_version}/source/boost_${boost_version_underscore}.tar.bz2.md5sum
#md5sum -c boost_${boost_version_underscore}.tar.bz2.md5sum
echo ${boost_md5}"  "boost_${boost_version_underscore}.tar.bz2 > {http_base}/project/boost/boost/${boost_version}/boost_${boost_version_underscore}.tar.bz2.md5sum
echo ${boost_md5}"  "boost_${boost_version_underscore}.tar.bz2 > ${http_base}/qa/boost_${boost_version_underscore}.tar.bz2 ${boost_url}.md5sum

```


## 临时源码编译

由于ceph存在submodule,所以需要把submodule也导入内网，编译前，需要修改ceph的submodule文件，使其子模块指向内网的地址。
此过程为临时修改为内部地址。
例如： 所有的submoldue 导入到 gitlab的内部仓库。

```shell

#!/bin/bash
#
#author by linxuhua 
#

BASE_DIR=`pwd`
# boost base http url
INTRANET_BASE=http://localhost
# ceph submodule group url in gitlab
CEPH_GIT_BASE=git@localhost:ceph-submodules

cd ${BASE_DIR}

sed -i -e 's@$SUDO yum-config-manager --add-repo@#$SUDO yum-config-manager --add-repo@g'  \
       -e 's@$SUDO yum install --nogpgcheck -y epel-release@#$SUDO yum install --nogpgcheck -y epel-release@g' \
       -e 's@$SUDO rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$MAJOR_VERSION@#$SUDO rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$MAJOR_VERSION@g' \
       -e 's@$SUDO rm -f /etc/yum.repos.d/dl.fedoraproject.org*@#$SUDO rm -f /etc/yum.repos.d/dl.fedoraproject.org*@g' \
       ${BASE_DIR}/install-deps.sh 

cp ${BASE_DIR}/cmake/modules/BuildBoost.cmake ${BASE_DIR}/cmake/modules/BuildBoost.cmake.bk
sed -i -e 's#https://dl.bintray.com#'"${INTRANET_BASE}"'#g'  \
       -e 's#http://downloads.sourceforge.net#'"${INTRANET_BASE}"'#g'  \
       -e 's#https://download.ceph.com#'"${INTRANET_BASE}"'#g'  ${BASE_DIR}/cmake/modules/BuildBoost.cmake

cp ${BASE_DIR}/.gitmodules ${BASE_DIR}/.gitmodules.bk
sed -i -e 's#https://github.com/ceph#'"${CEPH_GIT_BASE}"'#g'  \
       -e 's#https://github.com/01org#'"${CEPH_GIT_BASE}"'#g' \
       -e 's#https://github.com/facebook#'"${CEPH_GIT_BASE}"'#g' ${BASE_DIR}/.gitmodules

#gitlab url is lowercase， replace the path and url to lowercase  
sed -i -e 's#xxHash.git#xxhash.git#g' -e 's#"src/xxHash"#"src/xxhash"#g' ${BASE_DIR}/.gitmodules


#初始化rapidjson模块，然后修改其submodule的url到内网地址
git submodule update --init

cp ${BASE_DIR}/src/rapidjson/.gitmodules  ${BASE_DIR}/src/rapidjson/.gitmodules.bk

sed -i -e 's#https://github.com/google#'"${CEPH_GIT_BASE}"'#g' ${BASE_DIR}/src/rapidjson/.gitmodules


sed -i -e 's#https://dl.bintray.com#'"${INTRANET_BASE}"'#g'  \
       -e 's#https://downloads.sourceforge.net#'"${INTRANET_BASE}"'#g'  \
       -e 's#https://download.ceph.com#'"${INTRANET_BASE}"'#g'        make-dist


./do_cmake.sh

cd build 

make -j10

```

## 修改源码为内网编译，永久使用分支指向内部源

1、同步所有源码到内网

2、 执行文件 intranet-commit.sh 


## SRPM编译

SRPM 需要读取tag生成版本号，请按照此方法打tag

> git tag -a v12.2.5.1

在编译环境先安装rpmbuild工具

> yum install rpm-build rpmdevtools

>rpmdev-setuptree

编译SRPM文件

```shell
cd $CEPH_BASE

version=v12.2.5.1

./make-dist ${version}

cp ceph-${version}.tar.bz2 ~/rpmbuild/SOURCES/

tar --strip-components=1 -C ~/rpmbuild/SPECS/ --no-anchored -xvjf ~/rpmbuild/SOURCES/ceph-${version}.tar.bz2 "ceph.spec"

rpmbuild -ba ~/rpmbuild/SPECS/ceph.spec

```

