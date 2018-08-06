#!/bin/bash
#
#author by linxuhua 
# modify source code for intranet
#

BASE_DIR=`pwd`
# boost base http url
INTRANET_BASE=http://localhost
# ceph submodule group url in gitlab
CEPH_GIT_BASE=git@localhost:ceph-submodules

cd ${BASE_DIR}

git branch dev


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

git commit -am "change to intranet"

#初始化rapidjson模块，然后修改其submodule的url到内网地址
git submodule update --init

cd src/rapidjson

git branch dev

sed -i -e 's#https://github.com/google#'"${CEPH_GIT_BASE}"'#g' ${BASE_DIR}/src/rapidjson/.gitmodules

git commit -am "change to intranet"
git push --all

git reset origin/updev --hard

cd ${BASE_DIR}

git commit -am "change rapidjson's submoudle to intranet"

git push origin dev









sed -i -e 's#https://dl.bintray.com#'"${INTRANET_BASE}"'#g'  \
       -e 's#https://downloads.sourceforge.net#'"${INTRANET_BASE}"'#g'  \
       -e 's#https://download.ceph.com#'"${INTRANET_BASE}"'#g'        make-dist


