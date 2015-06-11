#!/usr/bin/env bash
Logfile="vagrantlog.txt"   
# Edit the following to change the name of the database user :
#APP_DB_USER=postgresVagrant

APP_DB_USER=postgres
APP_DB_PASS=root

# Edit the following to change the name of the database that is created (defaults to the user name)
APP_DB_NAME=dotCMS

# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=1.18.1

echo "sudo to root"

sudo su - root

echo "Installing Git" >>$Logfile

yum install git -y > /dev/null >>$Logfile

echo "Clone git repository"

#git clone https://github.com/hcawebdevelopment/crm-modules.git /opt/crm-modules/
#git clone https://github.com/dotCMS/core-2.x.git /opt/crm-modules/dotCMS


echo "Installing postGRESql" >>$Logfile
yum install debconf-utils -y > /dev/null >>$Logfile


###########################################################
# Changes below this line are probably not necessary
###########################################################
print_db_usage () {
  echo ""
  echo "============================================================================================================================="
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 15432)" 
  echo "  Host: localhost"
  echo "  Port: 15432"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME"
  echo ""
  echo "Env variable for web application connecting from host machine for development:"
  echo "  DATABASE_URL=postgresql://localhost:15432/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME"
  echo "============================================================================================================================="
  echo ""
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)" >>$Logfile
  echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'" >>$Logfile
  echo "" >>$Logfile
  print_db_usage >>$Logfile
  exit
fi

# If you want your vm to be upgraded to latest version please enable blow
# Update package list and upgrade all packages
#yum -y update
#yum -y upgrade

# Start installing softwares required for project setup

#Installing Java 

echo "Installing Java ...." >>$Logfile

yum install -y java-1.6.0 >>$Logfile


#Installing and perform postGRESql setup required for dotCMS

echo "Installing PostGreSql ...." >>$Logfile

yum install -y "postgresql" "postgresql-contrib" "postgresql-server" "postgresql-jdbc" >>$Logfile

echo "Initiating PostGreSql configurations ...." >>$Logfile

PG_CONF="/var/lib/pgsql/data/postgresql.conf"
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
PG_DIR="/var/lib/pgsql/data"

#To perform all the settings , should be sudo'ed to root 
#changing role of user to root

sudo su - root

#initialize dotcms database

service postgresql initdb >>$Logfile

#checking postgresql service to on 

chkconfig postgresql on >>$Logfile

# start postgresql service 

service postgresql start >>$Logfile

# Edit postgresql.conf to change listen address to '*':

echo "Updating postgresql listener addresses to be accessible to host " >>$Logfile

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

sed -i "s/#port = 5432/port = 5432/" "$PG_CONF"

# Append to pg_hba.conf to add password auth:
echo "host    all         all         0.0.0.0/0              md5" >> "$PG_HBA"

#re-start postgresql service

service postgresql restart >>$Logfile

#following commands will be running in psql interface

cat << EOF | su - postgres -c psql
create database $APP_DB_NAME with owner $APP_DB_USER;
GRANT CREATE on database $APP_DB_NAME to $APP_DB_USER;
alter user $APP_DB_USER password '$APP_DB_PASS';
EOF

echo "Exiting out of 'psql' interface!" >>$Logfile

#Turning off iptables/firewall
 
service iptables stop >>$Logfile

chkconfig iptables off >>$Logfile

# saving the firewall rule 

service iptables save >>$Logfile

#Restarting postgresql service

service postgresql restart >>$Logfile
#TO-DO

#Setting up environment variables.
#Setting up tomcat variables.
#Setting up shared directories.


date > "$PROVISIONED_ON" >>$Logfile

######################################################################################
## WAS SETUP
######################################################################################


yum -y install unzip
yum -y install gtk2.i686
yum -y install libXtst.i686

mkdir /tmp/websphere

wget http://public.dhe.ibm.com/software/rationalsdp/v7/im/144/zips/agent.installer.linux.gtk.x86_1.4.4000.20110525_1254.zip -P /tmp/websphere

mkdir /opt/software/
mkdir /opt/software/IBM
mkdir /opt/software/IBM/installer-package
mkdir /opt/software/IBM/was
mkdir /opt/WebSphere85/

cd /tmp/websphere
unzip InstalMgr1.5.2_LNX_X86_WAS_8.5.zip -d /opt/software/IBM/installer-package
unzip   WAS_V8.5_1_OF_3.zip -d /opt/software/IBM/was
unzip   WAS_V8.5_2_OF_3.zip -d /opt/software/IBM/was
unzip   WAS_V8.5_3_OF_3.zip -d /opt/software/IBM/was

#Install Package Manager
cd /opt/software/IBM/installer-package
./installc  -acceptLicense -accessRights admin -installationDirectory "/opt/WebSphere85/IMGR" -dataLocation "/opt/WebSphere85/Imdata" -silent

#Install WAS
cd /opt/WebSphere85/IMGR/eclipse/tools
./imcl listAvailablePackages -repositories /opt/software/IBM/was/repository.config
[get the output and use that string in the next install command e.g. com.ibm.websphere.BASE.v85_8.5.0.20120501_1108]
./imcl -acceptLicense -showProgress install com.ibm.websphere.BASE.v85_8.5.0.20120501_1108 -repositories  /opt/software/IBM/was/repository.config

#create a default profile
cd /opt/IBM/WebSphere/AppServer/bin
./manageprofiles.sh -create -templatePath /opt/IBM/WebSphere/AppServer/profileTemplates/default/


echo "Successfully created dev virtual machine." 
echo "You can check vagrant log for postgres connections,installed softwares etc @ /home/vagrant/vagrantlog.txt in generated Virtual Machine"
echo ""
print_db_usage >>$Logfile

 