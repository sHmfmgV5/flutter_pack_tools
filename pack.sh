#!/bin/bash

source pgyer_upload.sh

# 蒲公英api_key
api_key="bb89b09f7b16ca336ba9ad385d3da6cb"

project_path=$(pwd)

#build/app/outputs/flutter-apk/app-sz-release.apk
release_apk_path=$project_path/build/app/outputs/flutter-apk
release_ipa_path=$project_path/build/ios
dist_dir=$project_path/dist


printHelp() {
    echo "Usage: $0 -v <version_name> -n <version_number> -f <flavor>"
    echo "Example: $0 -v 1.0.0 -n 18 -f sz"
    echo ""
    echo "Description:"
    echo "  -v version_name                build_name"
    echo "  -n version_number              build_number"
    echo "  -f flavor                      flavor"
    echo "  -h help                        show this help"
    echo ""
    exit 1
}

while getopts 'v:n:f:hai' OPT; do
    case $OPT in
        v) version_name="$OPTARG";;
        n) version_number="$OPTARG";;
        f) flavor="$OPTARG";;
        a) a=1;;
        i) i=1;;
        ?) printHelp;;
    esac
done
#通过shift $(($OPTIND - 1))的处理，$*中就只保留了除去选项内容的参数，
#可以在后面的shell程序中进行处理
shift $(($OPTIND - 1))


target_dir=$version_name+$version_number
ios_dist=$dist_dir/$target_dir/ios/$flavor
android_dist=$dist_dir/$target_dir/android

# echo $ios_dist
# echo $android_dist
# echo $flavor


if [ "$flavor" == "sz" ]; then
    target="lib/main_sz.dart"
elif [ "$flavor" == "us" ]; then
    target="lib/main_us.dart"
else
    echo "no flavor!"
    exit
fi

build_android(){
    fvm flutter build apk --release \
        --flavor $flavor \
        --target $target \
        --obfuscate --split-debug-info=$android_dist/$flavor \
        --build-name=$version_name \
        --build-number=$version_number

    #app-sz-release.apk
    apk_file=$release_apk_path/app-$flavor-release.apk
    echo $apk_file
    if [ ! -f "$apk_file" ]; then
        echo "apk file not exists"
        exit
    fi

    out_file=$android_dist/app-$flavor-release.$version_name.$version_number.apk
    echo $out_file
    if [ ! -x $android_dist ];then
        mkdir -p $android_dist
    fi
    mv $apk_file $out_file
    pgyer_upload $api_key $out_file
}

build_ios(){
    fvm flutter build ipa --release \
        --flavor $flavor \
        --target $target  \
        --obfuscate \
        --obfuscate --split-debug-info=$ios_dist \
        --build-name=$version_name \
        --build-number=$version_number \
        --export-method=ad-hoc
        
    
    if [ ! -x "$release_ipa_path" ]; then
        echo "ios build dir not exists"
        exit
    fi

    if [ ! -x $ios_dist ];then
        mkdir -p $ios_dist
    fi

    mv $release_ipa_path $ios_dist

    files=$(ls $ios_dist/ios/ipa/*.ipa)
    app_name=$(basename ${files[0]})

    out_file=$ios_dist/ios/ipa/$app_name
    echo $out_file
    if [ ! -f "$out_file" ]; then
        echo "ipa file not exists"
        exit
    fi

    pgyer_upload $api_key $out_file
}


if [ "$a" == "1" ]; then
    build_android
fi
if [ "$i" == "1" ]; then
    build_ios
fi

if [[ "$a" == "" && "$i" == "" ]];then 
    build_android
    build_ios
fi