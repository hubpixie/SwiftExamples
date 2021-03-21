// How can I convert a String to an MD5 hash in iOS using Swift?
// How to read a block of data from file (instead of a whole file) in Swift
// github swift read  binary files in iOS
import Foundation
import CommonCrypto

typealias CCBridgeMethodType = (UnsafeRawPointer?, UInt32,
    UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?
class HashEdit {
    enum CCType {
        case md5
        case sha1
        case sha224
        case sha256
        case sha384
        case sha512

        var length: Int {
            switch self {
            case .md5:
                return Int(CC_MD5_DIGEST_LENGTH)
            case .sha1:
                return Int(CC_SHA1_DIGEST_LENGTH)
            case .sha224:
                return Int(CC_SHA224_DIGEST_LENGTH)
            case .sha256:
                return Int(CC_SHA256_DIGEST_LENGTH)
            case .sha384:
                return Int(CC_SHA384_DIGEST_LENGTH)
            case .sha512:
                return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }

        var method: CCBridgeMethodType {
            switch self {
            case .md5:
                return CC_MD5
            case .sha1:
                return CC_SHA1
            case .sha224:
                return CC_SHA224
            case .sha256:
                return CC_SHA256
            case .sha384:
                return CC_SHA384
            case .sha512:
                return CC_SHA512
            }
        }
    }

    static var shared = HashEdit()

    func hash(_ data: Data, ccType: CCType) -> String {
        let digest = data.withUnsafeBytes { (rawBytesPointer: UnsafeRawBufferPointer) -> Data? in
            guard let bytes = rawBytesPointer.baseAddress?.assumingMemoryBound(to: Float.self) else {
                return nil
            }
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: ccType.length)
            _ = ccType.method(bytes, CC_LONG(data.count), buffer)
            let result = Data(bytes: buffer, count: ccType.length)
            buffer.deallocate()
            return result
        }
        return digest?.map { String(format: "%02hhx", $0) }.joined() ?? ""
    }
}

// MARK: - Public Methods

extension HashEdit {
    func loadFileAsBlock(number: Int, withBlockSize size: Int, path: String) -> Data? {
        let correctPath = path.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")

        guard let fileHandle = FileHandle(forReadingAtPath: correctPath) else { return nil }

        let bytesOffset = UInt64((number - 1) * size)
        fileHandle.seek(toFileOffset: bytesOffset)
        let data = fileHandle.readData(ofLength: size)
        fileHandle.closeFile()
        return data
    }
}
