#!/bin/bash

# Name: buildPkg.sh
# Description: Build package
# Author: Tuxi Metal <tuximetal[at]lgdweb[dot]fr>
# Url: https://github.com/custom-archlinux/iso-sources
# Version: 1.0
# Revision: 2021.06.28
# License: MIT License

currentLocation="$(pwd)"
packageNames="$(ls -d -- */ | cut -f1 -d '/')"
packageNames+=("exit")
PS3="Choose a number to select the package to build or 'q' to cancel: "
mainRepositoryPath="/opt/alice"
packageToBuild=""

printMessage() {
  message=$1
  tput setaf 2
  echo -en "-------------------------------------------\n"
  echo -en "${message}\n"
  echo -en "-------------------------------------------\n"
  tput sgr0
}

# Helper function to handle errors
handleError() {
  clear
  set -uo pipefail
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
}

buildPackage() {
  printMessage "Updating package sums in $(pwd)"
  pattern=$(ls ./PKGBUILD 2>/dev/null | wc -l)
  if [[ $pattern != 0 ]]
  then
    updpkgsums
    sleep .5
    printMessage "Build package ${packageToBuild}"
    makepkg --syncdeps --rmdeps --clean --force --noconfirm

    printMessage "Current directory: $(pwd) in packageBuild function"
  fi
}

changeDirectory() {
  name="${currentLocation}/${packageToBuild}"
  printMessage "Go to: ${name}"

  if [[ -d "${name}" ]]
  then
    printMessage "Enter in ${name} directory"
    cd ${name}

    printMessage "Current directory: $(pwd) in changeDirectory function"
  fi
}


movePkgToRepo() {
  printMessage "Move the built package ${packageToBuild} to ${mainRepositoryPath}/x86_64"

  pattern=$(ls ./${packageToBuild}*.pkg.* 2>/dev/null | wc -l)
  if [[ $pattern != 0 ]]
  then
    mv ${packageToBuild}-*.pkg.* ${mainRepositoryPath}/x86_64
  fi
}

removeSources() {
  printMessage "Remove sources from $(pwd)"
  git clean -xdf
}

selectPackageToBuild() {
  printMessage "Select the package to build\n${packageNames[*]}"

  PS3="Choose a package to build: "
  select opt in ${packageNames[@]} ; do
  case $opt in
    exit)
      printMessage "All is done!"
      exit 0
      # break
      ;;
    *)
      if [[ "$opt" == "" ]]
      then
        printMessage "Invalid choice"
        continue
      fi
      packageToBuild=${opt}
      printMessage "package to build: ${packageToBuild}"
      changeDirectory
      buildPackage
      movePkgToRepo
      removeSources
      # break
      ;;
    esac
    selectPackageToBuild
  done
}

main() {
  handleError
  selectPackageToBuild
}

time main

exit 0
