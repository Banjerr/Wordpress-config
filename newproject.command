#!/bin/sh

# Version = 1.3.2
# 


# --------------------
# Load Variables
# --------------------
CURRENTDIRECTORY=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
source $CURRENTDIRECTORY/config.cfg

# --------------------
# Set directory
# --------------------
cd $DIRECTORY

# --------------------
# Set project name
# --------------------
echo "What is the project name ?"
read PROJECT_NAME
while [[ -z "$PROJECT_NAME" ]]; do
    echo "Please, type your project name:"
    read PROJECT_NAME
done

# --------------------
# Create database
# --------------------
echo "For local database configuration, I will use project name as database name, I just need table prefix (default : wp_)"
read TABLE_PREFIX
if [[ $TABLE_PREFIX == "" ]]; then
	TABLE_PREFIX="wp_"
fi
$MYSQL_PATH -u$DB_USER -p$DB_PASSWORD -e "create database "$PROJECT_NAME

# --------------------
# Function
# Download unzip and remove
# --------------------
function fetch_zip()
{
	curl -o file.zip $1
	unzip -q file.zip
	rm file.zip
}

# --------------------
# Create project directory
# --------------------
mkdir $PROJECT_NAME
PROJECT_DIR=$DIRECTORY"/"$PROJECT_NAME
cd $PROJECT_NAME

# --------------------
# Fetch Wordpress latest build
# --------------------
echo 'Download Wordpress...'
fetch_zip $WORDPRESS_URL
cp -R wordpress/* .
rm -rf wordpress && rm readme.html && rm license.txt

# --------------------
# Fetch base theme & remove default themes
# --------------------
echo 'Remove default themes and fetch your starter theme'
cd wp-content/themes/
git clone $THEME_URL $PROJECT_NAME
rm -r twentyten
rm -r twentyeleven
rm -r twentytwelve
rm -r twentythirteen
rm -r twentyfourteen

# --------------------
# Remove Hello Dolly plugin and fetch plugins
# --------------------
echo 'Remove Hello Dolly and fetch your plugins'
cd ../plugins/
rm hello.php

for PLUGIN in ${PLUGINS_URL[@]}
do
	fetch_zip $PLUGIN
done

# --------------------
# Create Wordpress wp-config.php
# --------------------
echo 'Create wp-config...'
cd $PROJECT_DIR
touch wp-config-local.php
echo "<?php
define( 'DB_NAME', '"$PROJECT_NAME"' );
define( 'DB_USER', '"$DB_USER"' );
define( 'DB_PASSWORD', '"$DB_PASSWORD"' );
define( 'DB_HOST', '"$DB_HOST"' );" >wp-config-local.php
touch db.txt
echo "if ( file_exists( dirname( __FILE__ ) . '/wp-config-local.php' ) ) {
	include( dirname( __FILE__ ) . '/wp-config-local.php' );
} else {
	define( 'DB_NAME', '' );
	define( 'DB_USER', '' );
	define( 'DB_PASSWORD', '' );
	define( 'DB_HOST', '' ); // Probably 'localhost'
}" > db.txt

sed -e'
/DB_NAME/,/localhost/ c\
hello
' \
<wp-config-sample.php >wp-config-temp.php

sed '/hello/ {
r db.txt
d
}'<wp-config-temp.php >wp-config.php
mv wp-config.php wp-config-temp.php

curl -o salt.txt https://api.wordpress.org/secret-key/1.1/salt/

sed '/#@-/r salt.txt' <wp-config-temp.php >wp-config.php
mv wp-config.php wp-config-temp.php

sed "/#@+/,/#@-/d" <wp-config-temp.php >wp-config.php
mv wp-config.php wp-config-temp.php

sed s/wp_/$TABLE_PREFIX/ <wp-config-temp.php >wp-config.php

rm wp-config-temp.php
rm db.txt
rm salt.txt

# --------------------
# Launch sublime project
# --------------------
echo 'Launch Sublime text 2'
cd $PROJECT_DIR
"$SUBLIME_PATH" $DIRECTORY"/"$PROJECT_NAME

# --------------------
# git init
# --------------------
echo 'git init'
git init
echo ".DS_Store
wp-config-local.php
.sass-cache" > .gitignore

# --------------------
# Launch default browser
# --------------------
echo 'Launch browser'
open $LOCAL_URL$PROJECT_NAME

echo 'Installation Complete, press enter to quit'
read
