default:
	swift build -c release
	cp .build/release/changelog ./
