#!/bin/bash

# Name: buildPkg.sh
# Description: Build packages
# Author: Titux Metal <tituxmetal[at]lgdweb[dot]fr>
# Url: https://github.com/ArchLinuxCustomEasy/pkgbuilds
# Version: 1.0
# Revision: 2021.09.16
# License: MIT License

currentLocation="$(pwd)"
packageNames="$(ls -d -- */ | cut -f1 -d '/')"
packageNames+=("exit")
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
  pattern=$(ls ./PKGBUILD 2>/dev/null | wc -l)
  if [[ $pattern != 0 ]]
  then
    printMessage "Build package ${packageToBuild}"
    makepkg --syncdeps --rmdeps --clean --force --noconfirm
  fi
}

changeDirectory() {
  name="${currentLocation}/${packageToBuild}"
  printMessage "Go to: ${name}"

  if [[ -d "${name}" ]]
  then
    printMessage "Enter in ${name} directory"
    cd ${name}
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
  cd ${currentLocation}
  printMessage "Clean ${packageToBuild} sources"
  git clean -Xdf ${packageToBuild}
}

selectPackageToBuild() {
  printMessage "Select the package to build\n${packageNames[*]}"

  PS3="Choose a package to build: "
  select opt in ${packageNames[@]} ; do
  case $opt in
    exit)
      printMessage "All is done!"
      exit 0
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
