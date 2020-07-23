#!/bin/sh
#
# Deploy cc.uffs.edu.br website and its dependencies.
#
# Author: Fernando Bevilacqua <fernando.bevilacqua.uffs.edu.br>
# Date: 2020-07-22
# License: MIT
#

#########################################################
# Configuration variables
#########################################################
BASE_REPO=https://github.com/ccuffs

SITE_TARGET_FOLDER=/var/www/cc.uffs.edu.br
SITE_SRC_FOLDER=/tmp/cc.uffs.edu.br.git

BUNDLE_CMD="/usr/local/bin/bundle"
JEKYLL_CMD="$BUNDLE_CMD exec jekyll"

#########################################################
# Functions
#########################################################

# log "message"
log() {
    msg=$1
    now=`date +%Y-%m-%d:%H:%M:%S`
    tag="[$now]"

    echo "$tag $msg"
}

# getrepo https://repo.url/here /target/folder
getrepo() {
    repo=$1
    target_dir=$2
    
    log "Fetching git repo: $repo"
    if [ ! -d $target_dir ]
    then
        git clone --recurse-submodules $repo $target_dir
    fi

    cd $target_dir
    git reset HEAD --hard
    git pull --recurse-submodules
}

# mkncp /from/folder /to/folder
mkncp() {
    from_dir=$1
    to_dir=$2
    
    mkdir -p $to_dir
    cp -r $from_dir/* $to_dir/
}

# deploy name
deploy() {
    name=$1
    repo=$BASE_REPO/$name
    target=$SITE_TARGET_FOLDER/$name

    getrepo $repo /tmp/$name
    mkncp /tmp/$name $target

    log "Put '$repo' into '$target'."
}

#########################################################
# Main stuff
#########################################################

log "Deploy started."

# Deploy main site using jekyll

getrepo "$BASE_REPO/cc.uffs.edu.br" $SITE_SRC_FOLDER

log "Install jekyll dependencies..."
cd $SITE_SRC_FOLDER

# Add info about current commit
commit_info=$(git log -1 --pretty='format:text: "%H%d %aN (%aD): %s"')
echo $commit_info > $SITE_SRC_FOLDER/_data/commit_info.yml

# Install and update all bundle stuff
$BUNDLE_CMD update

log "Build website using jekyll..."
mkdir -p $SITE_TARGET_FOLDER/
$JEKYLL_CMD build --source $SITE_SRC_FOLDER/ --destination $SITE_TARGET_FOLDER/

# Site dependencies, i.e. subfolders, etc.
log "Deploy dependencies..."

deploy horario
deploy erbd2019

# Ensure /horarios also work
mkncp $SITE_TARGET_FOLDER/horario $SITE_TARGET_FOLDER/horarios

log "Git info: $commit_info"
log "All good! Have a coffee."