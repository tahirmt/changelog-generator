default:
	swift build -c release --arch arm64 --arch x86_64
	cp .build/apple/Products/Release/changelog ./
