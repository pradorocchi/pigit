import Foundation

class Parse {
    var index = 0
    let data: Data
    
    init?(_ url: URL) {
        if let data = try? Data(contentsOf: url) {
            self.data = data
        } else {
            return nil
        }
    }
    
    func ascii(_ limiter: String) throws -> String {
        var result = String()
        var character = String()
        while character != limiter {
            result += character
            character = try self.character()
        }
        return result
    }
    
    func variable() throws -> String {
        var result = String()
        var byte = String()
        repeat {
            result += byte
            byte = try character()
        } while(byte != "\u{0000}")
        return result
    }
    
    func name() throws -> String {
        return try {
            index += $0 ? 4 : 2
            return String(decoding: try advance($1), as: UTF8.self)
        } (try version3(), try length())
    }
    
    func string() throws -> String { return String(decoding: try advance(4), as: UTF8.self) }
    func character() throws -> String { return String(decoding: try advance(1), as: UTF8.self) }
    func hash() throws -> String { return (try advance(20)).map { String(format: "%02hhx", $0) }.joined() }
    
    func number() throws -> Int {
        if let result = Int(try advance(4).map { String(format: "%02hhx", $0) }.joined(), radix: 16) {
            return result
        }
        throw Failure.Index.malformed
    }
    
    func tree() throws -> Int {
        return String(decoding: data.subdata(in: index ..< index + 4), as: UTF8.self) == "Tree" ? try number() : 0
    }
    
    func date() throws -> Date {
        let result = Date(timeIntervalSince1970: TimeInterval(try number()))
        index += 4
        return result
    }
    
    func conflict() throws -> Bool {
        var byte = data.subdata(in:
            index ..< index + 1).withUnsafeBytes { $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1).pointee }
        byte >>= 2
        if byte & 0x01 == 1 {
            return true
        }
        byte >>= 1
        if byte & 0x01 == 1 {
            return true
        }
        return false
    }
    
    func clean() {
        while (String(decoding: data.subdata(in: index ..< index + 1), as: UTF8.self) == "\u{0000}") {
            index += 1
        }
    }
    
    private func version3() throws -> Bool {
        var byte = data.subdata(in:
            index ..< index + 1).withUnsafeBytes { $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1).pointee }
        byte >>= 1
        return byte & 0x01 == 1
    }
    
    private func length() throws -> Int {
        guard let result = Int(data.subdata(in: index + 1 ..< index + 2).map { String(format: "%02hhx", $0) }.joined(), radix: 16)
            else { throw Failure.Index.malformed }
        return result
    }
    
    private func advance(_ bytes: Int) throws -> Data {
        let index = self.index + bytes
        guard data.count >= index else { throw Failure.Index.malformed }
        let result = data.subdata(in: self.index ..< index)
        self.index = index
        return result
    }
}
