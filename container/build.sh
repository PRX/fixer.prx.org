#!/bin/bash
$(/usr/local/bin/boot2docker shellinit)

BUILD_DIR=./build

_clean() {

  if [ -d $BUILD_DIR ]; then
    rm -R $BUILD_DIR
  fi

  docker rmi build_master
  docker rmi build_masterprocessor
  docker rmi build_worker
}

# make build dirs
_make_build_dir() {
  echo build directory $BUILD_DIR
  mkdir -p $BUILD_DIR
}

_copy_app() {
  build_dir=$1
  # copy the dirs and files that should be in the image
  for dir in app bin config db lib public vendor; do
    cp -a $dir $build_dir
  done

  for dir in log tmp; do
    mkdir -p $build_dir/$dir
  done

  for file in config.ru Gemfile Gemfile.lock LICENSE Rakefile .dockerignore .gitignore; do
    cp -a $file $build_dir
  done
}

_prepare() {
  _make_build_dir
  cp -a container/docker-compose.yml $BUILD_DIR
}

_prepare_image() {
  image_name=$1

  # create a dir for master
  image_build_dir=$BUILD_DIR/$image_name
  echo $image_name build directory $image_build_dir

  mkdir -p $image_build_dir

  _copy_app $image_build_dir

  cp -a container/images/scripts $image_build_dir
  cp -a container/images/$image_name/ $image_build_dir
}

_build() {
  _prepare
  _prepare_image master
  _prepare_image master_processor
  _prepare_image worker

  docker-compose -f $BUILD_DIR/docker-compose.yml build
}

_up() {
  docker-compose -f $BUILD_DIR/docker-compose.yml up
}

# These are just placeholders for now
# todo: need to work out labelling and tracking versions
_tag() {
  docker tag -f build_master publicradioexchange/fixer_master
  docker tag -f build_worker publicradioexchange/fixer_worker
  docker tag -f build_masterprocessor publicradioexchange/fixer_masterprocessor
}

_push() {
  docker push publicradioexchange/fixer_master
  docker push publicradioexchange/fixer_worker
  docker push publicradioexchange/fixer_masterprocessor
}

if [ "$1" = "clean" ]; then
  _clean
elif [ "$1" = "up" ]; then
  _up
elif [ "$1" = "tag" ]; then
  _tag
elif [ "$1" = "push" ]; then
  _push
else
  _build
fi
