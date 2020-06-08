//
//  IIndentLog.swift
//  Logging
//
//  Created by Matt Hogg on 02/11/2019.
//  Copyright © 2019 Matthew Hogg. All rights reserved.
//

import Foundation
//import Common

public protocol IIndentLog {
	var IndentLog_Indent : Int { get set }
	var IndentLog_URL : URL? { get set }
	
	var IndentLog_Instance : IIndentLog? { get set }
	
	var IndentLog_Allowed : [LogType]? { get set }
}

public extension IIndentLog {
	
	@discardableResult
	mutating func IndentLog_Increment() -> Int {
		var log = IndentLog_Instance
		return log?.IndentLog_Reset(IndentLog_Indent + 1) ?? 0
	}
	
	@discardableResult
	mutating func IndentLog_Decrement() -> Int {
		var log = IndentLog_Instance
		return log?.IndentLog_Reset(IndentLog_Indent - 1) ?? 0
	}
	
	@discardableResult
	mutating func IndentLog_Reset(_ indent: Int) -> Int {
		IndentLog_Indent = indent < 0 ? 0 : indent
		return IndentLog_Indent
	}
}

public enum LogType : String {
	case debug
	case info
	case checkpoint
	case indent
	case timed
	case warning
	case error
	case fatal
	case sql
	case other
	
	func toCode() -> String {
		switch self {
		case .checkpoint:
			return "CHK"
		case .debug:
			return "DBG"
		case .error:
			return "ERR"
		case .fatal:
			return "FTL"
		case .indent:
			return ">>>"
		case .info:
			return "INF"
		case .other:
			return "???"
		case .timed:
			return "TMR"
		case .sql:
			return "SQL"
		default:
			return "WRN"
		}
	}
	
	func fromCode(_ code: String) -> LogType {
		let code = (code + "   ").substring(from: 0, length: 3).uppercased()
		switch code {
		case "DBG":
			return .debug
		case "CHK":
			return .checkpoint
		case "INF":
			return .info
		case ">>>":
			return .indent
		case "TMR":
			return .timed
		case "WRN":
			return .warning
		case "ERR":
			return .error
		case "FTL":
			return .fatal
		case "SQL":
			return .sql
		default:
			return .other
		}
	}
	
}

extension Date {
	func standardString() -> String {
		let df = DateFormatter()
		df.dateFormat = "dd/MM/yy HH:mm:ssZ"
		
		return df.string(from: Date())
	}
	
	func timeSinceString(_ startDate: Date) -> String {
		let ts = self.timeIntervalSince(startDate)
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.day, .hour, .minute, .second]
		formatter.unitsStyle = .abbreviated
		formatter.maximumUnitCount = 1
		return formatter.string(from: ts)!
	}
	
}

public extension IIndentLog {
	
	/// New indent with no return value
	/// - Parameters:
	///   - title: Description to show on the log
	///   - innerCode: This is called with no return value. When finished the indent is complete too.
	func indent(_ title: String, _ innerCode: () -> Void) {
		
		var log = self
		let indent = log.IndentLog_Indent
		let inTS = Date()
		write(type: .indent, category: ">>>", message: title)
		if isAllowed(.indent) {
			log.IndentLog_Increment()
		}
		innerCode()
		log.IndentLog_Reset(indent)
		write(type: .indent, category: "<<<", message: "\(title) {\(Date().timeSinceString(inTS))}")
	}
	
	/// New indent with a return value
	/// - Parameters:
	///   - title: Description to show on the log
	///   - innerCode: This is called with a return value. When finished the indent is complete too.
	func indent<T>(_ title: String, _ innerCode: () -> T, summary: ((T) -> Void)?) -> T {

		var log = self
		let indent = log.IndentLog_Indent
		let inTS = Date()
		write(type: .indent, category: ">>>", message: title)
		if isAllowed(.indent) {
			log.IndentLog_Increment()
		}

		let ret = innerCode()
		log.IndentLog_Reset(indent)
		write(type: .indent, category: "<<<", message: "\(title) {\(Date().timeSinceString(inTS))}")
		if let callSummary = summary {
			callSummary(ret)
		}
		return ret
	}
	
	func checkpoint(_ title: String, _ innerCode: () -> Void, keyAndValues: [String:Any?]) {

		var log = self
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) {\(Date().timeSinceString(inTS))}")
	}
	
	func checkpoint<T>(_ title: String, _ innerCode: () -> T, keyAndValues: [String:Any?]) -> T {
		return checkpoint(title, innerCode, summary: nil, keyAndValues: keyAndValues)
	}
	
	func checkpoint<T>(_ title: String, _ innerCode: () -> T, summary: ((T) -> Void)?, keyAndValues: [String:Any?]) -> T {
		var log = self
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		let ret = innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) [\(ret)] {\(Date().timeSinceString(inTS))}")
		if let callSummary = summary {
			callSummary(ret)
		}
		return ret
	}
	
	func checkpoint(_ label: String, _ title: String, _ innerCode: () -> Void, keyAndValues: [String:Any?]) {
		if isAllowed(.checkpoint) { self.label(label) }

		var log = self
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) {\(Date().timeSinceString(inTS))}")
	}
	
	func checkpoint<T>(_ label: String, _ title: String, _ innerCode: () -> T, keyAndValues: [String:Any?]) -> T {
		return checkpoint(label, title, innerCode, summary: nil, keyAndValues: keyAndValues)
	}
	func checkpoint<T>(_ label: String, _ title: String, _ innerCode: () -> T, summary: ((T) -> Void)?, keyAndValues: [String:Any?]) -> T {

		var log = self
		if isAllowed(.checkpoint) { self.label(label) }
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		let ret = innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) [\(ret)] {\(Date().timeSinceString(inTS))}")
		if let callSummary = summary {
			callSummary(ret)
		}
		return ret
		
	}
	
	func label(_ title: String) {
		guard IndentLog_Allowed?.count ?? 1 > 0 else { return }

		let lines = title.splitIntoLines(60)
		let max = lines.map { (s) -> Int in
			return s.trim().length()
		}.max() ?? 0
		blank()
		if max > 0 {
			let spaces = " ".repeating(max)
			let top = "/".repeating(max + 8)
			write(category: "///", message: top, maxLen: 1000, indentedCount: 0)
			for line in lines {
				let outline = "/// " + (line.trim() + spaces).substring(from: 0, length: max) + " ///"
				writeNoTS(outline)
			}
			writeNoTS(top)
		}
	}
	
	func blank() {
		guard IndentLog_Allowed?.count ?? 1 > 0 else { return }

		writeNoTS("")
	}
	
	private func indentSpaces(_ indent: Int) -> String {
		return ".  ".repeating(indent)
	}
	
	private func getURLFileLength(_ filePath: URL) -> UInt64 {
		do {
			let _attrs = try FileManager.default.attributesOfItem(atPath: filePath.path)
			return _attrs[.size] as? UInt64 ?? UInt64(0)
		}
		catch {
			
		}
		return UInt64.zero
	}
	
	private func isAllowed(_ types: LogType...) -> Bool {
		guard let allowedTypes = IndentLog_Allowed else {
			return true
		}
		return types.first { (type) -> Bool in
			return allowedTypes.contains(type)
		} != nil
	}
	
	private func write(type: LogType, category: String, message: String, maxLen: Int = 60, indentedCount : Int? = nil) {
		if isAllowed(type) {
			write(category: category, message: message, maxLen: maxLen, indentedCount: indentedCount)
		}
	}
	
	private func write(category: String, message: String, maxLen: Int = 60, indentedCount : Int? = nil) {
		
		let messageLines = message.splitIntoLines(maxLen)
		var output = Date().standardString() + "  "
		let cat = (category + "   ").substring(from: 0, length: 3).uppercased()
		let indent = indentSpaces(indentedCount ?? self.IndentLog_Indent)
		output += cat + "  " + indent
		var allOutput = ""
		var reset = false
		for line in messageLines {
			if allOutput != "" {
				allOutput += "\n"
			}
			allOutput += output + line
			if !reset {
				output = " ".repeating(output.length())
				reset = true
			}
		}
		if let url = self.IndentLog_URL {
			do {
				try allOutput.appendToURL(fileURL: url)
			}
			catch {
				print(allOutput)
			}
		}
		else {
			print(allOutput)
		}
	}
	
	private func writeNoTS(_ message: String) {
		
		var output = Date().standardString() + "  "
		output = " ".repeating(output.length() + 5) + message

		if let url = self.IndentLog_URL {
			do {
				try output.appendToURL(fileURL: url)
			}
			catch {
				print(output)
			}
		}
		else {
			print(output)
		}
	}
	
	func args(_ title: String, _ keysValues: [String:Any?], _ alternate: String = "ARG") {
		guard IndentLog_Allowed?.count ?? 1 > 0 else { return }

		if title.trim().length() > 0 {
			write(category: alternate, message: title)
		}
		let maxLen = keysValues.keys.map { (k) -> Int in
			return k.trim().length()
		}.max()
		if maxLen == nil {
			return
		}
		
		for kv in keysValues {
			let k = (kv.key + " ".repeat(maxLen!)).substring(from: 0, length: maxLen!)
			if (kv.value == nil) {
				write(category: "...", message: "--> \(k) : <nil>")
			}
			else {
				write(category: "...", message: "--> \(k) : \(kv.value!)")
			}
		}
		blank()
	}
	
	func debug(_ message: String, _ arguments: [String:Any?]) {

		guard isAllowed(.debug) else { return }

		args(message, arguments, LogType.debug.toCode())
	}
	func debug(_ message: String, _ arguments: CVarArg...) {

		guard isAllowed(.debug) else { return }
		
		write(category: LogType.debug.toCode(), message: String(format: message, arguments))
	}
	
	func info(_ message: String, _ arguments: [String:Any?]) {

		guard isAllowed(.info) else { return }
		
		args(message, arguments, LogType.info.toCode())
	}
	func info(_ message: String, _ arguments: CVarArg...) {

		guard isAllowed(.info) else { return }
		
		write(category: LogType.info.toCode(), message: String(format: message, arguments))
	}
	
	func warn(_ message: String, _ arguments: [String:Any?]) {

		guard isAllowed(.warning) else { return }
		
		args(message, arguments, LogType.warning.toCode())
	}
	func warn(_ message: String, _ arguments: CVarArg...) {

		guard isAllowed(.warning) else { return }
		
		write(category: LogType.warning.toCode(), message: String(format: message, arguments))
	}
	
	func error(_ message: String, _ arguments: [String:Any?]) {

		guard isAllowed(.error) else { return }
		
		args(message, arguments, LogType.error.toCode())
	}
	func error(_ message: String, _ arguments: CVarArg...) {

		guard isAllowed(.error) else { return }
		
		write(category: LogType.error.toCode(), message: String(format: message, arguments))
	}
	
	func SQL(_ message: String, _ arguments: [String:Any?]) {

		guard isAllowed(.sql) else { return }
		
		args(message, arguments, LogType.sql.toCode())
	}
	func SQL(_ message: String, _ args: CVarArg...) {

		guard isAllowed(.sql) else { return }
		
		write(category: LogType.sql.toCode(), message: String(format: message, args))
	}
	
}

public extension Optional where Wrapped == IIndentLog {
	
	/// New indent with no return value
	/// - Parameters:
	///   - title: Description to show on the log
	///   - innerCode: This is called with no return value. When finished the indent is complete too.
	func indent(_ title: String, _ innerCode: () -> Void) {
		
		//We can assume the log itself might not always be instanciated, but we still need to execute the code.
		if self == nil {
			innerCode()
			return
		}
		var log = self!
		let indent = log.IndentLog_Indent
		let inTS = Date()
		write(type: .indent, category: ">>>", message: title)
		log.IndentLog_Increment()
		innerCode()
		log.IndentLog_Reset(indent)
		write(type: .indent, category: "<<<", message: "\(title) {\(Date().timeSinceString(inTS))}")
	}
	
	/// New indent with a return value
	/// - Parameters:
	///   - title: Description to show on the log
	///   - innerCode: This is called with a return value. When finished the indent is complete too.
	func indent<T>(_ title: String, _ innerCode: () -> T) -> T {

		//We can assume the log itself might not always be instanciated, but we still need to execute the code.
		if self == nil {
			return innerCode()
		}
		var log = self!
		let indent = log.IndentLog_Indent
		let inTS = Date()
		write(type: .indent, category: ">>>", message: title)
		log.IndentLog_Increment()
		let ret = innerCode()
		log.IndentLog_Reset(indent)
		write(type: .indent, category: "<<<", message: "\(title) {\(Date().timeSinceString(inTS))}")
		return ret
	}
	
	func checkpoint(_ title: String, _ innerCode: () -> Void, keyAndValues: [String:Any?]) {
		if self == nil {
			innerCode()
			return
		}
		var log = self!
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) {\(Date().timeSinceString(inTS))}")
	}
	
	func checkpoint<T>(_ title: String, _ innerCode: () -> T, keyAndValues: [String:Any?]) -> T {
		if self == nil {
			return innerCode()
		}
		var log = self!
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		let ret = innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) [\(ret)] {\(Date().timeSinceString(inTS))}")
		return ret
	}
	
	func checkpoint(_ label: String, _ title: String, _ innerCode: () -> Void, keyAndValues: [String:Any?]) {
		if isAllowed(.checkpoint) { self.label(label) }
		if self == nil {
			innerCode()
			return
		}

		var log = self!
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) {\(Date().timeSinceString(inTS))}")
	}
	
	func checkpoint<T>(_ label: String, _ title: String, _ innerCode: () -> T, keyAndValues: [String:Any?]) -> T {
		if self == nil {
			return innerCode()
		}
		var log = self!
		if isAllowed(.checkpoint) { self.label(label) }
		let indent = log.IndentLog_Indent
		let inTS = Date()
		if isAllowed(.checkpoint) {
			args(title, keyAndValues, "CHK")
			log.IndentLog_Increment()
		}
		let ret = innerCode()
		log.IndentLog_Reset(indent)
		write(type: .checkpoint, category: "---", message: "<<< \(title) [\(ret)] {\(Date().timeSinceString(inTS))}")
		return ret
		
	}
	
	func label(_ title: String) {
		guard self?.IndentLog_Allowed?.count ?? 1 > 0 else { return }
		guard self != nil else {
			return
		}
		let lines = title.splitIntoLines(60)
		let max = lines.map { (s) -> Int in
			return s.trim().length()
		}.max() ?? 0
		blank()
		if max > 0 {
			let spaces = " ".repeating(max)
			let top = "/".repeating(max + 8)
			write(category: "///", message: top, maxLen: 1000, indentedCount: 0)
			for line in lines {
				let outline = "/// " + (line.trim() + spaces).substring(from: 0, length: max) + " ///"
				writeNoTS(outline)
			}
			writeNoTS(top)
		}
	}
	
	func blank() {
		guard self?.IndentLog_Allowed?.count ?? 1 > 0 else { return }
		writeNoTS("")
	}
	
	private func indentSpaces(_ indent: Int) -> String {
		return ".  ".repeating(indent)
	}
	
	private func isAllowed(_ types: LogType...) -> Bool {
		guard let allowedTypes = self?.IndentLog_Allowed else {
			return true
		}
		return types.first { (type) -> Bool in
			return allowedTypes.contains(type)
			} != nil
	}
	
	private func write(type: LogType, category: String, message: String, maxLen: Int = 60, indentedCount : Int? = nil) {
		if isAllowed(type) {
			write(category: category, message: message, maxLen: maxLen, indentedCount: indentedCount)
		}
	}
	
	private func write(category: String, message: String, maxLen: Int = 60, indentedCount : Int? = nil) {
		
		let messageLines = message.splitIntoLines(maxLen)
		var output = Date().standardString() + "  "
		let cat = (category + "   ").substring(from: 0, length: 3).uppercased()
		let indent = indentSpaces(indentedCount ?? self!.IndentLog_Indent)
		output += cat + "  " + indent
		var allOutput = ""
		var reset = false
		for line in messageLines {
			if allOutput != "" {
				allOutput += "\n"
			}
			allOutput += output + line
			if !reset {
				output = " ".repeating(output.length())
				reset = true
			}
		}
		if let url = self!.IndentLog_URL {
			do {
				try allOutput.appendToURL(fileURL: url)
			}
			catch {
				print(output)
			}
		}
		else {
			print(output)
		}
	}
	
	private func writeNoTS(_ message: String) {
		
		var output = Date().standardString() + "  "
		output = " ".repeating(output.length() + 5) + message

		if let url = self!.IndentLog_URL {
			do {
				try output.appendToURL(fileURL: url)
			}
			catch {
				print(output)
			}
		}
		else {
			print(output)
		}
	}
	
	func args(_ title: String, _ keysValues: [String:Any?], _ alternate: String = "ARG") {
		guard self?.IndentLog_Allowed?.count ?? 1 > 0 else { return }
		if self == nil {
			return
		}
		if title.trim().length() > 0 {
			write(category: alternate, message: title)
		}
		let maxLen = keysValues.keys.map { (k) -> Int in
			return k.trim().length()
		}.max()
		if maxLen == nil {
			return
		}
		
		for kv in keysValues {
			let k = (kv.key + " ".repeat(maxLen!)).substring(from: 0, length: maxLen!)
			if (kv.value == nil) {
				write(category: "...", message: "--> \(k) : <nil>")
			}
			else {
				write(category: "...", message: "--> \(k) : \(kv.value!)")
			}
		}
		blank()
	}
	
	func debug(_ message: String, _ arguments: [String:Any?]) {
		guard self != nil && isAllowed(.debug) else { return }
		args(message, arguments, LogType.debug.toCode())
	}
	func debug(_ message: String, _ arguments: CVarArg...) {
		guard self != nil && isAllowed(.debug) else { return }
		write(category: LogType.debug.toCode(), message: String(format: message, arguments))
	}
	
	func info(_ message: String, _ arguments: [String:Any?]) {
		guard self != nil && isAllowed(.info) else { return }
		args(message, arguments, LogType.info.toCode())
	}
	func info(_ message: String, _ arguments: CVarArg...) {
		guard self != nil && isAllowed(.info) else { return }
		write(category: LogType.info.toCode(), message: String(format: message, arguments))
	}
	
	func warn(_ message: String, _ arguments: [String:Any?]) {
		guard self != nil && isAllowed(.warning) else { return }
		args(message, arguments, LogType.warning.toCode())
	}
	func warn(_ message: String, _ arguments: CVarArg...) {
		guard self != nil && isAllowed(.warning) else { return }
		write(category: LogType.warning.toCode(), message: String(format: message, arguments))
	}
	
	func error(_ message: String, _ arguments: [String:Any?]) {
		guard self != nil && isAllowed(.error) else { return }
		args(message, arguments, LogType.error.toCode())
	}
	func error(_ message: String, _ arguments: CVarArg...) {
		guard self != nil && isAllowed(.error) else { return }
		write(category: LogType.error.toCode(), message: String(format: message, arguments))
	}
	
	func SQL(_ message: String, _ arguments: [String:Any?]) {
		guard self != nil && isAllowed(.sql) else { return }
		args(message, arguments, LogType.sql.toCode())
	}
	func SQL(_ message: String, _ args: CVarArg...) {
		guard self != nil && isAllowed(.sql) else { return }
		write(category: LogType.sql.toCode(), message: String(format: message, args))
	}
	
}

extension String {
	
	//Returns the (default) utf8 length of the string
	func length(encoding: String.Encoding = .utf8) -> Int {
		return lengthOfBytes(using: encoding)
	}
	
	//Returns the substring using from and to
	func substring(from: Int, to: Int) -> String {
		guard from < self.length() else { return "" }
		guard to >= 0 && from >= 0 && from <= to else {
			return ""
		}
		
		let start = index(startIndex, offsetBy: from)
		let end = index(startIndex, offsetBy: to.min(self.length() - 1))
		return String(self[start ... end])
	}
	
	//Returns the substring using from and length
	func substring(from: Int, length: Int) -> String {
		let to = from - 1 + length
		return self.substring(from: from, to: to)
	}
	
	//Returns the substring using from
	func substring(from: Int) -> String {
		let start = index(startIndex, offsetBy: from)
		let end = self.endIndex
		return String(self[start ..< end])    }
	
	//Returns the substring
	func substring(range: NSRange) -> String {
		return substring(from: range.lowerBound, to: range.upperBound)
	}
	
	func repeating(_ noTimes: Int) -> String {
		if noTimes < 1 {
			return ""
		}
		return String(repeating: self, count: noTimes)
	}
}

extension Comparable {
	func min(_ subsequent: Self...) -> Self {
		if subsequent.count == 0 {
			return self
		}
		var ar = subsequent
		ar.append(self)
		return ar.min()!
	}
	
	func max(_ subsequent: Self...) -> Self {
		if subsequent.count == 0 {
			return self
		}
		var ar = subsequent
		ar.append(self)
		return ar.max()!
	}
	
}
