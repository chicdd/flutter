#!/bin/bash

# 현재 Build Configuration과 Product Name 확인
echo "Build Configuration: ${CONFIGURATION}"
echo "Product Name: ${PRODUCT_NAME}"

# Assets 경로 설정
ASSETS_PATH="$SRCROOT/Runner/Assets.xcassets/AppIcon.appiconset"

# Build Configuration에 따라 적절한 아이콘 복사
if [[ "${CONFIGURATION}" == *"C1"* ]] || [[ "${PRODUCT_NAME}" == *"순천씨원"* ]]; then
    echo "Copying C1 app icons..."
    SOURCE_PATH="$SRCROOT/Runner/Assets-C1.xcassets/AppIcon.appiconset"
elif [[ "${CONFIGURATION}" == *"Kone"* ]] || [[ "${PRODUCT_NAME}" == *"한국안전시스템"* ]]; then
    echo "Copying Kone app icons..."
    SOURCE_PATH="$SRCROOT/Runner/Assets-Kone.xcassets/AppIcon.appiconset"
elif [[ "${CONFIGURATION}" == *"seodaemun"* ]] || [[ "${PRODUCT_NAME}" == *"서대문포콤"* ]]; then
    echo "Copying seodaemun app icons..."
    SOURCE_PATH="$SRCROOT/Runner/Assets-seodaemun.xcassets/AppIcon.appiconset"
else
    echo "Unknown configuration (${CONFIGURATION}) and product name (${PRODUCT_NAME}), using default icons"
    exit 0
fi

# 아이콘 파일들 복사
if [ -d "$SOURCE_PATH" ]; then
    echo "Copying from $SOURCE_PATH to $ASSETS_PATH"
    cp -f "$SOURCE_PATH"/*.png "$ASSETS_PATH/"
    echo "App icons copied successfully for ${CONFIGURATION}"
else
    echo "Source path $SOURCE_PATH not found"
    exit 1
fi