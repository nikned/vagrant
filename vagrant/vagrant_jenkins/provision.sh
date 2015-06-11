#!/bin/bash
 
if [ ! -f /usr/bin/svn ]; 
then
	echo "-------- PROVISIONING SUBVERSION ------------"
	echo "---------------------------------------------"
 
	## Install subverison
	apt-get update
	apt-get -y install subversion
else
	echo "CHECK - Subversion already installed"
fi
 
 
if [ ! -f /usr/lib/jvm/java-7-oracle/bin/java ]; 
then
    echo "-------- PROVISIONING JAVA ------------"
	echo "---------------------------------------"
 
	## Make java install non-interactive
	## See http://askubuntu.com/questions/190582/installing-java-automatically-with-silent-option
	echo debconf shared/accepted-oracle-license-v1-1 select true | \
	  debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | \
	  debconf-set-selections
 
	## Install java 1.7
	## See http://www.webupd8.org/2012/06/how-to-install-oracle-java-7-in-debian.html
	echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
	echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
	apt-get update
	apt-get -y install oracle-java7-installer
else
	echo "CHECK - Java already installed"
fi
 
if [ ! -f /etc/init.d/jenkins ]; 
then
	echo "-------- PROVISIONING JENKINS ------------"
	echo "------------------------------------------"
 
 
	## Install Jenkins
	#
	# URL: http://localhost:6060
	# Home: /var/lib/jenkins
	# Start/Stop: /etc/init.d/jenkins
	# Config: /etc/default/jenkins
	# Jenkins log: /var/log/jenkins/jenkins.log
	
	#### These lines install latest jenkins ( latest and greatest also unstable builds) #####################
	# wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
	# sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
	#### These lines install latest jenkins ( latest and greatest also unstable builds) ######################

	### POINTING TO STABLE JENKINS BUILDS ONLY #############
        wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | sudo apt-key add -
	sh -c 'echo deb http://pkg.jenkins-ci.org/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
	apt-get update
	apt-get -y install jenkins
 
	# Move Jenkins to port 6060
	sed -i 's/8080/6060/g' /etc/default/jenkins
	/etc/init.d/jenkins restart
else
	echo "CHECK - Jenkins already installed"
fi
 
 
### Everything below this point is not stricly needed for Jenkins to work
###
 
if [ ! -f /etc/init.d/tomcat7 ]; 
then
	echo "-------- PROVISIONING TOMCAT ------------"
	echo "-----------------------------------------"
 
 
	## Install Tomcat (port 8080) 
	# This gives us something to deploy builds into
	# CATALINA_BASE=/var/lib/tomcat7
	# CATALINE_HOME=/usr/share/tomcat7
	export JAVA_HOME="/usr/lib/jvm/java-7-oracle"
	apt-get -y install tomcat7
 
	# Work around a bug in the default tomcat start script
	sed -i 's/export JAVA_HOME/export JAVA_HOME=\"\/usr\/lib\/jvm\/java-7-oracle\"/g' /etc/init.d/tomcat7
	/etc/init.d/tomcat7 stop
	/etc/init.d/tomcat7 start
else
	echo "CHECK - Tomcat already installed"
fi
 
if [ ! -f /usr/local/lib/ant/apache-ant-1.9.4/bin/ant ]; 
then
	echo "-------- PROVISIONING ANT ---------------"
	echo "-----------------------------------------"
 
	mkdir -p /usr/local/lib/ant
	cd /usr/local/lib/ant
	wget -q http://ftp.halifax.rwth-aachen.de/apache//ant/binaries/apache-ant-1.9.4-bin.tar.gz
	tar xzf apache-ant-1.9.4-bin.tar.gz
	rm apache-ant-1.9.4-bin.tar.gz
	ln -s /usr/local/lib/ant/apache-ant-1.9.4/bin/ant /usr/local/bin/ant
 
	echo "Ant installed"
else
	echo "CHECK - Ant already installed"
fi


if [ ! -f /usr/share/maven/bin/mvn ];
then
	echo "-------- PROVISIONING MAVEN ---------------"
	echo "-----------------------------------------"

	apt-get install -y maven

	echo "Maven installed"
else
	echo "CHECK - Maven already installed"
fi


if [ ! -f /etc/init.d/git ];
then
	echo "-------- PROVISIONING Git ----------------"
	echo "------------------------------------------"


	## Install git
	apt-get -y install git

else
	echo "CHECK - git already installed"
fi
 

if [ ! -f /etc/init.d/opennms ];
then
        echo "-------- PROVISIONING OPENNMS ------------"
        echo "------------------------------------------"


        ## Install OpenNMS -OpenNMS is a free an open source enterprise grade network monitoring and network management platform
        #
        # URL:
        # Home:
        # Start/Stop:
        # Config: /etc/default/opennms
        

        #### These lines install latest opennms #####################
        # wget -q -O - http://debian.opennms.org/OPENNMS-GPG-KEY | sudo apt-key add -
        # sh -c 'echo deb http://debian.opennms.org stable main > /etc/apt/sources.list.d/opennms.list'
        #### These lines install latest opennms ######################

       
        wget -q -O - http://debian.opennms.org/OPENNMS-GPG-KEY | sudo apt-key add -
        sh -c 'echo deb http://debian.opennms.org stable main > /etc/apt/sources.list.d/opennms.list'
        apt-get update
        apt-get -y install opennms

        # Move Jenkins to port 6060
        #sed -i 's/8180/8180/g' /etc/default/opennms
        # Not Starting opennmas for now (need additional steps to run opennms successfully)
        #sudo service opennms start
else
        echo "CHECK - OpenNms already installed"
fi


### stricly needed for Jenkins to webdav to crm modules environment for deployment
###

	echo "-------- PROVISIONING Cadaver (open source webdav client) ------------"
	echo "----------------------------------------------------------------------"


	## Install Cadaver
	# This gives us something to webdav and push files to dotcms environment

	apt-get install -y cadaver
	#create .netrc config with user login and password credentials ( putting mine for now )
	sh -c 'echo "machine     ehctest.com
				 login       nikhil.nedunuri@hcahealthcare.com
				 password    changeit

				 machine     ehcstaging.com
				 login       nikhil.nedunuri@hcahealthcare.com
				 password    changeme " > ~/.netrc'


echo "-------- PROVISIONING DONE ------------"
echo "-- Jenkins: http://localhost:6060      "
echo "-- Tomcat7: http://localhost:7070      "
echo "-- Ant  -------------------------------"
echo "-- Maven  -----------------------------"
echo "-- git  -------------------------------"
echo "-- OpenNMS(not started)  --------------"
echo "-- Cadaver  ---------------------------"
echo "---------------------------------------"