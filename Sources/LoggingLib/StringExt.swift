//
//  StringExt.swift
//  Logging
//
//  Created by Matt Hogg on 05/11/2019.
//  Copyright © 2019 Matthew Hogg. All rights reserved.
//

import Foundation

 extension String {
	func `repeat`(_ noTimes: Int) -> String {
		guard noTimes > 0 else {
			return ""
		}
		return String.init(repeating: self, count: noTimes)
	}
	
	func parseTabs(_ column: Int) -> String {
		var ret = ""
		var col = column
		for c in self {
			if c == "\t" {
				ret += " ".repeat(8 - col % 8)
				col += (8 - col % 8)
			}
			else {
				if c == "\r" {
					col = 0
				}
				else {
					col += 1
				}
				ret += "\(c)"
			}
		}
		return ret
	}
	
	func indexes(of character: String) -> [Int] {

	  precondition(character.count == 1, "Must be single character")

	  return self.enumerated().reduce([]) { partial, element  in
		if String(element.element) == character {
		  return partial + [element.offset]
		}
		return partial
	  }
	}
	
	private func getIndexes(_ findThese: [String.Element], filter: (Int) -> Bool) -> [Int] {
		var ret : [Int] = []
		for c in findThese {
			ret.append(contentsOf: self.indexes(of: "\(c)"))
		}
		ret = ret.filter({ (i) -> Bool in
			return filter(i)
		})
		ret.sort()
		return ret
	}
	
	func trim(_ encoding: String.Encoding = .utf8) -> String {
		return self.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	func splitIntoLines(_ maxWidth: Int = 80) -> [String] {
		var ret : [String] = []
		let separators = Array(" \n\t-;:?\\.,_!")
		var text = self
		while text != "" {
			text = text.parseTabs(0)
			if text.length() < maxWidth {
				ret.append(text)
				break
			}
			
			//Get the separators' indexes
			let indexes = text.getIndexes(separators) { (i) -> Bool in
				return (i >= 0 && i < maxWidth)
			}
			if indexes.count == 0 {
				//There are no separators
				ret.append(text.substring(from: 0, length: maxWidth))
				text = text.substring(from: maxWidth).trim()
			}
			else {
				let lastIndex = indexes.last!
				ret.append(text.substring(from: 0, length: lastIndex))
				text = text.substring(from: lastIndex).trim()
			}
		}
		return ret
	}
}
