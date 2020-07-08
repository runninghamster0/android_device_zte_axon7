#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=axon7
VENDOR=zte

export DEVICE_BRINGUP_YEAR=2020

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

MK_ROOT="${MY_DIR}/../../.."

HELPER="${MK_ROOT}/vendor/havoc/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

function blob_fixup() {
    case "${1}" in
    vendor/bin/imsrcsd)
        patchelf --add-needed "libbase_shim.so" "${2}"
        ;;
    vendor/lib64/hw/android.hardware.bluetooth@1.0-impl-qti.so)
        patchelf --add-needed "libbase_shim.so" "${2}"
        ;;
    vendor/lib/libtfa9890.so)
        sed -i "s|/etc/settings/stereo_qcom_spk.cnt|/vendor/etc/tfa/stereo_qc_spk.cnt|g" "${2}"
        sed -i "s|/etc/settings/mono_qcom_rcv.cnt|/vendor/etc/tfa/mono_qc_rcv.cnt|g" "${2}"
        sed -i "s|/etc/settings/mono_qcom_spk_l.cnt|/vendor/etc/tfa/mono_qc_spk_l.cnt|g" "${2}"
        sed -i "s|/etc/settings/mono_qcom_spk_r.cnt|/vendor/etc/tfa/mono_qc_spk_r.cnt|g" "${2}"
        sed -i "s|/etc/settings/stereo_qcom_spk_l.cnt|/vendor/etc/tfa/stereo_qc_spk_l.cnt|g" "${2}"
        sed -i "s|/etc/settings/stereo_qcom_spk_r.cnt|/vendor/etc/tfa/stereo_qc_spk_r.cnt|g" "${2}"
        ;;
    etc/permissions/qti-vzw-ims-internal.xml)
        sed -i "s|/system/vendor/framework/qti-vzw-ims-internal.jar|/vendor/framework/qti-vzw-ims-internal.jar|g" "${2}"
        ;;
    vendor/lib/libFNVfbEngineHAL.so)
        patchelf --add-needed "libshim_camera.so" "${2}"
        ;;
    vendor/lib64/vendor.qti.gnss@1.0_vendor.so)
        patchelf --replace-needed "android.hardware.gnss@1.0.so" "android.hardware.gnss@1.0-v27.so" "${2}"
        ;;
    esac
}

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true
SECTION=
KANG=

while [ "$1" != "" ]; do
    case "$1" in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -k | --kang)            KANG="--kang"
                                ;;
        -s | --section )        shift
                                SECTION="$1"
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC="$1"
                                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$MK_ROOT"

extract "${MY_DIR}"/proprietary-files.txt "${SRC}" "${SECTION}"

# Fingerprint blobs
sed -i "s|/data/system/fingerprint|/data/vendor/fingerprint|g" "${DEVICE_BLOB_ROOT}"/vendor/lib64/hw/fingerprint.msm8996.so
sed -i "s|/data/system/fingerprint|/data/vendor/fingerprint|g" "${DEVICE_BLOB_ROOT}"/vendor/lib64/gxfingerprint.default.so
sed -i "s|/data/system/fingerprint|/data/vendor/fingerprint|g" "${DEVICE_BLOB_ROOT}"/vendor/lib64/libfp_client.so
sed -i "s|/data/system/fingerprint|/data/vendor/fingerprint|g" "${DEVICE_BLOB_ROOT}"/vendor/lib64/libfpservice.so

"${MY_DIR}"/setup-makefiles.sh
