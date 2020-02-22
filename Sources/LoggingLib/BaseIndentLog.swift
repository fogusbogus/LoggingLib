//
//  BaseIndentLog.swift
//  Logging
//
//  Created by Matt Hogg on 03/11/2019.
//  Copyright © 2019 Matthew Hogg. All rights reserved.
//

import Foundation

open class BaseIndentLog : IIndentLog {
	public func AllowLog(_ logType: LogType) -> Bool {
		return true
	}
	
	public init() {
		
	}
	public var IndentLog_Indent: Int = 0
	private var _logFileURL : URL? = nil
	public var DefaultFileName = "logFile.txt"
	public var IndentLog_URL : URL? {
		get {
			if _logFileURL == nil {
				let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
				_logFileURL = dir.appendingPathComponent(DefaultFileName)
				do {
					try "-----------------------------\n".appendToURL(fileURL: _logFileURL!)
				}
				catch { }
			}
			return _logFileURL
		}
		set {
			_logFileURL = newValue
		}
	}
	
	private var _log : IIndentLog? = nil
	public var IndentLog_Instance : IIndentLog? {
		get {
			return _log // ?? self
		}
		set {
			_log = newValue
		}
	}

//	public func IncreaseLogIndent() -> Int {
//		return ResetLogIndent(IndentLog_Indent + 1)
//	}
//
//	public func DecreaseLogIndent() -> Int {
//		return ResetLogIndent(IndentLog_Indent - 1)
//	}
//
//	public func ResetLogIndent(_ indent: Int) -> Int {
//		IndentLog_Indent = indent < 0 ? 0 : indent
//		return IndentLog_Indent
//	}
	
}

extension String {
   func appendLineToURL(fileURL: URL) throws {
		try self.appendToURL(fileURL: fileURL)
	}

	func appendToURL(fileURL: URL) throws {
		let data = (self + "\n").data(using: String.Encoding.utf8, allowLossyConversion: false)!
		try data.append(fileURL: fileURL)
	}
}

extension Data {
	func append(fileURL: URL) throws {
		if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
			defer {
				fileHandle.closeFile()
			}
			fileHandle.seekToEndOfFile()
			fileHandle.write(self)
		}
		else {
			try write(to: fileURL, options: .atomic)
		}
	}
}

