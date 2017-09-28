#!/bin/bash

# Remove existings HopsWorks clone
rm -r hopsworks

# Kill existing Machines
if [ -d karamel-chef ]; then
  cd karamel-chef
  sh ./kill.sh
fi

# Read configuration
hopsworks_repo=$(awk -F "=" '/hopsworks_repo/ {print $2}' test_conf.ini)
hopsworks_branch=$(awk -F "=" '/hopsworks_branch/ {print $2}' test_conf.ini)
hopsworks_chef_repo=$(awk -F "=" '/hopsworks-chef_repo/ {print $2}' test_conf.ini)
hopsworks_chef_branch=$(awk -F "=" '/hopsworks-chef_branch/ {print $2}' test_conf.ini)

# Clone Hopsworks and checkout on the correct branch
git clone "https://github.com/"$hopsworks_repo
cd hopsworks
git checkout $hopsworks_branch

# Compile everything
mvn clean install -Dmaven.test.skip=true

# Compute Sha1 of the artifacts
ear_sha1=$(sha1sum hopsworks-ear/target/hopsworks-ear.ear | awk '{print $1}')
web_sha1=$(sha1sum hopsworks-web/target/hopsworks-web.war | awk '{print $1}')
ca_sha1=$(sha1sum hopsworks-ca/target/hopsworks-ca.war | awk '{print $1}')

# Back to the root directory
cd ..

# If necessary, clone karamel-chef
if [ ! -d karamel-chef ]; then
  # TODO: change this for production
  git clone "https://github.com/siroibaf/karamel-chef"
  cd karamel-chef
  git checkout test_recipe
  cd ..
fi

# Generate cluster definition and Vagrantfile configuration files
cp templates/Vagrantfile karamel-chef
sed -i 's/{ear\_sha1}/'"$ear_sha1"'/' karmel-chef/Vagrantfile
sed -i 's/{web\_sha1}/'"$web_sha1"'/' karamel-chef/Vagrantfile
sed -i 's/{ear\_sha1}/'"$ca_sha1"'/' karamel-chef/Vagrantfile

cp templates/cluster.yml karamel-chef
sed -i 's/{repository}/'"$hopsworks_chef_repo"'/' karamel-chef/cluster.yml
sed -i 's/{branch}/'"$hopsworks_chef_branch"'/' karamel-chef/cluster.yml

# Execute the tests
cd karamel-chef
sh ./test.sh
