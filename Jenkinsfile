node {
  stage('make-srpm'){

    sh("""
       rm -rf /root/rpmbuild
       ./make-srpm.sh ${version}
       rpmbuild --rebuild ceph-*.srpm
    """)
      
  }

}